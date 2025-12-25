import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'big_two_player.dart';
import 'participant_info.dart';

part 'big_two_state.g.dart';

@JsonSerializable(explicitToJson: true)
class BigTwoState {
  final List<BigTwoPlayer> participants;
  final List<String> seats;
  final String currentPlayerId;
  final List<String> lastPlayedHand;
  final String lastPlayedById;
  final String? winner;
  final int passCount;
  final List<String> restartRequesters;
  final List<String> deckCards;
  final List<String> discardCards;
  final String lockedHandType;

  bool get isFirstTurn => discardCards.isEmpty && lastPlayedHand.isEmpty && deckCards.isEmpty;
  List<String> get uselessCards => deckCards + discardCards;

  BigTwoState({
    required this.participants,
    required this.seats,
    required this.currentPlayerId,
    this.lastPlayedHand = const [],
    this.lastPlayedById = '',
    this.winner,
    this.passCount = 0,
    this.restartRequesters = const [],
    this.deckCards = const [],
    this.discardCards = const [],
    this.lockedHandType = '',
  });

  factory BigTwoState.fromJson(Map<String, dynamic> json) =>
      _$BigTwoStateFromJson(json);

  factory BigTwoState.fromJsonString(String jsonString) {
    return BigTwoState.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => _$BigTwoStateToJson(this);

  String toJsonString() {
    return jsonEncode(toJson());
  }

  List<BigTwoPlayer> seatedPlayersList() {
    return seats
        .map((e) => participants.firstWhere((p) => p.uid == e))
        .toList();
  }

  BigTwoPlayer? getParticipantByID(String playerID) {
    return participants.firstWhereOrNull((p) => p.uid == playerID);
  }

  int? indexOfPlayerInSeats(String playerID, {List<BigTwoPlayer>? seatedPlayers}) {
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
        offset) => (currentSeats[offset].hasPassed == false));

    if (nextPlayerIndex == null) return null;
    return currentSeats[nextPlayerIndex].uid;
  }

  BigTwoState copyWith({
    List<BigTwoPlayer>? participants,
    List<String>? seats,
    String? currentPlayerId,
    List<String>? lastPlayedHand,
    String? lastPlayedById,
    String? winner,
    int? passCount,
    List<String>? restartRequesters,
    List<String>? deckCards,
    List<String>? discardCards,
    String? lockedHandType,
  }) {
    return BigTwoState(
      participants: participants ?? this.participants,
      seats: seats ?? this.seats,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      lastPlayedHand: lastPlayedHand ?? this.lastPlayedHand,
      lastPlayedById: lastPlayedById ?? this.lastPlayedById,
      winner: winner ?? this.winner,
      passCount: passCount ?? this.passCount,
      restartRequesters: restartRequesters ?? this.restartRequesters,
      deckCards: deckCards ?? this.deckCards,
      discardCards: discardCards ?? this.discardCards,
      lockedHandType: lockedHandType ?? this.lockedHandType,
    );
  }

}