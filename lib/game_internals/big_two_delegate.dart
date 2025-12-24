import 'package:ok_multipl_poker/entities/big_two_player.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/game_internals/card_suit.dart';
import 'package:ok_multipl_poker/game_internals/big_two_card_pattern.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';
import 'package:ok_multipl_poker/services/error_message_service.dart';
import 'big_two_deck_utils_mixin.dart';
import 'package:collection/collection.dart';

class BigTwoDelegate extends TurnBasedGameDelegate<BigTwoState> with BigTwoDeckUtilsMixin {
  ErrorMessageService? _errorMessageService;

  @override
  BigTwoState initializeGame(Room room) {
    final deck = PlayingCard.createDeck();
    final players = <BigTwoPlayer>[];
    var seats = List<String>.from(room.seats);
    
    // 2-Player Mode: Add Virtual Player
    if (seats.length == 2) {
      seats.add('virtual_player');
    }

    // Distribute cards: 3 seats, usually 17 cards each, 1 remainder
    // Total 52 cards. 52 ~/ 3 = 17. 52 % 3 = 1.
    final cardsPerPlayer = (deck.length / seats.length).floor();
    
    // Create initial players with cards
    for (int i = 0; i < seats.length; i++) {
      final uid = seats[i];
      final isVirtual = uid == 'virtual_player';
      final hand = deck.sublist(i * cardsPerPlayer, (i + 1) * cardsPerPlayer);
      
      String name;
      if (isVirtual) {
        name = 'Virtual Player';
      } else {
        name = room.participants.firstWhere((p) => p.id == seats[i]).name;
      }

      players.add(BigTwoPlayer(
        uid: uid,
        name: name,
        cards: hand.map(PlayingCard.cardToString).toList(),
        isVirtualPlayer: isVirtual,
      ));
    }

    // Identify the starting player (lowest human card)
    final lowestCardStr = _findLowestHumanCard(players);
    
    // Find who holds this lowest card
    String startingPlayerId = '';
    for (int i = 0; i < players.length; i++) {
      if (players[i].cards.contains(lowestCardStr)) {
        startingPlayerId = players[i].uid;
        break;
      }
    }

    // Distribute the remainder card (1 card) to the starting player (who holds the lowest card)
    // The remainder is at index: seats.length * cardsPerPlayer
    final remainderIndex = seats.length * cardsPerPlayer;
    if (remainderIndex < deck.length) {
       final extraCard = deck[remainderIndex];
       final extraCardStr = PlayingCard.cardToString(extraCard);
       
       // Add to starting player
       final playerIndex = players.indexWhere((p) => p.uid == startingPlayerId);
       if (playerIndex != -1) {
         final updatedCards = List<String>.from(players[playerIndex].cards)..add(extraCardStr);
         // Sort hand for tidiness (optional but good)
         final sortedHand = sortCardsByRank(updatedCards.map(PlayingCard.fromString).toList())
             .map(PlayingCard.cardToString).toList();
         
         players[playerIndex] = players[playerIndex].copyWith(cards: sortedHand);
       }
    }
    
    // Re-verify starting player just in case the extra card was even lower? 
    // Wait, the logic says "Distribute extra card to holder of CURRENT lowest card".
    // So the starting player is already determined.
    // Spec: "將該張餘牌分配給「持有目前最小牌」的真人玩家。" -> Done.

    return BigTwoState(
      participants: players,
      seats: seats,
      currentPlayerId: startingPlayerId.isNotEmpty ? startingPlayerId : seats.first,
    );
  }

  BigTwoPlayer myPlayer(String myUserId, BigTwoState bigTwoState) => bigTwoState.participants.firstWhere((p) => p.uid == myUserId);

