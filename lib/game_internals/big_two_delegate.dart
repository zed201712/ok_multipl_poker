import 'package:ok_multipl_poker/entities/big_two_player.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/game_internals/card_suit.dart';
import 'package:ok_multipl_poker/game_internals/big_two_card_pattern.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';
import 'big_two_deck_utils_mixin.dart';

class BigTwoDelegate extends TurnBasedGameDelegate<BigTwoState> with BigTwoDeckUtilsMixin {
  @override
  BigTwoState initializeGame(Room room) {
    final deck = PlayingCard.createDeck();
    final players = <BigTwoPlayer>[];
    final seats = room.seats;

    // Distribute cards to players
    final cardsPerPlayer = (deck.length / seats.length).floor();
    for (int i = 0; i < seats.length; i++) {
      final hand = deck.sublist(i * cardsPerPlayer, (i + 1) * cardsPerPlayer);
      players.add(BigTwoPlayer(
        uid: seats[i],
        name: room.participants.firstWhere((p) => p.id == seats[i]).name,
        cards: hand.map(PlayingCard.cardToString).toList(),
      ));
    }

    // Find who has the 3 of clubs to start
    String? startingPlayerId;
    for (var player in players) {
      if (player.cards.contains('C3')) {
        startingPlayerId = player.uid;
        break;
      }
    }

    return BigTwoState(
      participants: players,
      seats: seats,
      currentPlayerId: startingPlayerId ?? seats.first,
    );
  }

  BigTwoPlayer myPlayer(String myUserId, BigTwoState bigTwoState) => bigTwoState.participants.firstWhere((p) => p.uid == myUserId);

  List<BigTwoPlayer> otherPlayers(String myUserId, BigTwoState bigTwoState) => bigTwoState.participants.where((p) => p.uid != myUserId).toList();

  @override
  BigTwoState processAction(
      BigTwoState currentState, String actionName, String participantId, Map<String, dynamic> payload) {

    print("BigTwoDelegate: processAction called with actionName: $actionName");
    // 0. 基礎檢查
    if (currentState.winner != null && actionName != 'request_restart') return currentState;

    // 1. 處理重開局
    if (actionName == 'request_restart') {
      return _processRestartRequest(currentState, participantId);
    }

    // 2. 輪次檢查
    if (currentState.currentPlayerId != participantId) return currentState;

    // 3. 分派動作
    if (actionName == 'play_cards') {
      final cardsStr = List<String>.from(payload['cards'] ?? []);
      return _playCards(currentState, participantId, cardsStr);
    } else if (actionName == 'pass_turn') {
      return _passTurn(currentState, participantId);
    }
    
    return currentState;
  }

  BigTwoState _processRestartRequest(BigTwoState currentState, String participantId) {
     final newRequesters = List<String>.from(currentState.restartRequesters);
      if (!newRequesters.contains(participantId)) {
        newRequesters.add(participantId);
      }

      // Check if all players requested restart
      if (currentState.seats.isNotEmpty && newRequesters.length >= currentState.seats.length) {
        // Simulating re-initialization logic similar to initializeGame but reusing seats
        final deck = PlayingCard.createDeck();
        final Map<String, List<String>> hands = {};
        final seats = currentState.seats;
        final cardsPerPlayer = (deck.length / seats.length).floor();

        for (int i = 0; i < seats.length; i++) {
            final hand = deck.sublist(i * cardsPerPlayer, (i + 1) * cardsPerPlayer);
            hands[seats[i]] = hand.map(PlayingCard.cardToString).toList();
        }

        String startingPlayerId = seats.isNotEmpty ? seats[0] : '';
        for (final entry in hands.entries) {
           if (entry.value.contains('C3')) {
             startingPlayerId = entry.key;
             break;
           }
        }

        final participants = seats.map((uid) {
          // Try to keep existing name if possible, though State doesn't easily link back to Room participants here without extra logic.
          // We just reuse the name from previous state if available.
          final oldName = currentState.participants.firstWhere((p) => p.uid == uid, orElse: () => BigTwoPlayer(uid: uid, name: 'Player', cards: [])).name;
          return BigTwoPlayer(uid: uid, name: oldName, cards: hands[uid] ?? []);
        }).toList();

        return BigTwoState(
          participants: participants,
          seats: seats,
          currentPlayerId: startingPlayerId,
          // Defaults for other fields (deckCards=[], lockedHandType='') are correct for new game
        );
      }

      return currentState.copyWith(
        restartRequesters: newRequesters,
      );
  }

