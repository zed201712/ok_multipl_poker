import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/game_internals/card_player.dart';
import 'package:ok_multipl_poker/game_internals/card_suit.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';

void main() {
  group('CardPlayer', () {
    test('should initialize with default values', () {
      final player = CardPlayer();
      expect(player.hand, isEmpty);
      expect(player.maxCards, 13);
    });

    test('should initialize with a custom hand', () {
      final initialHand = [
        const PlayingCard(CardSuit.spades, 1),
        const PlayingCard(CardSuit.hearts, 10),
      ];
      final player = CardPlayer(initialHand: initialHand);

      expect(player.hand, initialHand);
    });

    test('should initialize with a custom maxCards value', () {
      final player = CardPlayer(maxCards: 10);
      expect(player.maxCards, 10);
    });

    test('should remove a card from the hand', () {
      final cardToRemove = const PlayingCard(CardSuit.spades, 1);
      final initialHand = [
        cardToRemove,
        const PlayingCard(CardSuit.hearts, 10),
      ];
      final player = CardPlayer(initialHand: initialHand);

      player.removeCard(cardToRemove);

      expect(player.hand, isNot(contains(cardToRemove)));
      expect(player.hand.length, 1);
    });

    test('should notify listeners when a card is removed', () {
      final cardToRemove = const PlayingCard(CardSuit.spades, 1);
      final player = CardPlayer(initialHand: [cardToRemove]);

      bool listenerWasCalled = false;
      player.addListener(() {
        listenerWasCalled = true;
      });

      player.removeCard(cardToRemove);

      expect(listenerWasCalled, isTrue);
    });
  });
}
