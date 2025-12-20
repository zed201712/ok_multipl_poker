import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/game_internals/card_suit.dart';

mixin BigTwoDeckUtilsMixin {
  /// 1 (Ace) -> 14, 2 -> 15, others keep value
  int getBigTwoValue(int value) {
    if (value == 1) return 14;
    if (value == 2) return 15;
    return value;
  }

  /// Spades > Hearts > Diamonds > Clubs
  int getSuitValue(CardSuit suit) {
    switch (suit) {
      case CardSuit.spades:
        return 4;
      case CardSuit.hearts:
        return 3;
      case CardSuit.diamonds:
        return 2;
      case CardSuit.clubs:
        return 1;
    }
  }

  /// Sorts cards first by Rank (3..2), then by Suit (Spades..Clubs).
  List<PlayingCard> sortCardsByRank(List<PlayingCard> cards) {
    // Note: List.from creates a shallow copy, ensuring we don't mutate the original list if we don't want to.
    // ..sort sorts it in place.
    return List<PlayingCard>.from(cards)
      ..sort((a, b) {
        int rankComp = getBigTwoValue(a.value).compareTo(getBigTwoValue(b.value));
        if (rankComp != 0) return rankComp;
        return getSuitValue(a.suit).compareTo(getSuitValue(b.suit));
      });
  }

  /// Sorts cards first by Suit (Spades..Clubs), then by Rank (3..2).
  List<PlayingCard> sortCardsBySuit(List<PlayingCard> cards) {
    return List<PlayingCard>.from(cards)
      ..sort((a, b) {
        int suitComp = getSuitValue(a.suit).compareTo(getSuitValue(b.suit));
        if (suitComp != 0) return suitComp;
        return getBigTwoValue(a.value).compareTo(getBigTwoValue(b.value));
      });
  }

  /// Finds all pairs in the given list of cards.
  /// A pair is defined as two cards with the same value (rank).
  List<List<PlayingCard>> findPairs(List<PlayingCard> cards) {
    final List<List<PlayingCard>> pairs = [];
    // To ensure deterministic order, let's sort by rank first
    final sortedCards = sortCardsByRank(cards);
    
    for (int i = 0; i < sortedCards.length; i++) {
      for (int j = i + 1; j < sortedCards.length; j++) {
        if (sortedCards[i].value == sortedCards[j].value) {
          pairs.add([sortedCards[i], sortedCards[j]]);
        }
      }
    }
    return pairs;
  }
}
