import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../entities/room.dart';
import '../entities/room_request.dart';
import '../entities/room_response.dart';
import '../entities/room_state.dart';

/// Manages all Firestore operations related to room state, requests, and responses.
class FirestoreRoomStateController {
  final FirebaseFirestore _firestore;
  final String _collectionName;

  // Stream controllers for exposing streams to the UI
  final _roomsController = BehaviorSubject<List<Room>>();
  final _roomStateController = BehaviorSubject<RoomState?>.seeded(null);

  // Internal subscriptions to Firestore streams
  StreamSubscription<List<Room>>? _roomsSubscription;
  StreamSubscription<RoomState>? _roomStateSubscription;

  FirestoreRoomStateController(this._firestore, this._collectionName) {
    _listenToRooms();
  }

  // --- Public Streams ---

  /// A stream of all rooms, updated in real-time.
  ValueStream<List<Room>> get roomsStream => _roomsController.stream;

  /// A stream of the current room's state. Use [setRoomId] to switch rooms.
  ValueStream<RoomState?> get roomStateStream => _roomStateController.stream;

  // --- Public Methods ---

  /// Switches the room state stream to a new room ID.
  ///
  /// Pass null or an empty string to clear the stream.
  void setRoomId(String? roomId) {
    _roomStateSubscription?.cancel();
    if (roomId == null || roomId.isEmpty) {
      _roomStateController.add(null);
      return;
    }

    final combinedStream = CombineLatestStream.combine3(
      _roomStream(roomId: roomId),
      _getRequestsStream(roomId: roomId),
      _getResponsesStream(roomId: roomId),
      (Room? room, List<RoomRequest> requests, List<RoomResponse> responses) {
        return RoomState(
          room: room,
          requests: requests,
          responses: responses,
        );
      },
    );

    _roomStateSubscription = combinedStream.listen((roomState) {
      _roomStateController.add(roomState);
    });
  }

  /// Disposes the controller and releases all resources.
  void dispose() {
    _roomsSubscription?.cancel();
    _roomStateSubscription?.cancel();
    _roomsController.close();
    _roomStateController.close();
  }

  // --- Internal Stream Management ---

