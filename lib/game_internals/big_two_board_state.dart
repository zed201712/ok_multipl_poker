import 'package:flutter/foundation.dart';

import 'card_player.dart';
import 'playing_area.dart';
import 'playing_card.dart';

/// A class that holds the state of a Big Two game board.
///
/// This includes the state of the local player, other players, and the
/// central playing area.
class BigTwoBoardState {
  /// The total number of players in the game.
  final int playerCount;

  /// The state of the player at the bottom of the screen (the local player).
  final CardPlayer player;

  /// The states of the other players in the game.
  final List<CardPlayer> otherPlayers;

  /// The state of the central area where cards are played.
  final PlayingArea centerPlayingArea = PlayingArea();

  BigTwoBoardState({this.playerCount = 4})
      : player = CardPlayer(),
        otherPlayers =
        List.generate(playerCount - 1, (_) => CardPlayer(), growable: false);

  /// Resets the game to its initial state, dealing new cards to all players.
  void restartGame() {
    final deck = PlayingCard.createDeck();

    // Clear all hands and the playing area.
    player.clearHand();
    for (final p in otherPlayers) {
      p.clearHand();
    }
    centerPlayingArea.replaceWith([]);

    // Deal cards.
    final allPlayers = [player, ...otherPlayers];
    final cardsPerPlayer = deck.length ~/ allPlayers.length;

    for (int i = 0; i < allPlayers.length; i++) {
      final p = allPlayers[i];
      final startIndex = i * cardsPerPlayer;
      final endIndex = (i + 1) * cardsPerPlayer;
      p.addCards(deck.sublist(startIndex, endIndex));
    }

    // Add any remaining cards to the center area.
    final remainingCards = deck.length % allPlayers.length;
    if (remainingCards > 0) {
      centerPlayingArea.replaceWith(centerPlayingArea.cards + deck.sublist(deck.length - remainingCards));
    }

    player.addListener(_handlePlayerChange);
  }

  /// 釋放資源。
  void dispose() {
    player.removeListener(_handlePlayerChange);
    centerPlayingArea.dispose();
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
