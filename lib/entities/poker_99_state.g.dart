// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poker_99_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Poker99State _$Poker99StateFromJson(Map<String, dynamic> json) => Poker99State(
  participants: (json['participants'] as List<dynamic>)
      .map((e) => PokerPlayer.fromJson(e as Map<String, dynamic>))
      .toList(),
  seats: (json['seats'] as List<dynamic>).map((e) => e as String).toList(),
  currentPlayerId: json['currentPlayerId'] as String,
  lastPlayedHand:
      (json['lastPlayedHand'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  lastPlayedById: json['lastPlayedById'] as String? ?? '',
  lastAction: json['lastAction'] as String? ?? '',
  winner: json['winner'] as String?,
  currentScore: (json['currentScore'] as num?)?.toInt() ?? 0,
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
  isReverse: json['isReverse'] as bool? ?? false,
  targetPlayerId: json['targetPlayerId'] as String? ?? '',
  thinkingTimeLimit: (json['thinkingTimeLimit'] as num?)?.toInt() ?? 5,
);

Map<String, dynamic> _$Poker99StateToJson(Poker99State instance) =>
    <String, dynamic>{
      'participants': instance.participants.map((e) => e.toJson()).toList(),
      'seats': instance.seats,
      'currentPlayerId': instance.currentPlayerId,
      'lastPlayedHand': instance.lastPlayedHand,
      'lastPlayedById': instance.lastPlayedById,
      'lastAction': instance.lastAction,
      'winner': instance.winner,
      'currentScore': instance.currentScore,
      'restartRequesters': instance.restartRequesters,
      'deckCards': instance.deckCards,
      'discardCards': instance.discardCards,
      'isReverse': instance.isReverse,
      'targetPlayerId': instance.targetPlayerId,
      'thinkingTimeLimit': instance.thinkingTimeLimit,
    };
