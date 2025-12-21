import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/game_internals/big_two_deck_utils_mixin.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/game_internals/card_suit.dart';

class MockBigTwoUtils with BigTwoDeckUtilsMixin {}

void main() {
  group('BigTwoDeckUtilsMixin', () {
    final utils = MockBigTwoUtils();

    test('getBigTwoValue converts correctly', () {
      expect(utils.getBigTwoValue(3), 3);
      expect(utils.getBigTwoValue(10), 10);
      expect(utils.getBigTwoValue(13), 13); // K
      expect(utils.getBigTwoValue(1), 14);  // A
      expect(utils.getBigTwoValue(2), 15);  // 2
    });

    test('getSuitValue orders correctly', () {
      expect(utils.getSuitValue(CardSuit.clubs), 1);
      expect(utils.getSuitValue(CardSuit.diamonds), 2);
      expect(utils.getSuitValue(CardSuit.hearts), 3);
      expect(utils.getSuitValue(CardSuit.spades), 4);
    });

    test('sortCardsByRank sorts by Rank (Asc) then Suit (Asc)', () {
      final s3 = PlayingCard(CardSuit.spades, 3);
      final h3 = PlayingCard(CardSuit.hearts, 3);
      final d2 = PlayingCard(CardSuit.diamonds, 2);

      final input = [d2, s3, h3];
      // Expectation:
      // Rank: 3 < 2 (Big Two rules)
      // Suit: Hearts (3) < Spades (4)
      // So order should be: H3, S3, D2
      final sorted = utils.sortCardsByRank(input);

      expect(sorted[0], h3);
      expect(sorted[1], s3);
      expect(sorted[2], d2);
    });
    
    test('sortCardsByRank handles complex list', () {
      final c3 = PlayingCard(CardSuit.clubs, 3);
      final s3 = PlayingCard(CardSuit.spades, 3);
      final h4 = PlayingCard(CardSuit.hearts, 4);
      final d2 = PlayingCard(CardSuit.diamonds, 2);
      
      final input = [d2, s3, c3, h4];
      // Expected Order:
      // Rank 3: C3 (Club 3), S3 (Spade 3) -> Club < Spade
      // Rank 4: H4
      // Rank 2: D2
      // Result: C3, S3, H4, D2
      
      final sorted = utils.sortCardsByRank(input);
      
      expect(sorted, [c3, s3, h4, d2]);
    });

    test('findSingles finds all singles', () {
      final s3 = PlayingCard(CardSuit.spades, 3);
      final h3 = PlayingCard(CardSuit.hearts, 3);
      final singles = utils.findSingles([s3, h3]);
      expect(singles.length, 2);
      expect(singles[0], [h3]); // Sorted by rank: H3 < S3 (same rank, H < S)
      expect(singles[1], [s3]);
    });

    test('findPairs finds all pairs', () {
      final s3 = PlayingCard(CardSuit.spades, 3);
      final h3 = PlayingCard(CardSuit.hearts, 3);
      final d3 = PlayingCard(CardSuit.diamonds, 3);
      
      final input = [s3, h3, d3];
      
      final pairs = utils.findPairs(input);
      
      // Expected pairs: (S3, H3), (S3, D3), (H3, D3)
      // Order depends on loop, but pairs should contain these combos
      expect(pairs.length, 3);
      
      bool containsPair(PlayingCard a, PlayingCard b) {
        return pairs.any((p) => (p[0] == a && p[1] == b) || (p[0] == b && p[1] == a));
      }
      
      expect(containsPair(s3, h3), isTrue);
      expect(containsPair(s3, d3), isTrue);
      expect(containsPair(h3, d3), isTrue);
    });
    
    test('isStraight detects standard straight', () {
      final s3 = PlayingCard(CardSuit.spades, 3);
      final s4 = PlayingCard(CardSuit.spades, 4);
      final s5 = PlayingCard(CardSuit.spades, 5);
      final s6 = PlayingCard(CardSuit.spades, 6);
      final s7 = PlayingCard(CardSuit.spades, 7);
      
      expect(utils.isStraight([s3, s4, s5, s6, s7]), isTrue);
    });

    test('isStraight detects A-2-3-4-5 straight', () {
      // Assuming spec wants A-2-3-4-5 support.
      // Logic in mixin implemented: Case 4: A-2-3-4-5 (Big Two values: 3,4,5,14,15)
      final a = PlayingCard(CardSuit.spades, 1);
      final two = PlayingCard(CardSuit.spades, 2);
      final three = PlayingCard(CardSuit.spades, 3);
      final four = PlayingCard(CardSuit.spades, 4);
      final five = PlayingCard(CardSuit.spades, 5);
      
      expect(utils.isStraight([a, two, three, four, five]), isTrue);
    });

    test('findStraights finds valid straight', () {
      final s3 = PlayingCard(CardSuit.spades, 3);
      final s4 = PlayingCard(CardSuit.spades, 4);
      final s5 = PlayingCard(CardSuit.spades, 5);
      final s6 = PlayingCard(CardSuit.spades, 6);
      final s7 = PlayingCard(CardSuit.spades, 7);
      
      final straights = utils.findStraights([s3, s4, s5, s6, s7]);
      expect(straights.length, 1);
    });

    test('isFullHouse detects full house', () {
      final s3 = PlayingCard(CardSuit.spades, 3);
      final h3 = PlayingCard(CardSuit.hearts, 3);
      final d3 = PlayingCard(CardSuit.diamonds, 3);
      final s4 = PlayingCard(CardSuit.spades, 4);
      final h4 = PlayingCard(CardSuit.hearts, 4);
      
      expect(utils.isFullHouse([s3, h3, d3, s4, h4]), isTrue);
    });

    test('findFullHouses finds full house', () {
      final s3 = PlayingCard(CardSuit.spades, 3);
      final h3 = PlayingCard(CardSuit.hearts, 3);
      final d3 = PlayingCard(CardSuit.diamonds, 3);
      final s4 = PlayingCard(CardSuit.spades, 4);
      final h4 = PlayingCard(CardSuit.hearts, 4);
      
      final fhs = utils.findFullHouses([s3, h3, d3, s4, h4]);
      expect(fhs.length, 1);
    });
    
    test('isStraightFlush detects straight flush', () {
      final s3 = PlayingCard(CardSuit.spades, 3);
      final s4 = PlayingCard(CardSuit.spades, 4);
      final s5 = PlayingCard(CardSuit.spades, 5);
      final s6 = PlayingCard(CardSuit.spades, 6);
      final s7 = PlayingCard(CardSuit.spades, 7);
      
      expect(utils.isStraightFlush([s3, s4, s5, s6, s7]), isTrue);
    });
    
    test('getNextPatternSelection cycles through candidates', () {
       final s3 = PlayingCard(CardSuit.spades, 3);
       final h3 = PlayingCard(CardSuit.hearts, 3);
       final d3 = PlayingCard(CardSuit.diamonds, 3);
       
       final hand = [s3, h3, d3];
       // Pairs: (H3, S3), (H3, D3), (S3, D3)  <- sorted by rank in findPairs
       // Note: findPairs output order in mixin:
       // sortedCards: H3, D3, S3 (wait.. getSuitValue: C=1, D=2, H=3, S=4)
       // D3(2) < H3(3) < S3(4)
       // Sorted: D3, H3, S3
       // Pairs loop:
       // i=0(D3): (D3, H3), (D3, S3)
       // i=1(H3): (H3, S3)
       // Total 3 pairs.
       
       // 1. Initial selection (empty)
       var selection = utils.getNextPatternSelection(
           hand: hand, 
           currentSelection: [], 
           finder: utils.findPairs
       );
       expect(selection, [d3, h3]);
       
       // 2. Next selection
       selection = utils.getNextPatternSelection(
           hand: hand, 
           currentSelection: [d3, h3], 
           finder: utils.findPairs
       );
       expect(selection, [d3, s3]);
       
       // 3. Next selection
       selection = utils.getNextPatternSelection(
           hand: hand, 
           currentSelection: [d3, s3], 
           finder: utils.findPairs
       );
       expect(selection, [h3, s3]);
       
       // 4. Wrap around
       selection = utils.getNextPatternSelection(
           hand: hand, 
           currentSelection: [h3, s3], 
           finder: utils.findPairs
       );
       expect(selection, [d3, h3]);
    });
  });
}
