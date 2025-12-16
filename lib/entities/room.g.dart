// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Room _$RoomFromJson(Map<String, dynamic> json) => Room(
  roomId: json['roomId'] as String? ?? '',
  creatorUid: json['creatorUid'] as String,
  managerUid: json['managerUid'] as String,
  title: json['title'] as String,
  maxPlayers: (json['maxPlayers'] as num).toInt(),
  state: json['state'] as String,
  body: json['body'] as String,
  matchMode: json['matchMode'] as String,
  visibility: json['visibility'] as String,
  seats:
      (json['seats'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  participants:
      (json['participants'] as List<dynamic>?)
          ?.map((e) => ParticipantInfo.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  createdAt: _timestampFromJson(json['createdAt']),
  updatedAt: _timestampFromJson(json['updatedAt']),
);

Map<String, dynamic> _$RoomToJson(Room instance) => <String, dynamic>{
  'roomId': instance.roomId,
  'creatorUid': instance.creatorUid,
  'managerUid': instance.managerUid,
  'title': instance.title,
  'maxPlayers': instance.maxPlayers,
  'state': instance.state,
  'body': instance.body,
  'matchMode': instance.matchMode,
  'visibility': instance.visibility,
  'seats': instance.seats,
  'participants': instance.participants.map((e) => e.toJson()).toList(),
  'createdAt': _timestampToJson(instance.createdAt),
  'updatedAt': _timestampToJson(instance.updatedAt),
};
