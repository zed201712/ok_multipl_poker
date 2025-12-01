import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/game_internals/card_suit.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';

void main() {
  group('PlayingCard.createDeck()', () {
    test('should create a deck with 52 cards', () {
      final deck = PlayingCard.createDeck();
      expect(deck.length, 52);
    });

    test('should create a deck with unique cards', () {
      final deck = PlayingCard.createDeck();
      final deckSet = deck.toSet();
      expect(deckSet.length, 52);
    });

    test('should shuffle the deck', () {
      final deck1 = PlayingCard.createDeck();
      final deck2 = PlayingCard.createDeck();
      // This is not a 100% guarantee, but it's very unlikely that two
      // shuffled decks are the same.
      expect(deck1, isNot(equals(deck2)));
    });

    test('should contain all suits and values', () {
      final deck = PlayingCard.createDeck();
      for (final suit in CardSuit.values) {
        for (int value = 1; value <= 13; value++) {
          expect(
              deck.any((card) => card.suit == suit && card.value == value),
              isTrue,
              reason: 'Missing card: $suit$value');
        }
      }
    });
  });
}
