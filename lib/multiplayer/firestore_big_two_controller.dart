import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ok_multipl_poker/entities/big_two_player.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/settings/settings.dart';

import '../game_internals/card_suit.dart';

class FirestoreBigTwoController {
  /// 遊戲狀態的響應式數據流。
  late final Stream<TurnBasedGameState<BigTwoState>?> gameStateStream;

  /// 底層的回合制遊戲控制器。
  late final FirestoreTurnBasedGameController<BigTwoState> _gameController;

  /// 建構子，要求傳入 Firestore 和 Auth 實例。
  FirestoreBigTwoController({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required SettingsController settingsController,
  }) {
    _gameController = FirestoreTurnBasedGameController<BigTwoState>(
      store: firestore,
      auth: auth,
      delegate: BigTwoDelegate(),
      collectionName: 'big_two_rooms',
      settingsController: settingsController,
    );
    gameStateStream = _gameController.gameStateStream;
  }

  /// 匹配並加入一個最多4人的遊戲房間。
  /// 成功時返回房間 ID。
  Future<String?> matchRoom() async {
    try {
      final roomId = await _gameController.matchAndJoinRoom(maxPlayers: 4);
      return roomId;
    } catch (e) {
      // You might want to log this error or rethrow a specific exception
      return null;
    }
  }

  /// 離開當前所在的房間。
  Future<void> leaveRoom() async {
    await _gameController.leaveRoom();
  }

  /// 發起重新開始遊戲的請求。
  /// 所有玩家都請求後，遊戲將會重置。
  Future<void> restart() async {
    _gameController.sendGameAction('request_restart');
  }

  /// 玩家出牌。
  /// [cards] 是一個代表玩家要出的牌的列表。
  Future<void> playCards(List<PlayingCard> cards) async {
    final cardStrings = cards.map((c) => PlayingCard.cardToString(c)).toList();
    _gameController.sendGameAction('play_cards', payload: {'cards': cardStrings});
  }

  /// 玩家選擇 pass。
  Future<void> passTurn() async {
    _gameController.sendGameAction('pass_turn');
  }

  /// 釋放資源，關閉數據流。
  void dispose() {
    _gameController.dispose();
  }
}

class BigTwoDelegate implements TurnBasedGameDelegate<BigTwoState> {
  @override
  BigTwoState stateFromJson(Map<String, dynamic> json) {
    return BigTwoState.fromJson(json);
  }

  @override
  Map<String, dynamic> stateToJson(BigTwoState state) {
    return state.toJson();
  }

  @override
  BigTwoState initializeGame(Room room) {
    // 1. Create a shuffled deck
    final deck = PlayingCard.createDeck();

    // 2. Deal cards to 4 players (13 cards each)
    // Assumes room has 4 participants for a standard Big Two game.
    // If fewer, we can still deal, but logic might need adjustment.
    final playerIds = room.seats;
    final Map<String, List<String>> hands = {};

    int cardIndex = 0;
    for (final playerId in playerIds) {
      final playerCards = <PlayingCard>[];
      for (int i = 0; i < 13; i++) {
        if (cardIndex < deck.length) {
          playerCards.add(deck[cardIndex++]);
        }
      }
      // Sort hands for better UX and logic (optional but recommended)
      // Here we store as strings.
      hands[playerId] = playerCards.map((c) => PlayingCard.cardToString(c)).toList();
    }
    
    // 3. Determine starting player (player with 3 of Clubs)
    String startingPlayerId = playerIds.isNotEmpty ? playerIds[0] : '';
    const threeOfClubsStr = 'C3'; // Assuming PlayingCard.cardToString uses this format

    for (final entry in hands.entries) {
      if (entry.value.contains(threeOfClubsStr)) {
        startingPlayerId = entry.key;
        break;
      }
    }

    // 4. Create BigTwoPlayer objects
    final participants = playerIds.map((uid) {
      // Name resolution would ideally happen elsewhere or be passed in, 
      // for now using empty or placeholder if not available in Room immediately in this context
      return BigTwoPlayer(
        uid: uid,
        name: 'Player', // Placeholder, UI should resolve names
        cards: hands[uid] ?? [],
      );
    }).toList();

    return BigTwoState(
      participants: participants,
      seats: playerIds,
      currentPlayerId: startingPlayerId,
      lastPlayedHand: [],
      lastPlayedById: '',
      winner: null,
      passCount: 0,
    );
  }

