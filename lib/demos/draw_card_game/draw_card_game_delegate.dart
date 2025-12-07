import 'package:ok_multipl_poker/demos/draw_card_game/draw_card_game_state.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';

class DrawCardGameDelegate extends TurnBasedGameDelegate<DrawCardGameState> {
  List<PlayingCard> _deck = [];

  @override
  DrawCardGameState initializeGame(List<String> playerIds) {
    _deck = PlayingCard.createDeck();
    final playerCards = {for (var id in playerIds) id: null};
    return DrawCardGameState(playerCards: playerCards);
  }

  @override
  DrawCardGameState processAction(
    DrawCardGameState currentState, 
    String action, 
    String playerId, 
    Map<String, dynamic> payload
  ) {
    if (action == 'draw_card') {
      if (currentState.playerCards[playerId] == null && _deck.isNotEmpty) {
        final newCard = _deck.removeLast();
        final newPlayerCards = Map<String, PlayingCard?>.from(currentState.playerCards);
        newPlayerCards[playerId] = newCard;
        return DrawCardGameState(playerCards: newPlayerCards);
      }
    }
    return currentState;
  }
  
  @override
  String getGameStatus(DrawCardGameState state) {
     // If all players have drawn a card, the game is finished.
    if (state.playerCards.values.every((card) => card != null)) {
      return 'finished';
    }
    return 'playing';
  }

  @override
  String? getCurrentPlayer(DrawCardGameState state) {
    // In this game, anyone who hasn't drawn a card can play.
    // We will pick the first one in the list.
    for (final entry in state.playerCards.entries) {
      if (entry.value == null) {
        return entry.key;
      }
    }
    return null; // All players have played
  }

  @override
  String? getWinner(DrawCardGameState state) {
    if (getGameStatus(state) != 'finished') {
      return null;
    }

    String? winnerId;
    PlayingCard? winningCard;

    for (final entry in state.playerCards.entries) {
      final playerId = entry.key;
      final card = entry.value;

      if (card != null) {
        if (winningCard == null || card.value > winningCard.value) {
          winningCard = card;
          winnerId = playerId;
        } else if (card.value == winningCard.value) {
          // In case of a tie in value, compare suits.
          if (card.suit.index > winningCard.suit.index) {
            winningCard = card;
            winnerId = playerId;
          }
        }
      }
    }
    return winnerId;
  }

  @override
  DrawCardGameState stateFromJson(Map<String, dynamic> json) {
    return DrawCardGameState.fromJson(json);
  }

  @override
  Map<String, dynamic> stateToJson(DrawCardGameState state) {
    return state.toJson();
  }
}
