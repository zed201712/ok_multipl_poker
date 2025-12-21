import 'package:collection/collection.dart';
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
  
  // --- Checkers and Finders ---

  /// Single
  bool isSingle(List<PlayingCard> cards) => cards.length == 1;

  List<List<PlayingCard>> findSingles(List<PlayingCard> cards) {
     return sortCardsByRank(cards).map((c) => [c]).toList();
  }

  /// Pair
  bool isPair(List<PlayingCard> cards) => cards.length == 2 && cards[0].value == cards[1].value;

  /// Finds all pairs in the given list of cards.
  List<List<PlayingCard>> findPairs(List<PlayingCard> cards) {
    final List<List<PlayingCard>> pairs = [];
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
  
  /// Straight
  /// Checks if cards form a valid straight (5 cards, consecutive ranks).
  /// Considers A=1 or A=14 depending on context, but here we primarily follow Big Two logic or simple consecutive.
  /// 
  /// Supported patterns (Rank order):
  /// A-2-3-4-5 (1,2,3,4,5)
  /// 2-3-4-5-6 (2,3,4,5,6)
  /// ...
  /// 10-J-Q-K-A (10,11,12,13,1)
  /// 
  /// Big Two specific:
  /// 3-4-5-6-7 (Values: 3,4,5,6,7) -> Straight
  /// ...
  /// 10-J-Q-K-A (Values: 10,11,12,13,14) -> Straight (if A is 14)
  /// J-Q-K-A-2 (Values: 11,12,13,14,15) -> Straight (if 2 is 15)
  bool isStraight(List<PlayingCard> cards) {
    if (cards.length != 5) return false;
    
    // Check for standard consecutive ranks (using 1..13)
    // A can be 1 or 14.
    // Let's try to sort by standard value first.
    final values = cards.map((c) => c.value).toList()..sort(); // 1..13
    
    // Case 1: Standard straight (e.g. 3,4,5,6,7 or 1,2,3,4,5)
    bool isStandard = true;
    for (int i = 0; i < values.length - 1; i++) {
      if (values[i + 1] != values[i] + 1) {
        isStandard = false;
        break;
      }
    }
    if (isStandard) return true;
    
    // Case 2: 10-J-Q-K-A (10,11,12,13,1)
    // Sorted values would be 1,10,11,12,13
    if (const ListEquality().equals(values, [1, 10, 11, 12, 13])) return true;
    
    // Case 3: J-Q-K-A-2 (11,12,13,1,2) ?? usually treated differently, 
    // but in Big Two A and 2 are high.
    // If we use Big Two Values (3..15):
    final bigTwoValues = cards.map((c) => getBigTwoValue(c.value)).toList()..sort();
    
    // Check consecutive in Big Two values
    bool isBigTwoConsecutive = true;
    for (int i = 0; i < bigTwoValues.length - 1; i++) {
      if (bigTwoValues[i + 1] != bigTwoValues[i] + 1) {
        isBigTwoConsecutive = false;
        break;
      }
    }
    if (isBigTwoConsecutive) return true;
    
    // 3-4-5-A-2 is sometimes valid in Taiwan Big Two (3,4,5,14,15 sorted).
    // Let's stick to basic ones for now as per spec "simple implementation".
    // 3-4-5-6-7 to 10-J-Q-K-A and A-2-3-4-5, 2-3-4-5-6.
    
    // Case 4: A-2-3-4-5 (Big Two values: 3,4,5,14,15)
    if (const ListEquality().equals(bigTwoValues, [3, 4, 5, 14, 15])) return true;
    
    // Case 5: 2-3-4-5-6 (Big Two values: 3,4,5,6,15)
    if (const ListEquality().equals(bigTwoValues, [3, 4, 5, 6, 15])) return true;

    return false;
  }

  List<List<PlayingCard>> findStraights(List<PlayingCard> cards) {
    if (cards.length < 5) return [];
    
    // Generate all combinations of 5 cards
    // This can be expensive if cards.length is large, but max is 13.
    // 13C5 = 1287, which is fine.
    
    final List<List<PlayingCard>> straights = [];
    final combinations = _combinations(cards, 5);
    
    for (final combo in combinations) {
      if (isStraight(combo)) {
        straights.add(sortCardsByRank(combo));
      }
    }
    
    return straights;
  }

  /// Full House
  bool isFullHouse(List<PlayingCard> cards) {
    if (cards.length != 5) return false;
    final valueCounts = <int, int>{};
    for (final c in cards) {
      valueCounts[c.value] = (valueCounts[c.value] ?? 0) + 1;
    }
    // Must be 3 of one kind and 2 of another
    return valueCounts.containsValue(3) && valueCounts.containsValue(2);
  }

  List<List<PlayingCard>> findFullHouses(List<PlayingCard> cards) {
    if (cards.length < 5) return [];
    final List<List<PlayingCard>> fullHouses = [];
    final combinations = _combinations(cards, 5);
    for (final combo in combinations) {
      if (isFullHouse(combo)) {
        fullHouses.add(sortCardsByRank(combo));
      }
    }
    return fullHouses;
  }

  /// Four of a Kind (鐵支)
  bool isFourOfAKind(List<PlayingCard> cards) {
    if (cards.length != 5) return false;
    final valueCounts = <int, int>{};
    for (final c in cards) {
      valueCounts[c.value] = (valueCounts[c.value] ?? 0) + 1;
    }
    // Must be 4 of one kind (the 5th card can be anything)
    return valueCounts.containsValue(4);
  }

  List<List<PlayingCard>> findFourOfAKinds(List<PlayingCard> cards) {
    if (cards.length < 5) return [];
    final List<List<PlayingCard>> result = [];
    final combinations = _combinations(cards, 5);
    for (final combo in combinations) {
      if (isFourOfAKind(combo)) {
        result.add(sortCardsByRank(combo));
      }
    }
    return result;
  }

  /// Straight Flush
  bool isStraightFlush(List<PlayingCard> cards) {
    if (!isStraight(cards)) return false;
    // Check flush
    final firstSuit = cards[0].suit;
    return cards.every((c) => c.suit == firstSuit);
  }

  List<List<PlayingCard>> findStraightFlushes(List<PlayingCard> cards) {
    if (cards.length < 5) return [];
    final List<List<PlayingCard>> result = [];
    final combinations = _combinations(cards, 5);
    for (final combo in combinations) {
      if (isStraightFlush(combo)) {
        result.add(sortCardsByRank(combo));
      }
    }
    return result;
  }
  
  /// Helper for combinations
  List<List<PlayingCard>> _combinations(List<PlayingCard> list, int k) {
    if (k == 0) return [[]];
    if (list.isEmpty) return [];
    
    final first = list.first;
    final rest = list.sublist(1);
    
    final combosWithFirst = _combinations(rest, k - 1).map((c) => [first, ...c]).toList();
    final combosWithoutFirst = _combinations(rest, k);
    
    return [...combosWithFirst, ...combosWithoutFirst];
  }

  /// 通用選牌邏輯
  List<PlayingCard> getNextPatternSelection({
      required List<PlayingCard> hand,
      required List<PlayingCard> currentSelection,
      required List<List<PlayingCard>> Function(List<PlayingCard>) finder,
  }) {
      final candidates = finder(hand);
      if (candidates.isEmpty) return [];

      final eq = const DeepCollectionEquality.unordered();
      
      // 尋找目前選擇是否在候選名單中
      int currentIndex = -1;
      if (currentSelection.isNotEmpty) {
        currentIndex = candidates.indexWhere((c) => eq.equals(c, currentSelection));
      }

      if (currentIndex == -1) {
        return candidates.first;
      } else {
        return candidates[(currentIndex + 1) % candidates.length];
      }
  }
}
