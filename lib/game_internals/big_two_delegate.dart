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
    seats = room.randomizeSeats ? (seats..shuffle()) : seats;

    // Add Virtual Player
    if (seats.length <= 2) {
      final virtualPlayerCount = 3 - seats.length;
      final virtualPlayers = Iterable.generate(virtualPlayerCount, (i) => i + 1)
          .map((i) => "virtual_player$i");
      seats.addAll(virtualPlayers);
    }

    // Distribute cards: 3 seats, usually 17 cards each, 1 remainder
    // Total 52 cards. 52 ~/ 3 = 17. 52 % 3 = 1.
    final cardsPerPlayer = (deck.length / seats.length).floor();
    
    // Create initial players with cards
    for (int i = 0; i < seats.length; i++) {
      final uid = seats[i];
      final isVirtual = uid.startsWith('virtual_player');
      final hand = deck.sublist(i * cardsPerPlayer, (i + 1) * cardsPerPlayer);
      
      String name;
      String avatarNumber;
      if (isVirtual) {
        name = uid;
        avatarNumber = room.participants.first.avatarNumber;
      } else {
        final participant = room.participants.firstWhere((p) => p.id == seats[i]);
        name = participant.name;
        avatarNumber = participant.avatarNumber;
      }

      players.add(BigTwoPlayer(
        uid: uid,
        name: name,
        cards: hand.map(PlayingCard.cardToString).toList(),
        hasPassed: isVirtual,
        isVirtualPlayer: isVirtual,
        avatarNumber: avatarNumber,
      ));
    }

    // Identify the starting player (lowest human card)
    final lowestCardStr = PlayingCard.cardToString(findLowestHumanCard(players));
    
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
         final sortedHand = sortCardsByRank(updatedCards.toPlayingCards())
             .toStringCards();
         
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
      Room room, BigTwoState currentState, String actionName, String participantId, Map<String, dynamic> payload) {
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
      return _processRestartRequest(room, currentState, participantId);
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

  BigTwoState _processRestartRequest(Room room, BigTwoState currentState, String participantId) {
     final newRequesters = List<String>.from(currentState.restartRequesters);
      if (!newRequesters.contains(participantId)) {
        newRequesters.add(participantId);
      }

      // Check if all REAL players requested restart (virtual players don't request)
      final realPlayersCount = currentState.participants.where((p) => !p.isVirtualPlayer).length;
      
      if (currentState.seats.isNotEmpty && newRequesters.length >= realPlayersCount) {
        // Re-initialization
        return initializeGame(room);
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
    final cards = cardsPlayed.toPlayingCards();
    if (!validateFirstPlay(state, cards)) return state;

    // Determine hand type and check validity
    final BigTwoCardPattern? playedPattern = getCardPattern(cards);

    // Check validity against locked state
    if (playedPattern == null || !checkPlayValidity(state, cards, playedPattern: playedPattern)) {
      return state;
    }

    // 3. Execute Play
    final newCards = tempHand;

    final newPlayer = player.copyWith(
      cards: newCards,
    );
    
    final newParticipants = List<BigTwoPlayer>.from(state.participants);
    newParticipants[playerIndex] = newPlayer;

    // Check Winner
    String? newWinner = state.winner;
    if (newCards.isEmpty) {
      newWinner = playerId;
    }

    // Update Deck
    final newDeckCards = List<String>.from(state.lastPlayedHand)..addAll(state.deckCards);

    // Update lockedHandType
    String newLockedHandType = playedPattern.toJson();

    final tempState = state.copyWith(
      participants: newParticipants,
      deckCards: newDeckCards,
      lastPlayedHand: cardsPlayed,
      lastPlayedById: playerId,
      lockedHandType: newLockedHandType,
      winner: newWinner,
    );

    if (newWinner != null) {
      return tempState.copyWith(
        seats: tempState.seats.where((s) => !s.startsWith('virtual_player')).toList(),
      );
    }

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

    BigTwoState tempState = state.copyWith(
      participants: newParticipants,
      lastPlayedById: playerId,
      passCount: _currentPassCount(newParticipants),
    );

    return _nextTurn(tempState);
  }

  BigTwoState _nextTurn(BigTwoState state) {
    String? nextPlayerId = state.nextPlayerId();

    List<BigTwoPlayer> participants = state.participants;
    String lockedHandType = state.lockedHandType;
    int passCount = state.passCount;
    List<String> lastPlayedHand = state.lastPlayedHand;
    List<String> deckCards = state.deckCards;
    List<String> discardCards = state.discardCards;

    if (passCount >= state.seats.length - 1 || nextPlayerId == null) {
      // Reset hasPassed for all if participant is not a VirtualPlayer
      participants = participants.map((p) => p.copyWith(hasPassed: p.isVirtualPlayer)).toList();
      lockedHandType = "";
      passCount = _currentPassCount(participants);

      discardCards = List<String>.from(lastPlayedHand)..addAll(deckCards)..addAll(discardCards);

      deckCards = [];
      lastPlayedHand = []; // Reset last played hand on new round
    }

    return state.copyWith(
        currentPlayerId: nextPlayerId,
        participants: participants,
        lockedHandType: lockedHandType,
        passCount: passCount,
        lastPlayedHand: lastPlayedHand,
        deckCards: deckCards,
        discardCards: discardCards,
    );
  }
  
  int _currentPassCount(List<BigTwoPlayer> players) {
    return players.where((p) => p.hasPassed).length;
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
  List<List<PlayingCard>> getPlayableCombinations(
      BigTwoState state, 
      List<PlayingCard> handCards, 
      BigTwoCardPattern pattern
  ) {
    final candidates = _getCandidates(handCards, pattern);
    
    // Filter by "isBeating"
    final validCombinations = <List<PlayingCard>>[];
    for (final combo in candidates) {
        // If lockedHandType is empty, any combination of valid pattern is valid
        // But need to respect First Turn rule?
        // The helper "getPlayableCombinations" usually implies valid moves for current turn.
        // We should check `validateFirstPlay` as well if it's the first turn.
        
        // However, isBeating requires a previous hand.
        if (state.lockedHandType == '') {
            validCombinations.add(combo);
        }
        else if (state.isFirstTurn) {
             if (validateFirstPlay(state, combo)) {
                 validCombinations.add(combo);
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
               validCombinations.add(combo);
             }
             else if (pattern == lockedPattern && isBeating(combo, state.lastPlayedHand.toPlayingCards())) {
               validCombinations.add(combo);
             }
        }
    }
    
    return validCombinations;
  }

  /// 功能 5: 回傳當前所有可打出的牌組
  List<List<PlayingCard>> getAllPlayableCombinations(BigTwoState state, List<PlayingCard> handCards) {
      final patterns = getPlayablePatterns(state);
      final allCombos = <List<PlayingCard>>[];
      
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

  /// 根據手牌回傳所有「持有」的牌型 (用於 UI 高亮)
  Set<BigTwoCardPattern> getHoldingPatterns(List<PlayingCard> hand) {
    final holding = <BigTwoCardPattern>{};
    if (findSingles(hand).isNotEmpty) holding.add(BigTwoCardPattern.single);
    if (findPairs(hand).isNotEmpty) holding.add(BigTwoCardPattern.pair);
    if (findStraights(hand).isNotEmpty) holding.add(BigTwoCardPattern.straight);
    if (findFullHouses(hand).isNotEmpty) holding.add(BigTwoCardPattern.fullHouse);
    if (findFourOfAKinds(hand).isNotEmpty) holding.add(BigTwoCardPattern.fourOfAKind);
    if (findStraightFlushes(hand).isNotEmpty) holding.add(BigTwoCardPattern.straightFlush);
    return holding;
  }
}
