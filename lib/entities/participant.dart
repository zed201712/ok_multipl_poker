import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import '../core/mixins/json_serializable_mixin.dart';

part 'participant.g.dart';

// Helper function to convert Firestore Timestamp to/from JSON.
Timestamp _timestampFromJson(dynamic json) => json as Timestamp;
Timestamp _timestampToJson(Timestamp timestamp) => timestamp;

// --- Data Models ---
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