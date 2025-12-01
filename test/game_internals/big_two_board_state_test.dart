import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/game_internals/big_two_board_state.dart';
import 'package:ok_multipl_poker/game_internals/card_player.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';

void main() {
  group('BigTwoBoardState', () {
    test('should initialize correctly for 4 players', () {
      final state = BigTwoBoardState();

      expect(state.player, isA<CardPlayer>());
      expect(state.otherPlayers.length, 3);
      for (final p in state.otherPlayers) {
        expect(p, isA<CardPlayer>());
      }
      expect(state.centerPlayingArea, isNotNull);
    });

    group('restartGame', () {
      test('should deal 13 cards to each of the 4 players', () {
        final state = BigTwoBoardState();
        state.restartGame();

        expect(state.player.hand.length, 13);
        for (final p in state.otherPlayers) {
          expect(p.hand.length, 13);
        }
      });

      test('should deal a full deck of unique cards', () {
        final state = BigTwoBoardState();
        state.restartGame();

        final allCards = [
          ...state.player.hand,
          ...state.otherPlayers[0].hand,
          ...state.otherPlayers[1].hand,
          ...state.otherPlayers[2].hand,
          ...state.centerPlayingArea.cards,
        ];

        expect(allCards.length, 52);
        expect(allCards.toSet().length, 52, reason: 'Cards should be unique');
      });

      test('should clear previous hands before dealing', () {
        final state = BigTwoBoardState();
        // Give players some cards initially
        state.player.hand = [PlayingCard.random()];
        state.otherPlayers.first.hand = [PlayingCard.random()];
        state.centerPlayingArea.cards = [PlayingCard.random()];

        state.restartGame();

        expect(state.player.hand.length, 13);
        expect(state.otherPlayers.first.hand.length, 13);
        expect(state.centerPlayingArea.cards, isEmpty);
      });

      test('center area should be empty when cards are perfectly divisible', () {
        final state = BigTwoBoardState();
        state.restartGame();

        // For 4 players and a 52-card deck, there are no remaining cards.
        expect(state.centerPlayingArea.cards, isEmpty);
      });

      test('should deal 10 cards to 5 players with 2 remaining', () {
        final state = BigTwoBoardState(playerCount: 5);
        state.restartGame();

        expect(state.player.hand.length, 10, reason: 'Local player should have 10 cards');
        expect(state.otherPlayers.length, 4, reason: 'There should be 4 other players');
        for (final p in state.otherPlayers) {
          expect(p.hand.length, 10, reason: 'Each other player should have 10 cards');
        }

        expect(state.centerPlayingArea.cards.length, 2, reason: 'Center area should have 2 remaining cards');
      });
    });
  });
}
