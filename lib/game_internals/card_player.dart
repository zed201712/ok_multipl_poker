import 'package:flutter/foundation.dart';
import 'package:ok_multipl_poker/game_internals/player.dart';

import 'playing_card.dart';

/// A class that represents a player in a card game.
///
/// It holds the player's hand and has a maximum number of cards it can hold.
class CardPlayer with ChangeNotifier implements Player {
  /// The maximum number of cards this player can hold.
  final int maxCards;

  String name;

  /// The cards currently in the player's hand.
  @override
  List<PlayingCard> hand;

  final List<PlayingCard> selectedCards = [];

  /// Creates a new card player.
  CardPlayer({String? name, int? maxCards, List<PlayingCard>? initialHand})
      : maxCards = maxCards ?? 13,
        hand = initialHand ?? [],
        name = name ?? "";

  /// Removes a card from the player's hand.
  @override
  void removeCard(PlayingCard card) {
    if (hand.remove(card)) {
      notifyListeners();
    }
  }

  /// Removes all cards from the player's hand.
  void clearHand() {
    hand.clear();
    notifyListeners();
  }

  /// Adds a list of cards to the player's hand.
  void addCards(List<PlayingCard> cards) {
    hand.addAll(cards);
    notifyListeners();
  }

  void replaceWith(List<PlayingCard> cards) {
    hand.clear();
    addCards(cards);
  }

  void toggleCardSelection(PlayingCard card) {
    if (selectedCards.contains(card)) {
      selectedCards.remove(card);
    } else {
      selectedCards.add(card);
    }
    notifyListeners();
  }

  void setCardSelection(List<PlayingCard> cards) {
    selectedCards.clear();
    selectedCards.addAll(cards);
    notifyListeners();
  }
}
