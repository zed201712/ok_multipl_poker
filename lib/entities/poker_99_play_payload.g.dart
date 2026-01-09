// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poker_99_play_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Poker99PlayPayload _$Poker99PlayPayloadFromJson(Map<String, dynamic> json) =>
    Poker99PlayPayload(
      cards: (json['cards'] as List<dynamic>).map((e) => e as String).toList(),
      action: Poker99Action.fromJson(json['action'] as String),
      value: (json['value'] as num?)?.toInt() ?? 0,
      targetPlayerId: json['targetPlayerId'] as String? ?? '',
    );

Map<String, dynamic> _$Poker99PlayPayloadToJson(Poker99PlayPayload instance) =>
    <String, dynamic>{
      'cards': instance.cards,
      'action': Poker99PlayPayload._poker99ActionToJson(instance.action),
      'value': instance.value,
      'targetPlayerId': instance.targetPlayerId,
    };
