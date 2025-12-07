// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomState _$RoomStateFromJson(Map<String, dynamic> json) => RoomState(
  room: json['room'] == null
      ? null
      : Room.fromJson(json['room'] as Map<String, dynamic>),
  requests:
      (json['requests'] as List<dynamic>?)
          ?.map((e) => RoomRequest.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  responses:
      (json['responses'] as List<dynamic>?)
          ?.map((e) => RoomResponse.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$RoomStateToJson(RoomState instance) => <String, dynamic>{
  'room': instance.room?.toJson(),
  'requests': instance.requests.map((e) => e.toJson()).toList(),
  'responses': instance.responses.map((e) => e.toJson()).toList(),
};
