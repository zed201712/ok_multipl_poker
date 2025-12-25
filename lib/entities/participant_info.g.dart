// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParticipantInfo _$ParticipantInfoFromJson(Map<String, dynamic> json) =>
    ParticipantInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarNumber: json['avatarNumber'] as String? ?? '1',
    );

Map<String, dynamic> _$ParticipantInfoToJson(ParticipantInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatarNumber': instance.avatarNumber,
    };
