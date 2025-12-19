import 'package:ok_multipl_poker/entities/big_two_player.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/game_internals/card_suit.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';

class BigTwoDelegate extends TurnBasedGameDelegate<BigTwoState> {
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
        int cardIndex = 0;
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

    // Checking if this play is valid against last play
    bool isValidPlay = false;
    
    // Determine if player has control (Free Turn)
    // Control if:
    // 1. It's the very first turn of the game.
    // 2. The player was the last one to play a hand (everyone else passed).
    // 3. Theoretically if passCount >= N-1, but that usually results in lastPlayedById having control.
    //    If lastPlayedById is the current player, they have control.
    
    // Note: In typical Big Two, if everyone passes, the control returns to the last player.
    // Our state updates passCount. If passCount >= seats.length - 1, the next player (which should be the one who played last) gets control.
    // So if state.lastPlayedById == playerId, it is a Free Turn.
    
    bool isFreeTurn = isFirstTurn || (state.lastPlayedById == playerId);

    if (isFreeTurn) {
       isValidPlay = _isValidCombination(cardsPlayed);
    } else {
       // Must beat the previous hand
       isValidPlay = _isBeating(cardsPlayed, state.lastPlayedHand);
    }

    if (!isValidPlay) return state;

    // 3. Execute Play
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
    // Cannot pass if you have control
    if (state.lastPlayedById == playerId) return state;
    if (state.lastPlayedHand.isEmpty && state.lastPlayedById.isEmpty) return state; // Cannot pass on very first turn

    final playerIndex = state.participants.indexWhere((p) => p.uid == playerId);
    if (playerIndex == -1) return state;

    final newParticipants = List<BigTwoPlayer>.from(state.participants);
    // Mark as passed? For now we just track passCount and move on.
    // Optional: Update player state to indicate they passed this round.

    int newPassCount = state.passCount + 1;
    String nextPlayerId = _getNextPlayerId(state.seats, playerId);

    // If everyone else has passed (passCount reaches N-1), the next player gets control (Free Turn).
    // In our logic, 'control' is determined by whether lastPlayedById == currentPlayerId.
    // If passCount == seats.length - 1, it means the next player IS lastPlayedById (assuming standard rotation).
    // Let's verify:
    // P1 plays. 
    // P2 passes (count=1). Next=P3.
    // P3 passes (count=2). Next=P4.
    // P4 passes (count=3). Next=P1.
    // P1 is lastPlayedById. P1 has control.
    // So simply incrementing passCount and rotating is sufficient.
    
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
  
  bool _isValidCombination(List<String> cards) {
    // Basic validation for single cards and pairs for now.
    // Full implementation requires checking for straights, full houses, etc.
    if (cards.isEmpty) return false;
    
    if (cards.length == 1) return true;
    
    if (cards.length == 2) {
       final c1 = PlayingCard.fromString(cards[0]);
       final c2 = PlayingCard.fromString(cards[1]);
       return c1.value == c2.value;
    }
    
    // Placeholder for 5-card hands (Straight, Flush, Full House, Quads, Straight Flush)
    // For this spec implementation, we'll allow 5 cards if we can detect valid types.
    // Simplified: Just reject complex hands for now unless we implement full logic.
    return false; 
  }

  bool _isBeating(List<String> current, List<String> previous) {
    if (current.length != previous.length) return false;
    
    // Simplified comparison logic (only checking singles and pairs by rank)
    // Big Two Rank order: 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K, A, 2
    
    if (current.length == 1) {
      return _compareCards(PlayingCard.fromString(current[0]), PlayingCard.fromString(previous[0])) > 0;
    }
    
    if (current.length == 2) {
       final c1 = PlayingCard.fromString(current[0]);
       final c2 = PlayingCard.fromString(current[1]);
       if (c1.value != c2.value) return false; // Not a pair

       final p1 = PlayingCard.fromString(previous[0]);
       final p2 = PlayingCard.fromString(previous[1]); // Assuming prev is valid pair
       
       return _compareRank(c1.value, p1.value) > 0;
    }

    return false;
  }
  
  int _compareCards(PlayingCard a, PlayingCard b) {
    final rankComp = _compareRank(a.value, b.value);
    if (rankComp != 0) return rankComp;
    return _suitValue(a.suit).compareTo(_suitValue(b.suit));
  }
  
  int _compareRank(int a, int b) {
    // Map 1(A) -> 14, 2 -> 15 for easier comparison, keeping 3-13 as is.
    int valA = (a == 1) ? 14 : (a == 2 ? 15 : a);
    int valB = (b == 1) ? 14 : (b == 2 ? 15 : b);
    return valA.compareTo(valB);
  }
  
  int _suitValue(CardSuit suit) {
    // Taiwan rule: Club < Diamond < Heart < Spade. 
    switch (suit) {
      case CardSuit.clubs: return 1;
      case CardSuit.diamonds: return 2;
      case CardSuit.hearts: return 3;
      case CardSuit.spades: return 4;
    }
  }
}
