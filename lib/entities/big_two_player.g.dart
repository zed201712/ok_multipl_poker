// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'big_two_player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BigTwoPlayer _$BigTwoPlayerFromJson(Map<String, dynamic> json) => BigTwoPlayer(
  uid: json['uid'] as String,
  cards: (json['cards'] as List<dynamic>).map((e) => e as String).toList(),
  name: json['name'] as String,
  hasPassed: json['hasPassed'] as bool? ?? false,
  isVirtualPlayer: json['isVirtualPlayer'] as bool? ?? false,
);

Map<String, dynamic> _$BigTwoPlayerToJson(BigTwoPlayer instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'cards': instance.cards,
      'hasPassed': instance.hasPassed,
      'isVirtualPlayer': instance.isVirtualPlayer,
    };
