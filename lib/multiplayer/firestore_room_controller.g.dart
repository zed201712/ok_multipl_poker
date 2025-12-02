// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firestore_room_controller.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Room _$RoomFromJson(Map<String, dynamic> json) => Room(
  creatorUid: json['creatorUid'] as String,
  title: json['title'] as String,
  maxPlayers: (json['maxPlayers'] as num).toInt(),
  status: json['status'] as String,
  matchMode: json['matchMode'] as String,
  visibility: json['visibility'] as String,
  createdAt: _timestampFromJson(json['createdAt']),
  lastActivityAt: _timestampFromJson(json['lastActivityAt']),
);

Map<String, dynamic> _$RoomToJson(Room instance) => <String, dynamic>{
  'creatorUid': instance.creatorUid,
  'title': instance.title,
  'maxPlayers': instance.maxPlayers,
  'status': instance.status,
  'matchMode': instance.matchMode,
  'visibility': instance.visibility,
  'createdAt': _timestampToJson(instance.createdAt),
  'lastActivityAt': _timestampToJson(instance.lastActivityAt),
};

Participant _$ParticipantFromJson(Map<String, dynamic> json) => Participant(
  uid: json['uid'] as String,
  status: json['status'] as String,
  joinedAt: _timestampFromJson(json['joinedAt']),
);

Map<String, dynamic> _$ParticipantToJson(Participant instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'status': instance.status,
      'joinedAt': _timestampToJson(instance.joinedAt),
    };
