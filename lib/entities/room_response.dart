import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import '../core/mixins/json_serializable_mixin.dart';

part 'room_response.g.dart';

// Helper function to convert Firestore Timestamp to/from JSON.
Timestamp? _timestampFromJson(dynamic json) => json is Timestamp ? json : null;
Timestamp? _timestampToJson(Timestamp? timestamp) => timestamp;

@JsonSerializable(explicitToJson: true)
class RoomResponse with JsonSerializableMixin {
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  Set<String> get timeKeys => {'createdAt'};

  final String requestId;
  final String responseId;
  final String roomId;
  final String participantId;
  final Map<String, dynamic> body;

  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final Timestamp? createdAt;

  RoomResponse({
    required this.requestId,
    this.responseId = '',
    this.roomId = '',
    required this.participantId,
    required this.body,
    required this.createdAt,
  });

  /// Creates a RoomResponse instance from a Firestore document.
  factory RoomResponse.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists || doc.data() == null) {
      throw Exception('RoomResponse document not found or is empty');
    }
    return RoomResponse.fromJson(doc.data()!).copyWith(responseId: doc.id);
  }

  RoomResponse copyWith({
    String? requestId,
    String? responseId,
    String? roomId,
    String? participantId,
    Map<String, dynamic>? body,
    Timestamp? createdAt,
  }) {
    return RoomResponse(
      requestId: requestId ?? this.requestId,
      responseId: responseId ?? this.responseId,
      roomId: roomId ?? this.roomId,
      participantId: participantId ?? this.participantId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory RoomResponse.fromJson(Map<String, dynamic> json) =>
      _$RoomResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$RoomResponseToJson(this);
}
