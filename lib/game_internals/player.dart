import 'package:flutter/foundation.dart';

import 'playing_card.dart';

class Player extends ChangeNotifier {
  static const maxCards = 7;

  final List<PlayingCard> hand = List.generate(
    maxCards,
    (index) => PlayingCard.random(),
  );
  final List<PlayingCard> selectedCards = [];

  void removeCard(PlayingCard card) {
    hand.remove(card);
    notifyListeners();
  }

  void toggleCardSelection(PlayingCard card) {
    if (selectedCards.contains(card)) {
      selectedCards.remove(card);
    } else {
      selectedCards.add(card);
    }
    notifyListeners();
  }
}