  @override
  BigTwoState processAction(BigTwoState currentState, String actionName, String participantId, Map<String, dynamic> payload) {
    if (actionName == 'request_restart') {
      return _processRestartRequest(currentState, participantId);
    }

    // Basic validation: Check if game is over or if it's player's turn
    if (currentState.winner != null) return currentState;
    if (currentState.currentPlayerId != participantId) return currentState;

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
        // In a real scenario, we might need access to the Room object to re-initialize correctly 
        // with the same players. Since initializeGame takes a Room, and here we return a State...
        // The TurnBasedGameController normally handles 'restart' by calling initializeGame again 
        // if the logic was built that way. However, here we are inside processAction which returns a State.
        // 
        // If we want to reset state here, we can basically do what initializeGame does but reusing seats.
        // Since we don't have the Room object here easily, we can just re-deal.
        
        // Simulating re-initialization:
        final deck = PlayingCard.createDeck();
        final Map<String, List<String>> hands = {};
        int cardIndex = 0;
        for (final playerId in currentState.seats) {
          final playerCards = <PlayingCard>[];
          for (int i = 0; i < 13; i++) {
             if (cardIndex < deck.length) playerCards.add(deck[cardIndex++]);
          }
          hands[playerId] = playerCards.map((c) => PlayingCard.cardToString(c)).toList();
        }

        String startingPlayerId = currentState.seats.isNotEmpty ? currentState.seats[0] : '';
        for (final entry in hands.entries) {
           if (entry.value.contains('C3')) {
             startingPlayerId = entry.key;
             break;
           }
        }

        final participants = currentState.seats.map((uid) {
          return BigTwoPlayer(uid: uid, name: 'Player', cards: hands[uid] ?? []);
        }).toList();

        return BigTwoState(
          participants: participants,
          seats: currentState.seats,
          currentPlayerId: startingPlayerId,
        );
      }