  List<BigTwoPlayer> otherPlayers(String myUserId, BigTwoState bigTwoState) {
    final seatedPlayers = bigTwoState.seatedPlayersList();
    final currentIndex = bigTwoState.indexOfPlayerInSeats(myUserId, seatedPlayers: seatedPlayers)!;

    final total = seatedPlayers.length;
    final next1Index = currentIndex + 1;
    final seatOrder = Iterable.generate(total - 1, (i) => (i + next1Index) % total);
    return seatOrder.map((offset) => bigTwoState.participants[offset]).toList();
  }

  void setErrorMessageService(ErrorMessageService? service) {
    _errorMessageService = service;
  }

  @override
  BigTwoState processAction(
      BigTwoState currentState, String actionName, String participantId, Map<String, dynamic> payload) {
    if (_errorMessageService != null) {
      final seatedPlayers = currentState.seatedPlayersList();
      final currentIndex = currentState.indexOfPlayerInSeats(
          participantId, seatedPlayers: seatedPlayers)!;
      String debugMessage = "seats[$currentIndex]";
      debugMessage =
      "$debugMessage\nlockedHandType: ${currentState.lockedHandType}";
      debugMessage =
      "$debugMessage\nlastPlayedHand: ${currentState.lastPlayedHand}";
      debugMessage = "$debugMessage\npassCount: ${currentState
          .passCount}, passed: [${seatedPlayers.map((p) => p.hasPassed)}]";
      print("_____\n$debugMessage");
      _errorMessageService?.showError(debugMessage);
    }

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

      // Check if all REAL players requested restart (virtual players don't request)
      final realPlayersCount = currentState.participants.where((p) => !p.isVirtualPlayer).length;
      
