import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import '../core/mixins/json_serializable_mixin.dart';

part 'room.g.dart';

// Helper function to convert Firestore Timestamp to/from JSON.
Timestamp _timestampFromJson(dynamic json) => json as Timestamp;
Timestamp _timestampToJson(Timestamp timestamp) => timestamp;

// --- Data Models ---
@JsonSerializable(explicitToJson: true)
class Room with JsonSerializableMixin {
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  Set<String> get timeKeys => {'createdAt', 'updatedAt'};

  final String roomId;

  final String creatorUid;
  final String managerUid;
  final String title;
  final int maxPlayers;
  final String state;
  final String body;
  final String matchMode;
  final String visibility;
  final List<String> seats;
  final List<String> participants;

  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final Timestamp createdAt;

  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final Timestamp updatedAt;

  Room({
    this.roomId = '', // Default value for when creating from json
    required this.creatorUid,
    required this.managerUid,
    required this.title,
    required this.maxPlayers,
    required this.state,
    required this.body,
    required this.matchMode,
    required this.visibility,
    this.seats = const [],
    this.participants = const [],
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

  /// Creates a copy of the room with new values.
  Room copyWith({
    String? roomId,
    String? creatorUid,
    String? managerUid,
    String? title,
    int? maxPlayers,
    String? state,
    String? body,
    String? matchMode,
    String? visibility,
    List<String>? seats,
    List<String>? participants,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Room(
      roomId: roomId ?? this.roomId,
      creatorUid: creatorUid ?? this.creatorUid,
      managerUid: managerUid ?? this.managerUid,
      title: title ?? this.title,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      state: state ?? this.state,
      body: body ?? this.body,
      matchMode: matchMode ?? this.matchMode,
      visibility: visibility ?? this.visibility,
      seats: seats ?? this.seats,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$RoomToJson(this);
}