      return BigTwoState(
        participants: currentState.participants,
        seats: currentState.seats,
        currentPlayerId: currentState.currentPlayerId,
        lastPlayedHand: currentState.lastPlayedHand,
        lastPlayedById: currentState.lastPlayedById,
        winner: currentState.winner,
        passCount: currentState.passCount,
        restartRequesters: newRequesters,
      );
  }

  BigTwoState _playCards(BigTwoState state, String playerId, List<String> cardsPlayed) {
    // 1. Validate if player has these cards
    final playerIndex = state.participants.indexWhere((p) => p.uid == playerId);
    if (playerIndex == -1) return state;
    final player = state.participants[playerIndex];
    
    // Verify cards are in hand
    for (final card in cardsPlayed) {
      if (!player.cards.contains(card)) {
        // Player trying to play card they don't have
        return state; 
      }
    }

    // 2. Validate move logic (Big Two Rules)
    // This requires a robust Card/Hand validator. 
    // For this implementation, let's implement basic validation:
    // - If it's a new round (passCount >= N-1 or new game), any valid combo allowed.
    // - If not new round, must beat lastPlayedHand.
    
    // Special rule: First hand of game must contain 3 of Clubs if it's the very first turn.
    // We can check this if lastPlayedHand is empty and all players have full hands (13 cards).
    // Or simpler: if it's the player with 3 of Clubs turn and no cards played yet.
    bool isFirstTurn = state.lastPlayedHand.isEmpty && state.lastPlayedById.isEmpty; 
    if (isFirstTurn) {
      if (!cardsPlayed.contains('C3')) {
         return state; // First play must contain 3 of Clubs
      }
    }

    // Checking if this play is valid against last play
    bool isValidPlay = false;
    if (state.passCount >= state.seats.length - 1 || (state.lastPlayedHand.isEmpty && state.lastPlayedById == playerId)) {
       // Player has control (everyone else passed, or it's their free turn)
       isValidPlay = _isValidCombination(cardsPlayed);
    } else {
       // Must beat the previous hand
       isValidPlay = _isBeating(cardsPlayed, state.lastPlayedHand);
    }

    if (!isValidPlay) return state;

    // 3. Execute Play
    // Remove cards from player
    final newCards = List<String>.from(player.cards);
    for (final c in cardsPlayed) newCards.remove(c);

    final newPlayer = BigTwoPlayer(
      uid: player.uid, 
      name: player.name, 
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

    // Calculate next player
    // If winner found, we might still update state but game effectively ends.
    String nextPlayerId = _getNextPlayerId(state.seats, playerId);

    return BigTwoState(
      participants: newParticipants,
      seats: state.seats,
      currentPlayerId: nextPlayerId,
      lastPlayedHand: cardsPlayed,
      lastPlayedById: playerId,
      winner: newWinner,
      passCount: 0, // Reset pass count on valid play
      restartRequesters: state.restartRequesters,
    );
  }

  BigTwoState _passTurn(BigTwoState state, String playerId) {
    // Cannot pass if you have control (i.e. you are the one who played last valid hand and everyone else passed, or start of game)
    // Actually, in Big Two, if everyone passed to you, you MUST play. 
    // If state.lastPlayedById == playerId, you cannot pass.
    if (state.lastPlayedById == playerId) return state;
    if (state.lastPlayedHand.isEmpty && state.lastPlayedById.isEmpty) return state; // Cannot pass on very first turn

    final playerIndex = state.participants.indexWhere((p) => p.uid == playerId);
    if (playerIndex == -1) return state;

    final newParticipants = List<BigTwoPlayer>.from(state.participants);
    newParticipants[playerIndex] = BigTwoPlayer(
        uid: state.participants[playerIndex].uid,
        name: state.participants[playerIndex].name,
        cards: state.participants[playerIndex].cards,
        hasPassed: true
    );

    int newPassCount = state.passCount + 1;
    String nextPlayerId = _getNextPlayerId(state.seats, playerId);

    // If passCount reaches (Players - 1), the next player gains control.
    // They can play anything. We don't clear lastPlayedHand visually, but logic allows any play.
    // We should probably clear lastPlayedById to indicate free turn or set it to next player to indicate they have control?
    // Actually, standard logic: if everyone passes, the person who played the last hand plays again.
    // But what if that person is out of cards? (Winner). Game should have ended.
    
    // If newPassCount >= (state.seats.length - 1), it means everyone else passed.
    // The control returns to the person who played lastPlayedHand.
    // BUT, since we rotate turns, the `nextPlayerId` will eventually be `lastPlayedById`.
    // So we just need to ensure we don't skip them?
    
    // Wait, the standard logic is: A plays. B passes. C passes. D passes. Back to A. A starts new round.
    // So if A played, lastPlayedById is A. 
    // B passes -> next is C.
    // C passes -> next is D.
    // D passes -> next is A. 
    // Now A sees (passCount == 3). A has control.
    
    // So we just increment pass count and move to next player.
    // If next player is the one who played the last hand (lastPlayedById), then passCount should be reset effectively for logic (they have control).
    
    return BigTwoState(
      participants: newParticipants,
      seats: state.seats,
      currentPlayerId: nextPlayerId,
      lastPlayedHand: state.lastPlayedHand,
      lastPlayedById: state.lastPlayedById,
      winner: state.winner,
      passCount: newPassCount,
      restartRequesters: state.restartRequesters,
    );
  }

  String _getNextPlayerId(List<String> seats, String currentId) {
    final idx = seats.indexOf(currentId);
    if (idx == -1) return seats.isNotEmpty ? seats[0] : '';
    return seats[(idx + 1) % seats.length];
  }

  @override
  String getCurrentPlayer(BigTwoState state) {
    return state.currentPlayerId;
  }

  @override
  String? getWinner(BigTwoState state) {
    return state.winner;
  }
  
  // --- Helper Methods for Card Logic ---
  
  bool _isValidCombination(List<String> cards) {
    // Placeholder for complex Big Two logic
    // Needs to detect Singles, Pairs, Triples, Straights, Flushes, Full Houses, Quads, Straight Flushes
    // For now, allow single cards for basic testing
    if (cards.length == 1) return true;
    if (cards.length == 2) {
       // Check pair
       final c1 = PlayingCard.fromString(cards[0]);
       final c2 = PlayingCard.fromString(cards[1]);
       return c1.value == c2.value;
    }
    // ... Implement other combos
    return false; 
  }

  bool _isBeating(List<String> current, List<String> previous) {
    if (current.length != previous.length) return false;
    
    // Simplified comparison logic (only checking singles and pairs by rank)
    // Big Two Rank order: 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K, A, 2
    // Suit order: D < C < H < S (Commonly diamonds, clubs, hearts, spades? No. 
    // Taiwan rule: Club < Diamond < Heart < Spade. 
    // Spec didn't specify variant. Assuming typical: Club < Diamond < Heart < Spade.
    
    if (current.length == 1) {
      return _compareCards(PlayingCard.fromString(current[0]), PlayingCard.fromString(previous[0])) > 0;
    }
    
    if (current.length == 2) {
       final c1 = PlayingCard.fromString(current[0]);
       final c2 = PlayingCard.fromString(current[1]);
       if (c1.value != c2.value) return false; // Not a pair

       final p1 = PlayingCard.fromString(previous[0]);
       final p2 = PlayingCard.fromString(previous[1]); // Assuming prev is valid pair
       
       // Compare pairs: value first, then suit of the spade/highest suit?
       // Usually pair comparison depends on the rank of the pair.
       return _compareRank(c1.value, p1.value) > 0;
    }

    return false;
  }
  
  int _compareCards(PlayingCard a, PlayingCard b) {
    // Compare Rank
    final rankComp = _compareRank(a.value, b.value);
    if (rankComp != 0) return rankComp;
    
    // Compare Suit
    return _suitValue(a.suit).compareTo(_suitValue(b.suit));
  }
  
  int _compareRank(int a, int b) {
    // Map 1(A) -> 14, 2 -> 15 for easier comparison, keeping 3-13 as is.
    int valA = (a == 1) ? 14 : (a == 2 ? 15 : a);
    int valB = (b == 1) ? 14 : (b == 2 ? 15 : b);
    return valA.compareTo(valB);
  }
  
  int _suitValue(CardSuit suit) {
    switch (suit) {
      case CardSuit.clubs: return 1;
      case CardSuit.diamonds: return 2;
      case CardSuit.hearts: return 3;
      case CardSuit.spades: return 4;
    }
  }
}