      if (currentState.seats.isNotEmpty && newRequesters.length >= realPlayersCount) {
        // Re-initialization
        final deck = PlayingCard.createDeck();
        final seats = currentState.seats; // Includes virtual player if exists
        final cardsPerPlayer = (deck.length / seats.length).floor();
        
        final players = <BigTwoPlayer>[];

        for (int i = 0; i < seats.length; i++) {
            final uid = seats[i];
            final hand = deck.sublist(i * cardsPerPlayer, (i + 1) * cardsPerPlayer);
            
            // Find existing player info to preserve name/virtual status
            final existingPlayer = currentState.participants.firstWhere(
                (p) => p.uid == uid, 
                orElse: () => BigTwoPlayer(uid: uid, name: uid == 'virtual_player' ? 'Virtual Player' : 'Player', cards: [], isVirtualPlayer: uid == 'virtual_player')
            );
            
            players.add(existingPlayer.copyWith(
                cards: hand.map(PlayingCard.cardToString).toList(),
                hasPassed: false
            ));
        }

        // Logic for lowest card and extra card
        final lowestCardStr = _findLowestHumanCard(players);
        String startingPlayerId = '';
        for (final p in players) {
            if (p.cards.contains(lowestCardStr)) {
                startingPlayerId = p.uid;
                break;
            }
        }
        
        // Extra card
        final remainderIndex = seats.length * cardsPerPlayer;
        if (remainderIndex < deck.length) {
            final extraCard = deck[remainderIndex];
            final extraCardStr = PlayingCard.cardToString(extraCard);
            
            final pIndex = players.indexWhere((p) => p.uid == startingPlayerId);
            if (pIndex != -1) {
                final updatedCards = List<String>.from(players[pIndex].cards)..add(extraCardStr);
                 final sortedHand = sortCardsByRank(updatedCards.map(PlayingCard.fromString).toList())
                     .map(PlayingCard.cardToString).toList();
                players[pIndex] = players[pIndex].copyWith(cards: sortedHand);
            }
        }

        return BigTwoState(
          participants: players,
          seats: seats,
          currentPlayerId: startingPlayerId.isNotEmpty ? startingPlayerId : seats.first,
          // Defaults
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
    
    // Special rule: First hand of game must contain lowest card
    if (!validateFirstPlay(state, cardsPlayed)) return state;

    // Determine hand type and check validity
    final BigTwoCardPattern? playedPattern = getCardPattern(cardsPlayed);
    if (playedPattern == null) return state; // Invalid pattern

    // Check validity against locked state
    if (!checkPlayValidity(state, cardsPlayed, playedPattern)) {
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
    print("pass_turn state.passCount + 1");//TODO

    BigTwoState tempState = state.copyWith(
      participants: newParticipants,
      lastPlayedById: playerId,
      passCount: newPassCount,
    );

    return _nextTurn(tempState);
  }

  BigTwoState _nextTurn(BigTwoState state) {
    String? nextPid = state.nextPlayerId();

    List<BigTwoPlayer> participants = state.participants;
    String lockedHandType = state.lockedHandType;
    int passCount = state.passCount;
    List<String> lastPlayedHand = state.lastPlayedHand;
    String lastPlayedById = state.lastPlayedById;

    // Check if everyone else passed (Round Over / Free Turn for next player)
    // passCount counts how many CONSECUTIVE passes.
    // In 3 player game, if 2 people pass, the 3rd gets free turn.
    // seats.length - 1 is the threshold.

    if (passCount >= state.seats.length - 1 || nextPid == null) {
      // Reset hasPassed for all
      participants = participants.map((p) => p.copyWith(hasPassed: false)).toList();
      lockedHandType = "";
      passCount = 0;
      lastPlayedHand = []; // Reset last played hand on new round
      // lastPlayedById stays, but it doesn't matter as lockedHandType is empty
    }

    if (nextPid == null) {
      return state.copyWith(
        participants: participants,
        passCount: passCount,
        lockedHandType: lockedHandType,
        lastPlayedHand: lastPlayedHand,
      );
    }
    String nextPlayerId = nextPid;

    // Check if the next player is Virtual.
    // If Virtual, they automatically pass.
    final nextPlayer = participants.firstWhere((p) => p.uid == nextPlayerId);

    if (nextPlayer.isVirtualPlayer) {
        // Virtual player passes
        // But if Virtual player HAS control (free turn), they must play?
        // Spec says: "Virtual player holds cards but does not participate (skips/passes automatically)".
        // If Virtual player somehow got control (e.g. everyone else passed), they should pass control to next human?
        // But if everyone passed, the round is over, and the person who last played (Virtual?) starts.
        // Wait, Virtual player never plays, so they never become lastPlayedById.
        // So Virtual player only passes when it's their turn to FOLLOW.

        // Logic: Virtual player sets hasPassed = true, passCount++, then we recurse _nextTurn logic or loop.

        final updatedVirtualPlayer = nextPlayer.copyWith(hasPassed: true);
        final vIndex = participants.indexWhere((p) => p.uid == nextPlayerId);
        participants = List<BigTwoPlayer>.from(participants);
        participants[vIndex] = updatedVirtualPlayer;

        // If virtual player passes, check if round is over immediately?
        // If 3 players (A, B, V). A plays. B passes. V passes. Round over, A wins.
        passCount++;
        print("nextTurn passCount++");//TODO

        // Re-check round over condition
        if (passCount >= state.seats.length - 1) {
             participants = participants.map((p) => p.copyWith(hasPassed: false)).toList();
             lockedHandType = "";
             passCount = 0;
             lastPlayedHand = [];
             // Who starts? The person who played last.
             // If A played, B passed, V passed. nextPlayerId was V. V passed.
             // Now nextPlayerId should be A.

             // We need to calculate next player again from current state
             // But we are inside _nextTurn which returns a State.
             // Let's return the state with updated passCount and recurse _nextTurn?
             // But we need to update currentPlayerId to the one AFTER virtual player first?
        }

        // Update state with virtual player's pass
        final tempState = state.copyWith(
            participants: participants,
            passCount: passCount,
            currentPlayerId: nextPlayerId, // Temporarily set to V so nextPlayerId() can calculate from V
            lockedHandType: lockedHandType,
            lastPlayedHand: lastPlayedHand,
        );

        // Find who is after V
        String? afterVirtualPid = tempState.nextPlayerId();

        // If round ended due to V passing, the `lastPlayedById` should start.
        // `nextPlayerId()` in BigTwoState should handle "round over" logic?
        // Actually `nextPlayerId` just finds the next seated player who hasn't passed.
        // If everyone passed except one, `nextPlayerId` returns that one.

        return _nextTurn(tempState.copyWith(currentPlayerId: afterVirtualPid ?? nextPlayerId));
    }

    return state.copyWith(
        currentPlayerId: nextPlayerId,
        participants: participants,
        lockedHandType: lockedHandType,
        passCount: passCount,
        lastPlayedHand: lastPlayedHand,
        lastPlayedById: lastPlayedById,
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
  BigTwoCardPattern? getCardPattern(List<String> cardsStr) {
    final cards = cardsStr.map(PlayingCard.fromString).toList();

    if (isSingle(cards)) return BigTwoCardPattern.single;
    if (isPair(cards)) return BigTwoCardPattern.pair;
    
    if (cards.length == 5) {
      if (isStraightFlush(cards)) {
        if (_validateStrictStraightRange(cards)) return BigTwoCardPattern.straightFlush;
      }
      if (isFourOfAKind(cards)) return BigTwoCardPattern.fourOfAKind;
      if (isFullHouse(cards)) return BigTwoCardPattern.fullHouse;
      if (isStraight(cards)) {
        if (_validateStrictStraightRange(cards)) return BigTwoCardPattern.straight;
      }
    }
    
    return null;
  }
  
  /// Validates if the straight is strictly consecutive in the defined cycle:
  /// A, 2, 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K, A.
  /// Valid straights: A-2-3-4-5, 2-3-4-5-6, ... , 10-J-Q-K-A.
  /// Invalid examples: J-Q-K-A-2, Q-K-A-2-3, K-A-2-3-4.
  bool _validateStrictStraightRange(List<PlayingCard> cards) {
    final values = cards.map((c) => c.value).toSet();
    if (values.length != 5) return false;
    
    // Check A-2-3-4-5
    if (values.containsAll([1, 2, 3, 4, 5])) return true;
    
    // Check 2-3-4-5-6
    if (values.containsAll([2, 3, 4, 5, 6])) return true;
    
    // Check normal straights (3-4-5-6-7 to 9-10-J-Q-K)
    // And 10-J-Q-K-A
    
    // We can just sort by standard value (1..13) and check consecutiveness
    // BUT we need to handle 10-J-Q-K-A which wraps 13 -> 1.
    // 10-J-Q-K-A sorted values: 1, 10, 11, 12, 13
    
    final sortedVals = values.toList()..sort();
    
    // Case: 10-J-Q-K-A
    if (const ListEquality().equals(sortedVals, [1, 10, 11, 12, 13])) return true;
    
    // For other cases, must be consecutive
    for (int i = 0; i < sortedVals.length - 1; i++) {
        if (sortedVals[i + 1] != sortedVals[i] + 1) {
            return false;
        }
    }
    
    return true;
  }

  bool validateFirstPlay(BigTwoState state, List<String> cardsPlayed) {
    bool isFirstTurn = state.lastPlayedHand.isEmpty && state.lastPlayedById.isEmpty;
    if (!isFirstTurn) return true;
    
    // Find the required lowest card
    final lowestCardStr = _findLowestHumanCard(state.participants);
    
    if (!cardsPlayed.contains(lowestCardStr)) {
      return false; // First play must contain the lowest human card
    }
    return true;
  }
  
  /// Finds non-virtual player's lowest card
  String _findLowestHumanCard(List<BigTwoPlayer> players) {
    PlayingCard? lowestCard;
    
    for (final player in players) {
      if (player.isVirtualPlayer) continue;

      final hand = player.cards.map(PlayingCard.fromString).toList();
      if (hand.isEmpty) continue;
      
      final sortedHand = sortCardsByRank(hand);
      final playerLowest = sortedHand.first;
      
      if (lowestCard == null) {
        lowestCard = playerLowest;
        if (PlayingCard.cardToString(lowestCard) == 'C3') return 'C3';
      } else {
        if (_compareCards(playerLowest, lowestCard) < 0) {
          lowestCard = playerLowest;
          if (PlayingCard.cardToString(lowestCard) == 'C3') return 'C3';
        }
      }
    }
    return lowestCard != null ? PlayingCard.cardToString(lowestCard) : 'C3';
  }

  /// Checks if the played cards are valid against the current state logic.
  bool checkPlayValidity(BigTwoState state, List<String> cardsPlayed, BigTwoCardPattern playedPattern) {
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
      return isBeating(cardsPlayed, state.lastPlayedHand);
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
      return isBeating(cardsPlayed, state.lastPlayedHand);
    }

    // Standard Rule: Must match pattern
    if (playedPattern != lockedPattern) {
      return false;
    }

    // Compare same pattern
    return isBeating(cardsPlayed, state.lastPlayedHand);
  }

  /// Compares if [current] beats [previous]. Assumes both are of [pattern] or logic handled before.
  bool isBeating(List<String> currentStr, List<String> previousStr) {
    if (currentStr.length != previousStr.length) return false;
    final currentPattern = getCardPattern(currentStr);
    final previousPattern = getCardPattern(previousStr);

    if (currentPattern == null || previousPattern == null) return false;

    if (currentPattern == previousPattern) {
      return _beatsSamePattern(currentStr, previousStr, currentPattern);
    }
    else if (currentPattern == BigTwoCardPattern.straightFlush &&
        previousPattern != BigTwoCardPattern.straightFlush
    ) {
      return true;
    }
    else if (currentPattern == BigTwoCardPattern.fourOfAKind &&
        previousPattern != BigTwoCardPattern.straightFlush &&
        previousPattern != BigTwoCardPattern.fourOfAKind
    ) {
      return true;
    }
    
    return false;
  }

  /// Compares if [current] beats [previous]. Assumes both are of [pattern] or logic handled before.
  bool _beatsSamePattern(List<String> currentStr, List<String> previousStr, BigTwoCardPattern pattern) {
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
        final cLevel = _getStraightLevel(current);
        final pLevel = _getStraightLevel(previous);

        if (cLevel != pLevel) {
          return cLevel > pLevel;
        }

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

  int _getStraightLevel(List<PlayingCard> cards) {
    if (_is23456(cards)) return 2; // Max
    if (_isA2345(cards)) return 0; // Min
    return 1; // Normal
  }

  bool _isA2345(List<PlayingCard> cards) {
    final values = cards.map((c) => c.value).toSet();
    return values.containsAll([1, 2, 3, 4, 5]);
  }

  bool _is23456(List<PlayingCard> cards) {
    final values = cards.map((c) => c.value).toSet();
    return values.containsAll([2, 3, 4, 5, 6]);
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
    // Safety check, though should be validated by isFullHouse
    if (valueCounts.isEmpty) return 0;
    return valueCounts.entries.firstWhere((e) => e.value == 3, orElse: () => valueCounts.entries.first).key;
  }

  /// Returns the rank value of the four in Four of a Kind.
  int _getQuadRank(List<PlayingCard> cards) {
    final valueCounts = <int, int>{};
    for (final c in cards) {
      valueCounts[c.value] = (valueCounts[c.value] ?? 0) + 1;
    }
    if (valueCounts.isEmpty) return 0;
    return valueCounts.entries.firstWhere((e) => e.value == 4, orElse: () => valueCounts.entries.first).key;
  }
  
  // --- AI Helpers ---

  /// 功能 3: 回傳該玩家現在可以出的牌型種類 (考慮了 lockedHandType)
  List<BigTwoCardPattern> getPlayablePatterns(BigTwoState state, {List<PlayingCard>? handCards}) {
    if (state.lockedHandType.isEmpty) {
        return BigTwoCardPattern.values;
    }

    final locked = BigTwoCardPattern.fromJson(state.lockedHandType);
    final patterns = <BigTwoCardPattern>[locked];
    
    // Bombs can be played over anything (almost)
    if (locked != BigTwoCardPattern.straightFlush) {
        if (!patterns.contains(BigTwoCardPattern.straightFlush)) patterns.add(BigTwoCardPattern.straightFlush);
        if (!patterns.contains(BigTwoCardPattern.fourOfAKind)) patterns.add(BigTwoCardPattern.fourOfAKind);
    } else {
        // Only higher Straight Flush beats Straight Flush
        // already added locked (SF)
    }

    if (handCards == null) return patterns;

    final checkedPatterns = patterns
        .where((pattern) => _getCandidates(handCards, pattern).isNotEmpty)
        .toList();

    return checkedPatterns;
  }

  /// 功能 4: 針對特定牌型，回傳所有可打出的牌組 (必須 beat lastPlayedHand)
  List<List<String>> getPlayableCombinations(
      BigTwoState state, 
      List<PlayingCard> handCards, 
      BigTwoCardPattern pattern
  ) {
    final candidates = _getCandidates(handCards, pattern);
    
    // Filter by "isBeating"
    final validCombinations = <List<String>>[];
    for (final combo in candidates) {
        final comboStr = combo.map(PlayingCard.cardToString).toList();
        
        // If lockedHandType is empty, any combination of valid pattern is valid
        // But need to respect First Turn rule?
        // The helper "getPlayableCombinations" usually implies valid moves for current turn.
        // We should check `validateFirstPlay` as well if it's the first turn.
        
        // However, isBeating requires a previous hand.
        if (state.lockedHandType.isEmpty) {
             if (validateFirstPlay(state, comboStr)) {
                 validCombinations.add(comboStr);
             }
        } else {
             // Check if pattern matches locked pattern or is a bomb
             final lockedPattern = BigTwoCardPattern.fromJson(state.lockedHandType);
             
             // Bomb logic check
             bool isBomb = false;
             if (pattern == BigTwoCardPattern.straightFlush && lockedPattern != BigTwoCardPattern.straightFlush) isBomb = true;
             if (pattern == BigTwoCardPattern.fourOfAKind && 
                 lockedPattern != BigTwoCardPattern.fourOfAKind && 
                 lockedPattern != BigTwoCardPattern.straightFlush) {
               isBomb = true;
             }

             if (isBomb) {
               validCombinations.add(comboStr);
             }
             else if (pattern == lockedPattern && isBeating(comboStr, state.lastPlayedHand)) {
               validCombinations.add(comboStr);
             }
        }
    }
    
    return validCombinations;
  }

  /// 功能 5: 回傳當前所有可打出的牌組
  List<List<String>> getAllPlayableCombinations(BigTwoState state, List<PlayingCard> handCards) {
      final patterns = getPlayablePatterns(state);
      final allCombos = <List<String>>[];
      
      for (final p in patterns) {
          allCombos.addAll(getPlayableCombinations(state, handCards, p));
      }
      
      return allCombos;
  }

  List<List<PlayingCard>> _getCandidates(
      List<PlayingCard> handCards,
      BigTwoCardPattern pattern
      ) {
      List<List<PlayingCard>> candidates = [];

      switch (pattern) {
        case BigTwoCardPattern.single:
          candidates = findSingles(handCards);
          break;
        case BigTwoCardPattern.pair:
          candidates = findPairs(handCards);
          break;
        case BigTwoCardPattern.straight:
          candidates = findStraights(handCards);
          break;
        case BigTwoCardPattern.fullHouse:
          candidates = findFullHouses(handCards);
          break;
        case BigTwoCardPattern.fourOfAKind:
          candidates = findFourOfAKinds(handCards);
          break;
        case BigTwoCardPattern.straightFlush:
          candidates = findStraightFlushes(handCards);
          break;
      }

      return candidates;
  }
}
