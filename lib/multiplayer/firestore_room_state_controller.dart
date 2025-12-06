import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../entities/room.dart';
import '../entities/room_request.dart';
import '../entities/room_response.dart';
import '../entities/room_state.dart';

/// Manages all Firestore operations related to room state, requests, and responses.
class FirestoreRoomStateController {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _collectionName;

  // Stream controllers for exposing streams to the UI
  final _roomsController = BehaviorSubject<List<Room>>();
  final _roomStateController = BehaviorSubject<RoomState?>.seeded(null);
  final _userIdController = BehaviorSubject<String?>.seeded(null);

  // Internal subscriptions to Firestore streams
  StreamSubscription<List<Room>>? _roomsSubscription;
  StreamSubscription<RoomState>? _roomStateSubscription;

  FirestoreRoomStateController(this._firestore, this._auth, this._collectionName) {
    _initializeUser();
  }

  // --- Public Streams & Properties ---

  /// A stream of all rooms, updated in real-time.
  ValueStream<List<Room>> get roomsStream => _roomsController.stream;

  /// A stream of the current room's state. Use [setRoomId] to switch rooms.
  ValueStream<RoomState?> get roomStateStream => _roomStateController.stream;

  /// A stream of the current user's ID.
  ValueStream<String?> get userIdStream => _userIdController.stream;

  /// The current user's ID, or null if not authenticated.
  String? get currentUserId => _userIdController.value;

  // --- Public Methods ---

  /// Initializes the user by checking auth state and signing in anonymously if needed.
  Future<void> _initializeUser() async {
    User? user = _auth.currentUser;
    user ??= (await _auth.signInAnonymously()).user;
    _userIdController.add(user?.uid);
    _listenToRooms();
  }

  /// Switches the room state stream to a new room ID.
  ///
  /// Pass null or an empty string to clear the stream.
  void setRoomId(String? roomId) {
    _roomStateSubscription?.cancel();
    if (roomId == null || roomId.isEmpty) {
      _roomStateController.add(null);
      return;
    }
    if (currentUserId == null) {
      throw Exception('User not authenticated, cannot match a room.');
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
      _managerRequestHandler(roomState);
    });
  }

  /// Disposes the controller and releases all resources.
  void dispose() {
    _roomsSubscription?.cancel();
    _roomStateSubscription?.cancel();
    _roomsController.close();
    _roomStateController.close();
    _userIdController.close();
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
    required String title,
    required int maxPlayers,
    required String matchMode,
    required String visibility,
  }) async {
    final creatorUid = currentUserId;
    if (creatorUid == null) {
      throw Exception('User not authenticated, cannot create a room.');
    }

    final docId = (roomId != null && roomId.isNotEmpty)
        ? roomId
        : _firestore.collection(_collectionName).doc().id;

    final roomData = {
      'creatorUid': creatorUid,
      'managerUid': creatorUid,
      'title': title,
      'maxPlayers': maxPlayers,
      'state': 'open',
      'body': '',
      'matchMode': matchMode,
      'visibility': visibility,
      'participants': [creatorUid],
      'seats': [creatorUid],
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
    if (currentUserId == null) {
      throw Exception('User not authenticated, cannot match a room.');
    }

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
    required String title,
    required int maxPlayers,
    required String matchMode,
    required String visibility,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated, cannot match a room.');
    }

    final querySnapshot = await _firestore
        .collection(_collectionName)
        .where('state', isEqualTo: 'open')
        .where('visibility', isEqualTo: 'public')
        .get();

    final availableRooms = querySnapshot.docs.where((doc) {
      final room = Room.fromFirestore(doc);
      return room.participants.length < room.maxPlayers;
    }).toList();

    if (availableRooms.isNotEmpty) {
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
      return await createRoom(
        title: title,
        maxPlayers: maxPlayers,
        matchMode: matchMode,
        visibility: visibility,
      );
    }
  }

  /// Handles the logic for a user leaving a room.
  Future<void> leaveRoom({required String roomId}) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated, cannot leave a room.');
    }

    final roomDoc = await _firestore.collection(_collectionName).doc(roomId).get();
    if (!roomDoc.exists) return;

    final room = Room.fromFirestore(roomDoc);

    if (room.managerUid == userId) {
      final otherParticipants = room.participants.where((p) => p != userId).toList();
      if (otherParticipants.isNotEmpty) {
        await updateRoom(
          roomId: roomId,
          data: {
            'managerUid': otherParticipants.first,
            'participants': FieldValue.arrayRemove([userId]),
            'seats': FieldValue.arrayRemove([userId]),
          },
        );
      } else {
        await deleteRoom(roomId: roomId);
      }
    } else {
      await sendRequest(
        roomId: roomId,
        body: {'action': 'leave'},
      );
    }
  }

  /// Sends a keep-alive ping to the room.
  Future<void> sendAlivePing({required String roomId}) async {
    await sendRequest(
      roomId: roomId,
      body: {'action': 'alive'},
    );
  }

  // --- New Manager Auto-Approval ---

  void _managerRequestHandler(RoomState roomState) {
    final room = roomState.room;
    if (room == null || room.managerUid != currentUserId) {
      return;
    }

    final joinRequests = roomState.requests.where((req) => req.body['action'] == 'join');

    for (final request in joinRequests) {
      _approveJoinRequest(request, room);
    }
  }

  Future<void> _approveJoinRequest(RoomRequest request, Room room) async {
    if (room.participants.length >= room.maxPlayers) {
      // Maybe send a "room full" response in the future.
      return;
    }

    if (room.participants.contains(request.participantId)) {
      await deleteRequest(roomId: room.roomId, requestId: request.requestId);
      return;
    }

    final newParticipants = List<String>.from(room.participants)..add(request.participantId);

    await updateRoom(
      roomId: room.roomId,
      data: {'participants': newParticipants},
    );

    await deleteRequest(roomId: room.roomId, requestId: request.requestId);
  }

  // --- Private Firestore Streams ---

  Stream<Room?> _roomStream({required String roomId}) {
    return _firestore
        .collection(_collectionName)
        .doc(roomId)
        .snapshots()
        .map((doc) => doc.exists ? Room.fromFirestore(doc) : null);
  }

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
    required Map<String, dynamic> body,
  }) async {
    final participantId = currentUserId;
    if (participantId == null) {
      throw Exception('User not authenticated, cannot send a request.');
    }

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

  /// Encapsulates the logic for sending a 'join' request.
  Future<void> requestToJoinRoom({required String roomId}) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated, cannot send a request.');
    }
    await sendRequest(roomId: roomId, body: {'action': 'join'});
  }

  Future<void> deleteRequest({
    required String roomId,
    required String requestId,
  }) async {
    await _firestore.collection(_collectionName).doc(roomId).collection('requests').doc(requestId).delete();
  }

  Future<String> sendResponse({
    required String roomId,
    required String requestId,
    required Map<String, dynamic> body,
  }) async {
    final participantId = currentUserId;
    if (participantId == null) {
      throw Exception('User not authenticated, cannot send a response.');
    }

    final responseCollection = _firestore.collection(_collectionName).doc(roomId).collection('responses');
    final docRef = responseCollection.doc();
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

  Future<void> deleteResponse({
    required String roomId,
    required String responseId,
  }) async {
    await _firestore.collection(_collectionName).doc(roomId).collection('responses').doc(responseId).delete();
  }
}
