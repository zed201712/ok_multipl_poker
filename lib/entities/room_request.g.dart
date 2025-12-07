// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomRequest _$RoomRequestFromJson(Map<String, dynamic> json) => RoomRequest(
  requestId: json['requestId'] as String? ?? '',
  roomId: json['roomId'] as String? ?? '',
  participantId: json['participantId'] as String,
  body: json['body'] as Map<String, dynamic>,
  createdAt: _timestampFromJson(json['createdAt']),
);

Map<String, dynamic> _$RoomRequestToJson(RoomRequest instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'roomId': instance.roomId,
      'participantId': instance.participantId,
      'body': instance.body,
      'createdAt': _timestampToJson(instance.createdAt),
    };
