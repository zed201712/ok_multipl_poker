// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'big_two_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BigTwoState _$BigTwoStateFromJson(Map<String, dynamic> json) => BigTwoState(
  participants: (json['participants'] as List<dynamic>)
      .map((e) => BigTwoPlayer.fromJson(e as Map<String, dynamic>))
      .toList(),
  seats: (json['seats'] as List<dynamic>).map((e) => e as String).toList(),
  currentPlayerId: json['currentPlayerId'] as String,
  lastPlayedHand:
      (json['lastPlayedHand'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  lastPlayedById: json['lastPlayedById'] as String? ?? '',
  winner: json['winner'] as String?,
  passCount: (json['passCount'] as num?)?.toInt() ?? 0,
  restartRequesters:
      (json['restartRequesters'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  deckCards:
      (json['deckCards'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  discardCards:
      (json['discardCards'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  lockedHandType: json['lockedHandType'] as String? ?? '',
);

Map<String, dynamic> _$BigTwoStateToJson(BigTwoState instance) =>
    <String, dynamic>{
      'participants': instance.participants.map((e) => e.toJson()).toList(),
      'seats': instance.seats,
      'currentPlayerId': instance.currentPlayerId,
      'lastPlayedHand': instance.lastPlayedHand,
      'lastPlayedById': instance.lastPlayedById,
      'winner': instance.winner,
      'passCount': instance.passCount,
      'restartRequesters': instance.restartRequesters,
      'deckCards': instance.deckCards,
      'discardCards': instance.discardCards,
      'lockedHandType': instance.lockedHandType,
    };
