// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poker_99_play_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Poker99PlayPayload _$Poker99PlayPayloadFromJson(Map<String, dynamic> json) =>
    Poker99PlayPayload(
      cards: (json['cards'] as List<dynamic>).map((e) => e as String).toList(),
      action: $enumDecode(_$Poker99ActionEnumMap, json['action']),
      value: (json['value'] as num?)?.toInt() ?? 0,
      targetPlayerId: json['targetPlayerId'] as String? ?? '',
    );

Map<String, dynamic> _$Poker99PlayPayloadToJson(Poker99PlayPayload instance) =>
    <String, dynamic>{
      'cards': instance.cards,
      'action': instance.action,
      'value': instance.value,
      'targetPlayerId': instance.targetPlayerId,
    };

const _$Poker99ActionEnumMap = {
  Poker99Action.increase: 'increase',
  Poker99Action.decrease: 'decrease',
  Poker99Action.skip: 'skip',
  Poker99Action.reverse: 'reverse',
  Poker99Action.target: 'target',
  Poker99Action.setToZero: 'setToZero',
  Poker99Action.setTo99: 'setTo99',
};
