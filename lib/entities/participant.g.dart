// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Participant _$ParticipantFromJson(Map<String, dynamic> json) => Participant(
  uid: json['uid'] as String,
  status: json['status'] as String,
  joinedAt: _timestampFromJson(json['joinedAt']),
  createdAt: _timestampFromJson(json['createdAt']),
  updatedAt: _timestampFromJson(json['updatedAt']),
);

Map<String, dynamic> _$ParticipantToJson(Participant instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'status': instance.status,
      'joinedAt': _timestampToJson(instance.joinedAt),
      'createdAt': _timestampToJson(instance.createdAt),
      'updatedAt': _timestampToJson(instance.updatedAt),
    };