  void _listenToRooms() {
    _roomsSubscription = _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Room.fromFirestore(doc)).toList())
        .listen((rooms) {
      _roomsController.add(rooms);
    });
  }

  // --- Room ---

  /// Creates a new room document in Firestore.
  Future<String> createRoom({
    String? roomId,
    required String creatorUid,
    required String title,
    required int maxPlayers,
    required String matchMode,
    required String visibility,
  }) async {
    final docId = (roomId != null && roomId.isNotEmpty)
        ? roomId
        : _firestore.collection(_collectionName).doc().id;

    final roomData = {
      'creatorUid': creatorUid,
      'managerUid': creatorUid, // Manager is the creator initially
      'title': title,
      'maxPlayers': maxPlayers,
      'state': 'open', // Use 'state' to match Room entity
      'body': '', // Initialize body
      'matchMode': matchMode,
      'visibility': visibility,
      'participants': [creatorUid], // Creator is the first participant
      'seats': [creatorUid], // Creator takes the first seat
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection(_collectionName).doc(docId).set(roomData);
    return docId;
  }

  /// Updates a room with the given data.
  Future<void> updateRoom({
    required String roomId,
    required Map<String, Object?> data,
  }) async {
    final updateData = {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection(_collectionName).doc(roomId).update(updateData);
  }

  /// Updates the body of a room.
  Future<void> updateRoomBody({
    required String roomId,
    required String body,
  }) async {
    await updateRoom(roomId: roomId, data: {'body': body});
  }

  /// Deletes a room document.
  Future<void> deleteRoom({required String roomId}) async {
    await _firestore.collection(_collectionName).doc(roomId).delete();
  }

  // --- Room Lifecycle ---

  /// Tries to find an open room to join. If no suitable room is found,
  /// it creates a new one with the provided details.
  Future<String> matchRoom({
    required String userId,
    required String title,
    required int maxPlayers,
    required String matchMode,
    required String visibility,
  }) async {
    // 1. Find open rooms
    final querySnapshot = await _firestore
        .collection(_collectionName)
        .where('state', isEqualTo: 'open')
        .where('visibility', isEqualTo: 'public') // Assuming we only match with public rooms
        .get();

    // 2. Filter for rooms that are not full
    final availableRooms = querySnapshot.docs.where((doc) {
      final room = Room.fromFirestore(doc);
      return room.participants.length < room.maxPlayers;
    }).toList();

    if (availableRooms.isNotEmpty) {
      // 3. Join the first available room
      final roomToJoin = Room.fromFirestore(availableRooms.first);
      await updateRoom(
        roomId: roomToJoin.roomId,
        data: {
          'participants': FieldValue.arrayUnion([userId]),
          'seats': FieldValue.arrayUnion([userId]),
        },
      );
      return roomToJoin.roomId;
    } else {
      // 4. No available rooms, create a new one
      return await createRoom(
        creatorUid: userId,
        title: title,
        maxPlayers: maxPlayers,
        matchMode: matchMode,
        visibility: visibility,
      );
    }
  }

  /// Handles the logic for a user leaving a room.
  /// The behavior depends on whether the user is the manager or a participant.
  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    final roomDoc = await _firestore.collection(_collectionName).doc(roomId).get();
    if (!roomDoc.exists) return;

    final room = Room.fromFirestore(roomDoc);

    if (room.managerUid == userId) {
      // User is the manager
      final otherParticipants = room.participants.where((p) => p != userId).toList();
      if (otherParticipants.isNotEmpty) {
        // 2.1. Transfer managership
        await updateRoom(
          roomId: roomId,
          data: {
            'managerUid': otherParticipants.first,
            'participants': FieldValue.arrayRemove([userId]),
            'seats': FieldValue.arrayRemove([userId]),
          },
        );
      } else {
        // 2.2. No one else in the room, delete it
        await deleteRoom(roomId: roomId);
      }
    } else {
      // 3. User is a participant, send a leave request
      await sendRequest(
        roomId: roomId,
        participantId: userId,
        body: {'action': 'leave'},
      );
    }
  }

  /// Sends a keep-alive ping to the room in the form of a RoomRequest.
  Future<void> sendAlivePing({
    required String roomId,
    required String userId,
  }) async {
    await sendRequest(
      roomId: roomId,
      participantId: userId,
      body: {'action': 'alive'},
    );
  }

  // --- Private Firestore Streams ---

  /// Returns a stream of a specific room document.
  Stream<Room?> _roomStream({required String roomId}) {
    return _firestore
        .collection(_collectionName)
        .doc(roomId)
        .snapshots()
        .map((doc) => doc.exists ? Room.fromFirestore(doc) : null);
  }

  /// Returns a stream of all requests in a room.
  Stream<List<RoomRequest>> _getRequestsStream({required String roomId}) {
    return _firestore
        .collection(_collectionName)
        .doc(roomId)
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RoomRequest.fromFirestore(doc)).toList());
  }

  /// Returns a stream of all responses in a room.
  Stream<List<RoomResponse>> _getResponsesStream({required String roomId}) {
    return _firestore
        .collection(_collectionName)
        .doc(roomId)
        .collection('responses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RoomResponse.fromFirestore(doc)).toList());
  }

  // --- Request / Response CRUD ---

  /// Sends a request to a room.
  Future<String> sendRequest({
    required String roomId,
    required String participantId,
    required Map<String, dynamic> body,
  }) async {
    final requestCollection = _firestore.collection(_collectionName).doc(roomId).collection('requests');
    final docRef = requestCollection.doc();
    final requestData = {
      'requestId': docRef.id,
      'participantId': participantId,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(requestData);
    return docRef.id;
  }

  /// Deletes a request from a room.
  Future<void> deleteRequest({
    required String roomId,
    required String requestId,
  }) async {
    await _firestore.collection(_collectionName).doc(roomId).collection('requests').doc(requestId).delete();
  }

  /// Sends a response to a request in a room.
  Future<String> sendResponse({
    required String roomId,
    required String requestId,
    required String participantId,
    required Map<String, dynamic> body,
  }) async {
    final responseCollection = _firestore.collection(_collectionName).doc(roomId).collection('responses');
    final docRef = responseCollection.doc(); // Auto-generate ID
    final responseData = {
      'requestId': requestId,
      'responseId': docRef.id,
      'participantId': participantId,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(responseData);
    return docRef.id;
  }

  /// Deletes a response from a room.
  Future<void> deleteResponse({
    required String roomId,
    required String responseId,
  }) async {
    await _firestore.collection(_collectionName).doc(roomId).collection('responses').doc(responseId).delete();
  }
}
