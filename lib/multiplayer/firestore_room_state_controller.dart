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

  /// Defines how long a room is considered active without an update.
  static const Duration _aliveTime = Duration(minutes: 2);

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

  ValueStream<List<Room>> get roomsStream => _roomsController.stream;
  ValueStream<RoomState?> get roomStateStream => _roomStateController.stream;
  ValueStream<String?> get userIdStream => _userIdController.stream;
  String? get currentUserId => _userIdController.value;

  // --- Public Methods ---

  Future<void> _initializeUser() async {
    User? user = _auth.currentUser;
    user ??= (await _auth.signInAnonymously()).user;
    _userIdController.add(user?.uid);
    _listenToRooms();
  }

  void setRoomId(String? roomId) {
    _roomStateSubscription?.cancel();
    if (roomId == null || roomId.isEmpty) {
      _roomStateController.add(null);
      return;
    }
    if (currentUserId == null) {
      throw Exception('User not authenticated.');
    }

    final combinedStream = CombineLatestStream.combine3(
      _roomStream(roomId: roomId),
      _getRequestsStream(roomId: roomId),
      _getResponsesStream(roomId: roomId),
      (Room? room, List<RoomRequest> requests, List<RoomResponse> responses) =>
          RoomState(room: room, requests: requests, responses: responses),
    );

    _roomStateSubscription = combinedStream.listen((roomState) {
      _roomStateController.add(roomState);
      _managerRequestHandler(roomState);
    });
  }

  void dispose() {
    _roomsSubscription?.cancel();
    _roomStateSubscription?.cancel();
    _roomsController.close();
    _roomStateController.close();
    _userIdController.close();
  }

  // --- Room Lifecycle & Management ---

  void _listenToRooms() {
    _roomsSubscription = _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Room.fromFirestore(doc)).toList())
        .listen((rooms) {
      _roomsController.add(rooms);
      _performManagerDuties(rooms);
    });
  }

  void _performManagerDuties(List<Room> rooms) {
    if (currentUserId == null) return;

    for (final room in rooms) {
      if (room.managerUid == currentUserId) {
        final sinceUpdate = DateTime.now().difference(room.updatedAt.toDate());

        if (sinceUpdate > _aliveTime) {
          deleteRoom(roomId: room.roomId);
        } else if (sinceUpdate.inSeconds > _aliveTime.inSeconds * 0.8) {
          updateRoom(roomId: room.roomId, data: {});
        }
      }
    }
  }

  Future<String> createRoom({
    String? roomId,
    required String title,
    required int maxPlayers,
    required String matchMode,
    required String visibility,
  }) async {
    final creatorUid = currentUserId;
    if (creatorUid == null) {
      throw Exception('User not authenticated.');
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

  Future<void> updateRoom({
    required String roomId,
    required Map<String, Object?> data,
  }) async {
    final updateData = {...data, 'updatedAt': FieldValue.serverTimestamp()};
    await _firestore.collection(_collectionName).doc(roomId).update(updateData);
  }

  Future<void> deleteRoom({required String roomId}) async {
    await _firestore.collection(_collectionName).doc(roomId).delete();
  }

  Future<String> matchRoom({
    required String title,
    required int maxPlayers,
    required String matchMode,
    required String visibility,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated.');
    }

    final querySnapshot = await _firestore
        .collection(_collectionName)
        .where('state', isEqualTo: 'open')
        .where('visibility', isEqualTo: 'public')
        .get();

    final availableRooms = querySnapshot.docs.where((doc) {
      final room = Room.fromFirestore(doc);
      final isActive = DateTime.now().difference(room.updatedAt.toDate()) <= _aliveTime;
      return isActive && room.participants.length < room.maxPlayers;
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
          title: title, maxPlayers: maxPlayers, matchMode: matchMode, visibility: visibility);
    }
  }

  Future<void> leaveRoom({required String roomId}) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated.');
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
      await sendRequest(roomId: roomId, body: {'action': 'leave'});
    }
  }

  // --- Manager Request Handling ---

  void _managerRequestHandler(RoomState roomState) {
    final room = roomState.room;
    if (room == null || room.managerUid != currentUserId) return;

    for (final request in roomState.requests) {
      final action = request.body['action'];
      if (action == 'join') {
        _approveJoinRequest(request);
      } else if (action == 'leave') {
        _handleLeaveRequest(request);
      } else if (action == 'alive') {
        deleteRequest(roomId: room.roomId, requestId: request.requestId);
      }
    }
  }

  Future<void> _approveJoinRequest(RoomRequest request) async {
    final roomRef = _firestore.collection(_collectionName).doc(request.roomId);
    final requestRef = roomRef.collection('requests').doc(request.requestId);

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) return;

      final room = Room.fromFirestore(roomSnapshot);

      if (room.participants.contains(request.participantId)) {
        transaction.delete(requestRef);
        return;
      }

      if (room.participants.length >= room.maxPlayers) {
        await sendResponse(
          roomId: room.roomId,
          requestId: request.requestId,
          body: {'status': 'denied', 'reason': 'room_full'},
        );
        transaction.delete(requestRef);
        return;
      }

      transaction.update(roomRef, {
        'participants': FieldValue.arrayUnion([request.participantId]),
        'seats': FieldValue.arrayUnion([request.participantId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.delete(requestRef);
    });
  }

  Future<void> _handleLeaveRequest(RoomRequest request) async {
    final roomRef = _firestore.collection(_collectionName).doc(request.roomId);
    final requestRef = roomRef.collection('requests').doc(request.requestId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(roomRef, {
        'participants': FieldValue.arrayRemove([request.participantId]),
        'seats': FieldValue.arrayRemove([request.participantId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.delete(requestRef);
    });
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
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomRequest.fromFirestore(doc).copyWith(roomId: roomId))
            .toList());
  }

  Stream<List<RoomResponse>> _getResponsesStream({required String roomId}) {
    return _firestore
        .collection(_collectionName)
        .doc(roomId)
        .collection('responses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomResponse.fromFirestore(doc).copyWith(roomId: roomId))
            .toList());
  }

  // --- Request / Response CRUD ---

  Future<String> sendRequest({
    required String roomId,
    required Map<String, dynamic> body,
  }) async {
    final participantId = currentUserId;
    if (participantId == null) {
      throw Exception('User not authenticated.');
    }
    final ref = _firestore.collection(_collectionName).doc(roomId).collection('requests').doc();
    await ref.set({
      'requestId': ref.id,
      'roomId': roomId, // <--- Added roomId
      'participantId': participantId,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> requestToJoinRoom({required String roomId}) async {
    await sendRequest(roomId: roomId, body: {'action': 'join'});
  }

  Future<void> sendAlivePing({required String roomId}) async {
    await sendRequest(roomId: roomId, body: {'action': 'alive'});
  }

  Future<void> deleteRequest({
    required String roomId,
    required String requestId,
  }) async {
    await _firestore
        .collection(_collectionName)
        .doc(roomId)
        .collection('requests')
        .doc(requestId)
        .delete();
  }

  Future<String> sendResponse({
    required String roomId,
    required String requestId,
    required Map<String, dynamic> body,
  }) async {
    final participantId = currentUserId;
    if (participantId == null) {
      throw Exception('User not authenticated.');
    }
    final ref = _firestore.collection(_collectionName).doc(roomId).collection('responses').doc();
    await ref.set({
      'requestId': requestId,
      'responseId': ref.id,
      'roomId': roomId, // <--- Added roomId
      'participantId': participantId,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> deleteResponse({
    required String roomId,
    required String responseId,
  }) async {
    await _firestore
        .collection(_collectionName)
        .doc(roomId)
        .collection('responses')
        .doc(responseId)
        .delete();
  }
}
