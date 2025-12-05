// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: json['id'] as String?,
  systemText: json['systemText'] as String?,
  uid: json['uid'] as String,
  targetUid: json['targetUid'] as String?,
  displayName: json['displayName'] as String,
  createdAt: _timestampToDateTime(json['createdAt'] as Timestamp?),
  roomId: json['roomId'] as String,
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'systemText': instance.systemText,
  'uid': instance.uid,
  'targetUid': instance.targetUid,
  'displayName': instance.displayName,
  'createdAt': _dateTimeToTimestamp(instance.createdAt),
  'roomId': instance.roomId,
};
