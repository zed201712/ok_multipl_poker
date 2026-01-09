// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poker_player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PokerPlayer _$PokerPlayerFromJson(Map<String, dynamic> json) => PokerPlayer(
  uid: json['uid'] as String,
  cards: (json['cards'] as List<dynamic>).map((e) => e as String).toList(),
  name: json['name'] as String,
  avatarNumber: (json['avatarNumber'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PokerPlayerToJson(PokerPlayer instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'cards': instance.cards,
      'avatarNumber': instance.avatarNumber,
    };
