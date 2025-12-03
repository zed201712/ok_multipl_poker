
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import '../core/mixins/json_serializable_mixin.dart';

part 'firestore_room_controller.g.dart';

// Helper function to convert Firestore Timestamp to/from JSON.
Timestamp _timestampFromJson(dynamic json) => json as Timestamp;
Timestamp _timestampToJson(Timestamp timestamp) => timestamp;

// --- Data Models ---

@JsonSerializable(explicitToJson: true)
class Room with JsonSerializableMixin {
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  Set<String> get timeKeys => {'createdAt', 'updatedAt'};

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String roomId;

  final String creatorUid;
  final String title;
  final int maxPlayers;
  final String status;
  final String matchMode;
  final String visibility;

  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final Timestamp createdAt;

  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final Timestamp updatedAt;

  Room({
    this.roomId = '', // Default value for when creating from json
    required this.creatorUid,
    required this.title,
    required this.maxPlayers,
    required this.status,
    required this.matchMode,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a Room instance from a Firestore document.
  factory Room.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists || doc.data() == null) {
      throw Exception('Room document not found or is empty');
    }
    // Use the generated fromJson factory and then set the non-data field.
    return Room.fromJson(doc.data()!).copyWith(roomId: doc.id);
  }

  /// Creates a copy of the room with a new roomId.
  Room copyWith({String? roomId}) {
    return Room(
      roomId: roomId ?? this.roomId,
      creatorUid: this.creatorUid,
      title: this.title,
      maxPlayers: this.maxPlayers,
      status: this.status,
      matchMode: this.matchMode,
      visibility: this.visibility,
      createdAt: this.createdAt,
      updatedAt: updatedAt,
    );
  }

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$RoomToJson(this);
}

@JsonSerializable()
class Participant with JsonSerializableMixin {
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  Set<String> get timeKeys => {'joinedAt', 'createdAt', 'updatedAt'};

  final String uid;
  final String status;

  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final Timestamp joinedAt;

  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final Timestamp createdAt;

  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final Timestamp updatedAt;

  Participant({
    required this.uid,
    required this.status,
    required this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a Participant instance from a Firestore document.
  factory Participant.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists || doc.data() == null) {
      throw Exception('Participant document not found or is empty');
    }
    return Participant.fromJson(doc.data()!);
  }

  /// Creates a copy of the participant with new values.
  Participant copyWith({
    String? uid
  }) {
    return Participant(
      uid: uid ?? this.uid,
      status: status,
      joinedAt: joinedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory Participant.fromJson(Map<String, dynamic> json) =>
      _$ParticipantFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ParticipantToJson(this);
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
      'creatorUid': creatorUid,
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
