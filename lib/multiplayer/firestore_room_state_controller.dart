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

  FirestoreRoomStateController(this._firestore, this._collectionName);

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

  /// Returns a stream of all rooms.
  Stream<List<Room>> roomsStream() {
    return _firestore.collection(_collectionName).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Room.fromFirestore(doc)).toList());
  }

  // --- Room State ---

  Stream<RoomState> getRoomStateStream({required String roomId}) {
    return CombineLatestStream.combine3(
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
  }

  /// Returns a stream of a specific room document.
  Stream<Room?> _roomStream({required String roomId}) {
    return _firestore
        .collection(_collectionName)
        .doc(roomId)
        .snapshots()
        .map((doc) => doc.exists ? Room.fromFirestore(doc) : null);
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
}