  BigTwoState _playCards(BigTwoState state, String playerId, List<String> cardsPlayed) {
    // 1. Validate if player has these cards
    final playerIndex = state.participants.indexWhere((p) => p.uid == playerId);
    if (playerIndex == -1) return state;
    final player = state.participants[playerIndex];
    
    // Verify cards are in hand and remove them (handling duplicates strictly)
    final tempHand = List<String>.from(player.cards);
    for (final card in cardsPlayed) {
      if (!tempHand.remove(card)) {
        return state; 
      }
    }

    // 2. Validate move logic (Big Two Rules)
    
    // Special rule: First hand of game must contain 3 of Clubs if it's the very first turn.
    bool isFirstTurn = state.lastPlayedHand.isEmpty && state.lastPlayedById.isEmpty; 
    if (isFirstTurn) {
      if (!cardsPlayed.contains('C3')) {
         return state; // First play must contain 3 of Clubs
      }
    }

    // Determine hand type and check validity
    final BigTwoCardPattern? playedPattern = _getCardPattern(cardsPlayed);
    if (playedPattern == null) return state; // Invalid pattern

    // Check validity against locked state
    if (!_checkPlayValidity(state, cardsPlayed, playedPattern)) {
      return state;
    }

    // 3. Execute Play
    final newCards = tempHand;

    final newPlayer = player.copyWith(
      cards: newCards,
      hasPassed: false
    );
    
    final newParticipants = List<BigTwoPlayer>.from(state.participants);
    newParticipants[playerIndex] = newPlayer;

    // Check Winner
    String? newWinner = state.winner;
    if (newCards.isEmpty) {
      newWinner = playerId;
    }

    // Update Deck
    final newDeckCards = List<String>.from(state.deckCards)..addAll(cardsPlayed);

    // Update lockedHandType
    String newLockedHandType = playedPattern.toJson();

    final tempState = state.copyWith(
      participants: newParticipants,
      deckCards: newDeckCards,
      lastPlayedHand: cardsPlayed,
      lastPlayedById: playerId,
      passCount: 0, 
      lockedHandType: newLockedHandType,
      winner: newWinner,
    );

    return _nextTurn(tempState);
  }

  BigTwoState _passTurn(BigTwoState state, String playerId) {
    // Cannot pass if you have control
    if (state.lastPlayedById == playerId) return state;

    final playerIndex = state.participants.indexWhere((p) => p.uid == playerId);
    if (playerIndex == -1) return state;
    
    final player = state.participants[playerIndex];
    final newPlayer = player.copyWith(hasPassed: true);

    final newParticipants = List<BigTwoPlayer>.from(state.participants);
    newParticipants[playerIndex] = newPlayer;

    int newPassCount = state.passCount + 1;

    BigTwoState tempState = state.copyWith(
      participants: newParticipants,
      passCount: newPassCount,
    );

    return _nextTurn(tempState);
  }

  BigTwoState _nextTurn(BigTwoState state) {
    String? nextPid = state.nextPlayerId();
    if (nextPid == null) return state; 

    String nextPlayerId = nextPid;
    List<BigTwoPlayer> participants = state.participants;
    String lockedHandType = state.lockedHandType;
    int passCount = state.passCount;
    List<String> lastPlayedHand = state.lastPlayedHand;

    // Check if everyone else passed (Round Over / Free Turn for next player)
    if (passCount >= state.seats.length - 1) {
        // Reset hasPassed for all
        participants = participants.map((p) => p.copyWith(hasPassed: false)).toList();
        lockedHandType = "";
        passCount = 0; 
        lastPlayedHand = []; // Reset last played hand on new round
    }

    return state.copyWith(
        currentPlayerId: nextPlayerId,
        participants: participants,
        lockedHandType: lockedHandType,
        passCount: passCount,
        lastPlayedHand: lastPlayedHand,
    );
  }

  @override
  String? getCurrentPlayer(BigTwoState state) {
    return state.currentPlayerId;
  }

  @override
  String? getWinner(BigTwoState state) {
    return state.winner;
  }

  @override
  BigTwoState stateFromJson(Map<String, dynamic> json) {
    return BigTwoState.fromJson(json);
  }

  @override
  Map<String, dynamic> stateToJson(BigTwoState state) {
    return state.toJson();
  }
  
  // --- Helper Methods for Card Logic ---
  
  /// Identifies the pattern of the played cards.
  BigTwoCardPattern? _getCardPattern(List<String> cardsStr) {
    final cards = cardsStr.map(PlayingCard.fromString).toList();

    if (isSingle(cards)) return BigTwoCardPattern.single;
    if (isPair(cards)) return BigTwoCardPattern.pair;
    
    if (cards.length == 5) {
      if (isStraightFlush(cards)) return BigTwoCardPattern.straightFlush;
      if (isFourOfAKind(cards)) return BigTwoCardPattern.fourOfAKind;
      if (isFullHouse(cards)) return BigTwoCardPattern.fullHouse;
      if (isStraight(cards)) return BigTwoCardPattern.straight;
    }
    
    return null;
  }

