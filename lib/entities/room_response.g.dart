// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomResponse _$RoomResponseFromJson(Map<String, dynamic> json) => RoomResponse(
  requestId: json['requestId'] as String,
  responseId: json['responseId'] as String? ?? '',
  roomId: json['roomId'] as String? ?? '',
  participantId: json['participantId'] as String,
  body: json['body'] as Map<String, dynamic>,
  createdAt: _timestampFromJson(json['createdAt']),
);

Map<String, dynamic> _$RoomResponseToJson(RoomResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'responseId': instance.responseId,
      'roomId': instance.roomId,
      'participantId': instance.participantId,
      'body': instance.body,
      'createdAt': _timestampToJson(instance.createdAt),
    };
