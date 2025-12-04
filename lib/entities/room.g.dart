// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Room _$RoomFromJson(Map<String, dynamic> json) => Room(
  creatorUid: json['creatorUid'] as String,
  managerUid: json['managerUid'] as String,
  title: json['title'] as String,
  maxPlayers: (json['maxPlayers'] as num).toInt(),
  status: json['status'] as String,
  matchMode: json['matchMode'] as String,
  visibility: json['visibility'] as String,
  createdAt: _timestampFromJson(json['createdAt']),
  updatedAt: _timestampFromJson(json['updatedAt']),
);

Map<String, dynamic> _$RoomToJson(Room instance) => <String, dynamic>{
  'creatorUid': instance.creatorUid,
  'managerUid': instance.managerUid,
  'title': instance.title,
  'maxPlayers': instance.maxPlayers,
  'status': instance.status,
  'matchMode': instance.matchMode,
  'visibility': instance.visibility,
  'createdAt': _timestampToJson(instance.createdAt),
  'updatedAt': _timestampToJson(instance.updatedAt),
};
