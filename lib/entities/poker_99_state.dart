import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ok_multipl_poker/entities/poker_player.dart';
import 'big_two_player.dart';

part 'poker_99_state.g.dart';

@JsonSerializable(explicitToJson: true)
class Poker99State {
  final List<PokerPlayer> participants;
  final List<String> seats;
  final String currentPlayerId;
  final List<String> lastPlayedHand;
  final String lastPlayedById;
  final String lastAction;
  final String? winner;
  final int currentScore;
  final List<String> restartRequesters;
  final List<String> deckCards;
  final List<String> discardCards;
  final bool isReverse;
  final String targetPlayerId;
  final int thinkingTimeLimit;

  bool get isFirstTurn => discardCards.isEmpty && lastPlayedHand.isEmpty && deckCards.isEmpty;
  List<String> get uselessCards => deckCards + discardCards;

  Poker99State({
    required this.participants,
    required this.seats,
    required this.currentPlayerId,
    this.lastPlayedHand = const [],
    this.lastPlayedById = '',
    this.lastAction = '',
    this.winner,
    this.currentScore = 0,
    this.restartRequesters = const [],
    this.deckCards = const [],
    this.discardCards = const [],
    this.isReverse = false,
    this.targetPlayerId = '',
    this.thinkingTimeLimit = 5,
  });

  factory Poker99State.fromJson(Map<String, dynamic> json) =>
      _$Poker99StateFromJson(json);

  factory Poker99State.fromJsonString(String jsonString) {
    return Poker99State.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => _$Poker99StateToJson(this);

  String toJsonString() {
    return jsonEncode(toJson());
  }

  List<PokerPlayer> seatedPlayersList() {
    return seats
        .map((e) => participants.firstWhere((p) => p.uid == e))
        .toList();
  }

  PokerPlayer? getParticipantByID(String playerID) {
    return participants.firstWhereOrNull((p) => p.uid == playerID);
  }

  int? indexOfPlayerInSeats(String playerID, {List<PokerPlayer>? seatedPlayers}) {
    final participants = seatedPlayers ?? seatedPlayersList();

    final total = participants.length;
    try {
      final currentIndex = Iterable.generate(total, (i) => i)
          .firstWhere((i) => participants[i].uid == playerID);
      return currentIndex;
    }
    catch (e) {
      print('Error indexOfPlayerInSeats: $e');
    }
    return null;
  }

  String? nextPlayerId() {
    final currentSeats = seatedPlayersList();
    if (currentSeats.isEmpty) return null;
    final total = currentSeats.length;

    final currentIndex = Iterable.generate(total, (i) => i)
        .firstWhere((i) => currentSeats[i].uid == currentPlayerId);

    final next1Index = currentIndex + 1;
    final range = Iterable.generate(total - 1, (i) => (i + next1Index) % total);
    final nextPlayerIndex = range.firstWhereOrNull((
        offset) => (currentSeats[offset].cards.isNotEmpty));

    if (nextPlayerIndex == null) return null;
    return currentSeats[nextPlayerIndex].uid;
  }

  Poker99State copyWith({
    List<PokerPlayer>? participants,
    List<String>? seats,
    String? currentPlayerId,
    List<String>? lastPlayedHand,
    String? lastPlayedById,
    String? lastAction,
    String? winner,
    int? currentScore,
    List<String>? restartRequesters,
    List<String>? deckCards,
    List<String>? discardCards,
    bool? isReverse,
    String? targetPlayerId,
    int? thinkingTimeLimit,
  }) {
    return Poker99State(
      participants: participants ?? this.participants,
      seats: seats ?? this.seats,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      lastPlayedHand: lastPlayedHand ?? this.lastPlayedHand,
      lastPlayedById: lastPlayedById ?? this.lastPlayedById,
      lastAction: lastAction ?? this.lastAction,
      winner: winner ?? this.winner,
      currentScore: currentScore ?? this.currentScore,
      restartRequesters: restartRequesters ?? this.restartRequesters,
      deckCards: deckCards ?? this.deckCards,
      discardCards: discardCards ?? this.discardCards,
      isReverse: isReverse ?? this.isReverse,
      targetPlayerId: targetPlayerId ?? this.targetPlayerId,
      thinkingTimeLimit: thinkingTimeLimit ?? this.thinkingTimeLimit,
    );
  }

}