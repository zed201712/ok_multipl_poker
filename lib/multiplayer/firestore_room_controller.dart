import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/participant.dart';
import '../entities/room.dart';

// --- Controller ---

/// Manages all Firestore operations related to rooms and participants.
class FirestoreRoomController {
  final FirebaseFirestore _firestore;

  FirestoreRoomController(this._firestore);

  /// Creates a new room document in Firestore.
  /// If `roomId` is null or empty, a new ID will be generated.
  /// Returns the ID of the created or updated room.
  Future<String> createRoom({
    String? roomId,
    required String creatorUid,
    required String title,
    required int maxPlayers,
    required String matchMode,
    required String visibility,
  }) async {
    final docId = (roomId != null && roomId.isNotEmpty) ? roomId : _firestore.collection('rooms').doc().id;

    final roomData = {
      'creatorUid': creatorUid,
      'managerUid': creatorUid, // Manager is the creator initially
      'title': title,
      'maxPlayers': maxPlayers,
      'status': 'open',
      'matchMode': matchMode,
      'visibility': visibility,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('rooms').doc(docId).set(roomData);
    return docId;
  }

  /// Adds or updates a participant's information in a specific room.
  Future<void> joinRoom({
    required String roomId,
    required String userId,
    required String status,
  }) async {
    final participantData = {
      'uid': userId,
      'status': status,
      'joinedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .set(participantData, SetOptions(merge: true));
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
    await _firestore.collection('rooms').doc(roomId).update(updateData);
  }

  /// Changes the manager of a room.
  Future<void> changeManager({
    required String roomId,
    required String newManagerUid,
  }) async {
    await updateRoom(roomId: roomId, data: {'managerUid': newManagerUid});
  }

  /// Updates a participant's data in a room.
  Future<void> updateParticipant({
    required String roomId,
    required String userId,
    required Map<String, Object?> data,
  }) async {
    final updateData = {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .update(updateData);
  }

  /// Deletes a room document.
  /// Note: This does not delete subcollections. For that, a Cloud Function is recommended.
  Future<void> deleteRoom({required String roomId}) async {
    await _firestore.collection('rooms').doc(roomId).delete();
  }

  /// Deletes a participant from a room (the user "leaves" the room).
  Future<void> leaveRoom({required String roomId, required String userId}) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .delete();
  }

  /// Returns a stream of all rooms.
  Stream<List<Room>> roomsStream() {
    return _firestore
        .collection('rooms')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Room.fromFirestore(doc)).toList());
  }

  /// Returns a stream of a specific participant's document in a room.
  Stream<Participant?> participantStream({required String roomId, required String userId}) {
    if (roomId.isEmpty || userId.isEmpty) {
      return Stream.value(null);
    }
    final docRef = _firestore.collection('rooms').doc(roomId).collection('participants').doc(userId);
    return docRef.snapshots().map((doc) {
      if (doc.exists) {
        return Participant.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Returns a stream of all participants in a specific room.
  Stream<List<Participant>> participantsStream({required String roomId}) {
    if (roomId.isEmpty) {
      return Stream.value([]);
    }
    final collectionRef = _firestore.collection('rooms').doc(roomId).collection('participants');
    return collectionRef.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Participant.fromFirestore(doc)).toList(),
    );
  }
}