  /// Checks if the played cards are valid against the current state logic.
  bool _checkPlayValidity(BigTwoState state, List<String> cardsPlayed, BigTwoCardPattern playedPattern) {
    if (state.lockedHandType.isEmpty) {
      // Free turn: Any valid pattern is allowed
      return true;
    }

    final lockedPattern = BigTwoCardPattern.fromJson(state.lockedHandType);

    // Special Bomb/Beat Rules
    // 1. Straight Flush beats anything except higher Straight Flush
    if (playedPattern == BigTwoCardPattern.straightFlush) {
      if (lockedPattern != BigTwoCardPattern.straightFlush) {
        return true; // Bomb!
      }
      // Compare two Straight Flushes
      return _isBeating(cardsPlayed, state.lastPlayedHand, playedPattern);
    }

    // 2. Four of a Kind beats anything except Straight Flush and higher Four of a Kind
    if (playedPattern == BigTwoCardPattern.fourOfAKind) {
      if (lockedPattern == BigTwoCardPattern.straightFlush) {
        return false; // Can't beat SF
      }
      if (lockedPattern != BigTwoCardPattern.fourOfAKind) {
        return true; // Bomb! (Beats Straight, FullHouse, etc.)
      }
      // Compare two Four of a Kinds
      return _isBeating(cardsPlayed, state.lastPlayedHand, playedPattern);
    }

    // Standard Rule: Must match pattern
    if (playedPattern != lockedPattern) {
      return false;
    }

    // Compare same pattern
    return _isBeating(cardsPlayed, state.lastPlayedHand, playedPattern);
  }

  /// Compares if [current] beats [previous]. Assumes both are of [pattern] or logic handled before.
  bool _isBeating(List<String> currentStr, List<String> previousStr, BigTwoCardPattern pattern) {
    if (currentStr.length != previousStr.length) return false;
    
    final current = currentStr.map(PlayingCard.fromString).toList();
    final previous = previousStr.map(PlayingCard.fromString).toList();

    switch (pattern) {
      case BigTwoCardPattern.single:
        return _compareCards(current[0], previous[0]) > 0;
      case BigTwoCardPattern.pair:
         final cMax = sortCardsByRank(current).last;
         final pMax = sortCardsByRank(previous).last;
         return _compareCards(cMax, pMax) > 0;
      
      case BigTwoCardPattern.straight:
      case BigTwoCardPattern.straightFlush:
        final cRank = _getStraightRankCard(current);
        final pRank = _getStraightRankCard(previous);
        return _compareCards(cRank, pRank) > 0;

      case BigTwoCardPattern.fullHouse:
        final cTrip = _getTripletRank(current);
        final pTrip = _getTripletRank(previous);
        return getBigTwoValue(cTrip) > getBigTwoValue(pTrip);

      case BigTwoCardPattern.fourOfAKind:
        final cQuad = _getQuadRank(current);
        final pQuad = _getQuadRank(previous);
        return getBigTwoValue(cQuad) > getBigTwoValue(pQuad);
    }
  }
  
  int _compareCards(PlayingCard a, PlayingCard b) {
    final rankComp = getBigTwoValue(a.value).compareTo(getBigTwoValue(b.value));
    if (rankComp != 0) return rankComp;
    return getSuitValue(a.suit).compareTo(getSuitValue(b.suit));
  }

  /// Returns the card that determines the value of the straight.
  PlayingCard _getStraightRankCard(List<PlayingCard> cards) {
    final sorted = sortCardsByRank(cards);
    return sorted.last;
  }

  /// Returns the rank value of the triplet in a Full House.
  int _getTripletRank(List<PlayingCard> cards) {
     final valueCounts = <int, int>{};
    for (final c in cards) {
      valueCounts[c.value] = (valueCounts[c.value] ?? 0) + 1;
    }
    return valueCounts.entries.firstWhere((e) => e.value == 3).key;
  }

  /// Returns the rank value of the four in Four of a Kind.
  int _getQuadRank(List<PlayingCard> cards) {
    final valueCounts = <int, int>{};
    for (final c in cards) {
      valueCounts[c.value] = (valueCounts[c.value] ?? 0) + 1;
    }
    return valueCounts.entries.firstWhere((e) => e.value == 4).key;
  }
}
