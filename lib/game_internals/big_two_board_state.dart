import 'package:flutter/foundation.dart';
import 'package:ok_multipl_poker/game_internals/card_board_state.dart';

import 'card_player.dart';
import 'playing_card.dart';

/// A class that holds the state of a Big Two game board.
///
/// This includes the state of the local player, other players, and the
/// central playing area.
class BigTwoBoardState implements CardBoardState {
  /// The total number of players in the game.
  final int playerCount;

  final centerAreaIndex;

  @override
  final localPlayerIndex;

  @override
  // TODO: implement onWin
  VoidCallback get onWin => throw UnimplementedError();

  /// The state of the player at the bottom of the screen (the local player).
  @override
  CardPlayer get player => allPlayers[localPlayerIndex];

  CardPlayer get centerPlayingArea => allPlayers[centerAreaIndex];

  /// The states of the other players in the game.
  @override
  final List<CardPlayer> allPlayers;

  BigTwoBoardState({required this.playerCount, required this.allPlayers, required this.localPlayerIndex})
      : centerAreaIndex = playerCount;

  /// Resets the game to its initial state, dealing new cards to all players.
  void restartGame() {
    final deck = PlayingCard.createDeck();

    // Clear all hands and the playing area.
    for (final p in allPlayers) {
      p.clearHand();
    }

    // Deal cards.
    final cardsPerPlayer = deck.length ~/ playerCount;

    for (int i = 0; i < playerCount; i++) {
      final p = allPlayers[i];
      final startIndex = i * cardsPerPlayer;
      final endIndex = (i + 1) * cardsPerPlayer;
      p.addCards(deck.sublist(startIndex, endIndex));
    }

    // Add any remaining cards to the center area.
    final remainingCards = deck.length % playerCount;
    if (remainingCards > 0) {
      centerPlayingArea.replaceWith(deck.sublist(deck.length - remainingCards));
    }

    player.addListener(_handlePlayerChange);
  }

  /// 釋放資源。
  @override
  void dispose() {
    player.removeListener(_handlePlayerChange);
  }

  /// 處理玩家狀態的變更。
  ///
  /// 當玩家手牌為空時，觸發 `onWin` 回呼。
  void _handlePlayerChange() {
    if (player.hand.isEmpty) {
      //onWin();
    }
  }
}
