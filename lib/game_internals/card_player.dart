import 'package:flutter/foundation.dart';

import 'playing_card.dart';

/// A class that represents a player in a card game.
///
/// It holds the player's hand and has a maximum number of cards it can hold.
class CardPlayer with ChangeNotifier {
  /// The maximum number of cards this player can hold.
  final int maxCards;

  /// The cards currently in the player's hand.
  final List<PlayingCard> hand;

  /// Creates a new card player.
  CardPlayer({int? maxCards, List<PlayingCard>? initialHand}) 
      : maxCards = maxCards ?? 13,
        hand = initialHand ?? [];

  /// Removes a card from the player's hand.
  void removeCard(PlayingCard card) {
    if (hand.remove(card)) {
      notifyListeners();
    }
  }
}
