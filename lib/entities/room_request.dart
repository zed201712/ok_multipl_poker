import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import '../core/mixins/json_serializable_mixin.dart';

part 'room_request.g.dart';

// Helper function to convert Firestore Timestamp to/from JSON.
Timestamp _timestampFromJson(dynamic json) => json as Timestamp;
Timestamp _timestampToJson(Timestamp timestamp) => timestamp;

@JsonSerializable(explicitToJson: true)
class RoomRequest with JsonSerializableMixin {
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  Set<String> get timeKeys => {'createdAt'};

  final String requestId;
  final String roomId;
  final String participantId;
  final Map<String, dynamic> body;

  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final Timestamp createdAt;

  RoomRequest({
    this.requestId = '',
    this.roomId = '',
    required this.participantId,
    required this.body,
    required this.createdAt,
  });

  /// Creates a RoomRequest instance from a Firestore document.
  factory RoomRequest.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists || doc.data() == null) {
      throw Exception('RoomRequest document not found or is empty');
    }
    return RoomRequest.fromJson(doc.data()!).copyWith(requestId: doc.id);
  }

  RoomRequest copyWith({
    String? requestId,
    String? roomId,
    String? participantId,
    Map<String, dynamic>? body,
    Timestamp? createdAt,
  }) {
    return RoomRequest(
      requestId: requestId ?? this.requestId,
      roomId: roomId ?? this.roomId,
      participantId: participantId ?? this.participantId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory RoomRequest.fromJson(Map<String, dynamic> json) => _$RoomRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$RoomRequestToJson(this);
}
