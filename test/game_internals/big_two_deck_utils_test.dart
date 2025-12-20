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

    test('sortCardsBySuit sorts by Suit (Asc) then Rank (Asc)', () {
      final c3 = PlayingCard(CardSuit.clubs, 3);
      final s3 = PlayingCard(CardSuit.spades, 3);
      
      final input = [c3, s3];
      // Clubs (1) < Spades (4)
      final sorted = utils.sortCardsBySuit(input);
      expect(sorted, [c3, s3]);
    });
    
    test('sortCardsBySuit handles complex list', () {
      final c3 = PlayingCard(CardSuit.clubs, 3);
      final c4 = PlayingCard(CardSuit.clubs, 4);
      final s3 = PlayingCard(CardSuit.spades, 3);
      
      final input = [s3, c4, c3];
      // Order: 
      // Clubs: C3, C4 (Rank 3 < 4)
      // Spades: S3
      // Result: C3, C4, S3
      
      final sorted = utils.sortCardsBySuit(input);
      
      expect(sorted, [c3, c4, s3]);
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
      
      // Helper to check containment
      bool containsPair(PlayingCard a, PlayingCard b) {
        return pairs.any((p) => (p[0] == a && p[1] == b) || (p[0] == b && p[1] == a));
      }
      
      expect(containsPair(s3, h3), isTrue);
      expect(containsPair(s3, d3), isTrue);
      expect(containsPair(h3, d3), isTrue);
    });
    
    test('findPairs returns empty if no pairs', () {
      final s3 = PlayingCard(CardSuit.spades, 3);
      final h4 = PlayingCard(CardSuit.hearts, 4);
      
      final pairs = utils.findPairs([s3, h4]);
      expect(pairs, isEmpty);
    });
  });
}
