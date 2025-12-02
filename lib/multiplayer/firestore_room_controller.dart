
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Data Models ---

/// Represents a room document in the `rooms` collection.
class Room {
  final String roomId;
  final String creatorUid;
  final String title;
  final int maxPlayers;
  final String status;
  final String matchMode;
  final String visibility;
  final Timestamp createdAt;
  final Timestamp lastActivityAt;

  Room({
    required this.roomId,
    required this.creatorUid,
    required this.title,
    required this.maxPlayers,
    required this.status,
    required this.matchMode,
    required this.visibility,
    required this.createdAt,
    required this.lastActivityAt,
  });

  /// Creates a Room object from a Firestore document snapshot.
  factory Room.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Room(
      roomId: doc.id,
      creatorUid: data['creatorUid'] ?? '',
      title: data['title'] ?? '',
      maxPlayers: data['maxPlayers'] ?? 0,
      status: data['status'] ?? '',
      matchMode: data['matchMode'] ?? '',
      visibility: data['visibility'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      lastActivityAt: data['lastActivityAt'] ?? Timestamp.now(),
    );
  }

  /// Converts a Room object into a Map for Firestore.
  /// Note: `roomId` is typically used as the document ID and not stored as a field.
  Map<String, dynamic> toFirestore() {
    return {
      'creatorUid': creatorUid,
      'title': title,
      'maxPlayers': maxPlayers,
      'status': status,
      'matchMode': matchMode,
      'visibility': visibility,
      'createdAt': createdAt,
      'lastActivityAt': lastActivityAt,
    };
  }
}

/// Represents a participant document in the `participants` sub-collection.
class Participant {
  final String uid;
  final String status;
  final Timestamp joinedAt;

  Participant({
    required this.uid,
    required this.status,
    required this.joinedAt,
  });

  /// Creates a Participant object from a Firestore document snapshot.
  factory Participant.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Participant(
      uid: data['uid'] ?? '',
      status: data['status'] ?? '',
      joinedAt: data['joinedAt'] ?? Timestamp.now(),
    );
  }

  /// Converts a Participant object into a Map for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'status': status,
      'joinedAt': joinedAt,
    };
  }
}

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
      'roomId': docId,
      'creatorUid': creatorUid,
      'title': title,
      'maxPlayers': maxPlayers,
      'status': 'open',
      'matchMode': matchMode,
      'visibility': visibility,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivityAt': FieldValue.serverTimestamp(),
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
    };

    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .set(participantData, SetOptions(merge: true));
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
}
