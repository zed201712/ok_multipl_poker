import 'package:collection/collection.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/game_internals/card_suit.dart';

import '../entities/big_two_player.dart';
import 'big_two_card_pattern.dart';

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

    return _validateStrictStraightRange(cards);
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
  List<PlayingCard> _getNextPatternSelection({
    BigTwoState? bigTwoState,
    required List<PlayingCard> hand,
      required List<PlayingCard> currentSelection,
      required List<List<PlayingCard>> Function(List<PlayingCard>) finder,
  }) {
      final foundCandidates = finder(hand);
      if (foundCandidates.isEmpty) return [];

      final List<List<PlayingCard>> candidates;
      if (bigTwoState != null) {
        candidates = foundCandidates.where((e)=>checkPlayValidity(bigTwoState, e)).toList();
      }
      else {
        candidates = foundCandidates;
      }

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

  /// Validates if the straight is strictly consecutive in the defined cycle:
  /// A, 2, 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K, A.
  /// Valid straights: A-2-3-4-5, 2-3-4-5-6, ... , 10-J-Q-K-A.
  /// Invalid examples: J-Q-K-A-2, Q-K-A-2-3, K-A-2-3-4.
  bool _validateStrictStraightRange(List<PlayingCard> cards) {
    final values = cards.map((c) => c.value).toSet();
    if (values.length != 5) return false;

    // Check A-2-3-4-5
    if (values.containsAll([1, 2, 3, 4, 5])) return true;

    // Check 2-3-4-5-6
    if (values.containsAll([2, 3, 4, 5, 6])) return true;

    // Check normal straights (3-4-5-6-7 to 9-10-J-Q-K)
    // And 10-J-Q-K-A

    // We can just sort by standard value (1..13) and check consecutiveness
    // BUT we need to handle 10-J-Q-K-A which wraps 13 -> 1.
    // 10-J-Q-K-A sorted values: 1, 10, 11, 12, 13

    final sortedVals = values.toList()..sort();

    // Case: 10-J-Q-K-A
    if (const ListEquality().equals(sortedVals, [1, 10, 11, 12, 13])) return true;

    // For other cases, must be consecutive
    for (int i = 0; i < sortedVals.length - 1; i++) {
      if (sortedVals[i + 1] != sortedVals[i] + 1) {
        return false;
      }
    }

    return true;
  }

  /// 封裝後的選牌邏輯，接收 Enum
  List<PlayingCard> selectNextPattern({
    BigTwoState? bigTwoState,
    required List<PlayingCard> hand,
    required List<PlayingCard> currentSelection,
    required BigTwoCardPattern pattern,
  }) {
    List<List<PlayingCard>> Function(List<PlayingCard>)? finder;
    switch (pattern) {
      case BigTwoCardPattern.single:
        finder = findSingles;
        break;
      case BigTwoCardPattern.pair:
        finder = findPairs;
        break;
      case BigTwoCardPattern.straight:
        finder = findStraights;
        break;
      case BigTwoCardPattern.fullHouse:
        finder = findFullHouses;
        break;
      case BigTwoCardPattern.fourOfAKind:
        finder = findFourOfAKinds;
        break;
      case BigTwoCardPattern.straightFlush:
        finder = findStraightFlushes;
        break;
    }


    // 呼叫 Mixin 的方法
    // 注意：mixin 的 getNextPatternSelection 需要 finder 參數為 required，且不能為 null。
    if (finder == null) return [];

    final nextSelectionCards = _getNextPatternSelection(
      bigTwoState: bigTwoState,
      hand: hand,
      currentSelection: currentSelection,
      finder: finder,
    );

    // 轉回 List<String>
    return nextSelectionCards;
  }

  // --- Helper Methods for Card Logic ---

  /// Identifies the pattern of the played cards.
  BigTwoCardPattern? getCardPattern(List<PlayingCard> cards) {

    if (isSingle(cards)) return BigTwoCardPattern.single;
    if (isPair(cards)) return BigTwoCardPattern.pair;

    if (cards.length == 5) {
      if (isStraightFlush(cards)) return BigTwoCardPattern.straightFlush;
      if (isFourOfAKind(cards)) return BigTwoCardPattern.fourOfAKind;
      if (isFullHouse(cards)) return BigTwoCardPattern.fullHouse;
      if (isStraight(cards)) return BigTwoCardPattern.straight;
    }

    return null;
  }

  bool validateFirstPlay(BigTwoState state, List<PlayingCard> cardsPlayed) {
    if (!state.isFirstTurn) return true;

    // Find the required lowest card
    final lowestCard = findLowestHumanCard(state.participants);

    if (!cardsPlayed.contains(lowestCard)) {
      return false; // First play must contain the lowest human card
    }
    return true;
  }

  /// Finds non-virtual player's lowest card
  PlayingCard findLowestHumanCard(List<BigTwoPlayer> players) {
    PlayingCard? lowestCard;
    PlayingCard c3 = PlayingCard(CardSuit.clubs, 3);

    for (final player in players) {
      if (player.isVirtualPlayer) continue;

      final hand = player.cards.toPlayingCards();
      if (hand.isEmpty) continue;

      final sortedHand = sortCardsByRank(hand);
      final playerLowest = sortedHand.first;

      if (lowestCard == null) {
        lowestCard = playerLowest;
        if (c3 == lowestCard) return c3;
      } else {
        if (_compareCards(playerLowest, lowestCard) < 0) {
          lowestCard = playerLowest;
          if (c3 == lowestCard) return c3;
        }
      }
    }
    return lowestCard ?? c3;
  }

  /// Checks if the played cards are valid against the current state logic.
  bool checkPlayValidity(BigTwoState state, List<PlayingCard> cardsPlayed, {BigTwoCardPattern? playedPattern}) {
    final checkedCardPattern = playedPattern ?? getCardPattern(cardsPlayed);
    if (checkedCardPattern == null) return false;

    if (state.isFirstTurn) {
      final lowerCard = findLowestHumanCard(state.participants);
      return cardsPlayed.contains(lowerCard);
    }

    if (state.lockedHandType.isEmpty) {
      // Free turn: Any valid pattern is allowed
      return true;
    }
    final lastPlayedCards = state.lastPlayedHand.toPlayingCards();

    final lockedPattern = BigTwoCardPattern.fromJson(state.lockedHandType);

    // Special Bomb/Beat Rules
    // 1. Straight Flush beats anything except higher Straight Flush
    if (checkedCardPattern == BigTwoCardPattern.straightFlush) {
      if (lockedPattern != BigTwoCardPattern.straightFlush) {
        return true; // Bomb!
      }
      // Compare two Straight Flushes
      return isBeating(cardsPlayed, lastPlayedCards);
    }

    // 2. Four of a Kind beats anything except Straight Flush and higher Four of a Kind
    if (checkedCardPattern == BigTwoCardPattern.fourOfAKind) {
      if (lockedPattern == BigTwoCardPattern.straightFlush) {
        return false; // Can't beat SF
      }
      if (lockedPattern != BigTwoCardPattern.fourOfAKind) {
        return true; // Bomb! (Beats Straight, FullHouse, etc.)
      }
      // Compare two Four of a Kinds
      return isBeating(cardsPlayed, lastPlayedCards);
    }

    // Standard Rule: Must match pattern
    if (checkedCardPattern != lockedPattern) {
      return false;
    }

    // Compare same pattern
    return isBeating(cardsPlayed, lastPlayedCards);
  }

  /// Compares if [current] beats [previous]. Assumes both are of [pattern] or logic handled before.
  bool isBeating(List<PlayingCard> currentStr, List<PlayingCard> previousStr) {
    if (currentStr.length != previousStr.length) return false;
    final currentPattern = getCardPattern(currentStr);
    final previousPattern = getCardPattern(previousStr);

    if (currentPattern == null || previousPattern == null) return false;

    if (currentPattern == previousPattern) {
      return _beatsSamePattern(currentStr, previousStr, currentPattern);
    }
    else if (currentPattern == BigTwoCardPattern.straightFlush &&
        previousPattern != BigTwoCardPattern.straightFlush
    ) {
      return true;
    }
    else if (currentPattern == BigTwoCardPattern.fourOfAKind &&
        previousPattern != BigTwoCardPattern.straightFlush &&
        previousPattern != BigTwoCardPattern.fourOfAKind
    ) {
      return true;
    }

    return false;
  }

  /// Compares if [current] beats [previous]. Assumes both are of [pattern] or logic handled before.
  bool _beatsSamePattern(List<PlayingCard> currentCards, List<PlayingCard> previousCards, BigTwoCardPattern pattern) {
    if (currentCards.length != previousCards.length) return false;

    switch (pattern) {
      case BigTwoCardPattern.single:
        return _compareCards(currentCards[0], previousCards[0]) > 0;
      case BigTwoCardPattern.pair:
        final cMax = sortCardsByRank(currentCards).last;
        final pMax = sortCardsByRank(previousCards).last;
        return _compareCards(cMax, pMax) > 0;

      case BigTwoCardPattern.straight:
      case BigTwoCardPattern.straightFlush:
        final cLevel = _getStraightLevel(currentCards);
        final pLevel = _getStraightLevel(previousCards);

        if (cLevel != pLevel) {
          return cLevel > pLevel;
        }

        final cRank = _getStraightRankCard(currentCards);
        final pRank = _getStraightRankCard(previousCards);
        return _compareCards(cRank, pRank) > 0;

      case BigTwoCardPattern.fullHouse:
        final cTrip = _getTripletRank(currentCards);
        final pTrip = _getTripletRank(previousCards);
        return getBigTwoValue(cTrip) > getBigTwoValue(pTrip);

      case BigTwoCardPattern.fourOfAKind:
        final cQuad = _getQuadRank(currentCards);
        final pQuad = _getQuadRank(previousCards);
        return getBigTwoValue(cQuad) > getBigTwoValue(pQuad);
    }
  }

  int _getStraightLevel(List<PlayingCard> cards) {
    if (_is23456(cards)) return 2; // Max
    if (_isA2345(cards)) return 0; // Min
    return 1; // Normal
  }

  bool _isA2345(List<PlayingCard> cards) {
    final values = cards.map((c) => c.value).toSet();
    return values.containsAll([1, 2, 3, 4, 5]);
  }

  bool _is23456(List<PlayingCard> cards) {
    final values = cards.map((c) => c.value).toSet();
    return values.containsAll([2, 3, 4, 5, 6]);
  }

  int _compareCards(PlayingCard a, PlayingCard b) {
    final rankComp = getBigTwoValue(a.value).compareTo(getBigTwoValue(b.value));
    if (rankComp != 0) return rankComp;
    return getSuitValue(a.suit).compareTo(getSuitValue(b.suit));
  }

  /// Returns the card that determines the value of the straight.
  PlayingCard _getStraightRankCard(List<PlayingCard> cards) {
    final sorted = sortCardsByRank(cards);
    return sorted.last;
  }

  /// Returns the rank value of the triplet in a Full House.
  int _getTripletRank(List<PlayingCard> cards) {
    final valueCounts = <int, int>{};
    for (final c in cards) {
      valueCounts[c.value] = (valueCounts[c.value] ?? 0) + 1;
    }
    // Safety check, though should be validated by isFullHouse
    if (valueCounts.isEmpty) return 0;
    return valueCounts.entries.firstWhere((e) => e.value == 3, orElse: () => valueCounts.entries.first).key;
  }

  /// Returns the rank value of the four in Four of a Kind.
  int _getQuadRank(List<PlayingCard> cards) {
    final valueCounts = <int, int>{};
    for (final c in cards) {
      valueCounts[c.value] = (valueCounts[c.value] ?? 0) + 1;
    }
    if (valueCounts.isEmpty) return 0;
    return valueCounts.entries.firstWhere((e) => e.value == 4, orElse: () => valueCounts.entries.first).key;
  }

}
