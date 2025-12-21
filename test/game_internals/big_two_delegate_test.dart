import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/entities/big_two_player.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/game_internals/big_two_delegate.dart';
import 'package:ok_multipl_poker/game_internals/big_two_card_pattern.dart';

void main() {
  group('BigTwoDelegate', () {
    late BigTwoDelegate delegate;
    late BigTwoState initialState;
    const p1 = 'p1';
    const p2 = 'p2';
    const p3 = 'p3';
    const p4 = 'p4';

    setUp(() {
      delegate = BigTwoDelegate();
      initialState = BigTwoState(
        participants: [
          BigTwoPlayer(uid: p1, name: 'P1', cards: ['C3', 'D3', 'H3', 'S3', 'H4', 'H5', 'H6', 'H7', 'C4', 'D4']),
          BigTwoPlayer(uid: p2, name: 'P2', cards: ['C5', 'D5', 'S5', 'C6', 'D6', 'S6', 'C7', 'D7', 'S7', 'C8']),
          BigTwoPlayer(uid: p3, name: 'P3', cards: ['C9', 'D9', 'H9', 'S9', 'CA', 'DA', 'HA', 'SA', 'C2', 'D2']),
          BigTwoPlayer(uid: p4, name: 'P4', cards: ['C10', 'D10', 'H10', 'S10', 'CJ', 'DJ', 'HJ', 'SJ', 'CQ', 'DQ']),
        ],
        seats: [p1, p2, p3, p4],
        currentPlayerId: p1,
      );
    });

    // --- Unit Tests for Public Methods ---

    group('getCardPattern', () {
      test('identifies Single', () {
        expect(delegate.getCardPattern(['C3']), BigTwoCardPattern.single);
      });
      test('identifies Pair', () {
        expect(delegate.getCardPattern(['C3', 'D3']), BigTwoCardPattern.pair);
      });
      test('identifies Straight', () {
        expect(delegate.getCardPattern(['C3', 'D4', 'H5', 'S6', 'C7']), BigTwoCardPattern.straight);
      });
      test('identifies FullHouse', () {
        expect(delegate.getCardPattern(['C3', 'D3', 'H3', 'S4', 'C4']), BigTwoCardPattern.fullHouse);
      });
      test('identifies FourOfAKind', () {
        expect(delegate.getCardPattern(['C3', 'D3', 'H3', 'S3', 'C4']), BigTwoCardPattern.fourOfAKind);
      });
      test('identifies StraightFlush', () {
        expect(delegate.getCardPattern(['C3', 'C4', 'C5', 'C6', 'C7']), BigTwoCardPattern.straightFlush);
      });
      test('returns null for invalid pattern', () {
        expect(delegate.getCardPattern(['C3', 'D4']), null); // Random 2 cards
        expect(delegate.getCardPattern(['C3', 'D3', 'H3']), null); // Triplet not valid in Big Two usually
      });
    });

    group('isBeating', () {
      test('Single comparison', () {
        expect(delegate.isBeating(['D3'], ['C3'], BigTwoCardPattern.single), true); // Diamond > Club
        expect(delegate.isBeating(['C3'], ['D3'], BigTwoCardPattern.single), false);
        expect(delegate.isBeating(['C4'], ['D3'], BigTwoCardPattern.single), true);
      });
      test('Pair comparison', () {
        expect(delegate.isBeating(['S3', 'H3'], ['C3', 'D3'], BigTwoCardPattern.pair), true); // Spades/Hearts > Clubs/Diamonds
        expect(delegate.isBeating(['C4', 'D4'], ['S3', 'H3'], BigTwoCardPattern.pair), true);
      });
      test('FullHouse comparison (compare triplet)', () {
        // 44433 vs 33344
        expect(delegate.isBeating(['C4', 'D4', 'H4', 'S3', 'C3'], ['C3', 'D3', 'H3', 'S4', 'C4'], BigTwoCardPattern.fullHouse), true);
      });
      test('FourOfAKind comparison (compare quad)', () {
        // 44443 vs 33334
        expect(delegate.isBeating(['C4', 'D4', 'H4', 'S4', 'C3'], ['C3', 'D3', 'H3', 'S3', 'C4'], BigTwoCardPattern.fourOfAKind), true);
      });
    });

    group('checkPlayValidity', () {
      test('allows any valid pattern on free turn', () {
        final state = initialState.copyWith(lockedHandType: '');
        expect(delegate.checkPlayValidity(state, ['C3'], BigTwoCardPattern.single), true);
        expect(delegate.checkPlayValidity(state, ['C3', 'D3'], BigTwoCardPattern.pair), true);
      });

      test('requires matching pattern on normal turn', () {
        final state = initialState.copyWith(
          lockedHandType: BigTwoCardPattern.single.toJson(),
          lastPlayedHand: ['C3']
        );
        expect(delegate.checkPlayValidity(state, ['C3', 'D3'], BigTwoCardPattern.pair), false);
        expect(delegate.checkPlayValidity(state, ['D3'], BigTwoCardPattern.single), true);
      });

      test('requires beating previous hand', () {
        final state = initialState.copyWith(
            lockedHandType: BigTwoCardPattern.single.toJson(),
            lastPlayedHand: ['D3']
        );
        expect(delegate.checkPlayValidity(state, ['C3'], BigTwoCardPattern.single), false); // C3 < D3
        expect(delegate.checkPlayValidity(state, ['H3'], BigTwoCardPattern.single), true); // H3 > D3
      });
    });

    // --- Integration Tests (processAction) ---

    test('should allow playing a valid single card', () {
      final state = delegate.processAction(initialState, 'play_cards', p1, {'cards': ['C3']});
      
      expect(state.lastPlayedHand, ['C3']);
      expect(state.lastPlayedById, p1);
      expect(state.currentPlayerId, p2);
      expect(state.lockedHandType, BigTwoCardPattern.single.toJson());
      expect(state.participants[0].cards.contains('C3'), false);
    });

    test('should update lockedHandType correctly', () {
      final state = delegate.processAction(initialState, 'play_cards', p1, {'cards': ['C3']});
      expect(state.lockedHandType, BigTwoCardPattern.single.toJson());
    });

    test('should allow playing a valid pair', () {
      final state = delegate.processAction(initialState, 'play_cards', p1, {'cards': ['C3', 'D3']});
      
      expect(state.lastPlayedHand, unorderedEquals(['C3', 'D3']));
      expect(state.lockedHandType, BigTwoCardPattern.pair.toJson());
      expect(state.currentPlayerId, p2);
    });

    test('should validate turn logic: must beat last played hand', () {
      var state = delegate.processAction(initialState, 'play_cards', p1, {'cards': ['C3']});
      
      state = delegate.processAction(state, 'play_cards', p2, {'cards': ['C5']});
      expect(state.lastPlayedById, p2);
      expect(state.lastPlayedHand, ['C5']);

      state = delegate.processAction(state, 'play_cards', p3, {'cards': ['C2']});
      expect(state.lastPlayedById, p3);

      final oldState = state;
      state = delegate.processAction(state, 'play_cards', p4, {'cards': ['C10']});
      expect(state, oldState);
    });

    test('should validate turn logic: must match pattern', () {
      var state = delegate.processAction(initialState, 'play_cards', p1, {'cards': ['C3', 'D3']});
      
      final oldState = state;
      state = delegate.processAction(state, 'play_cards', p2, {'cards': ['C5']});
      expect(state, oldState);
      
      state = delegate.processAction(state, 'play_cards', p2, {'cards': ['C5', 'D5']});
      expect(state.lastPlayedById, p2);
      expect(state.lastPlayedHand, unorderedEquals(['C5', 'D5']));
    });

    test('bomb logic: Four of a Kind beats Straight', () {
      // Create a full copy of participants to avoid index out of bounds ifseats mismatch
      final newParticipants = List<BigTwoPlayer>.from(initialState.participants);
      // Give P1 a straight
      newParticipants[0] = newParticipants[0].copyWith(cards: ['C2', 'C3', 'D4', 'H5', 'S6', 'C7']);
      // Give P2 a Quad
      newParticipants[1] = newParticipants[1].copyWith(cards: ['C8', 'D8', 'H8', 'S8', 'C9', 'C10']);

      final s0 = initialState.copyWith(
        participants: newParticipants
      );
      
      var state = delegate.processAction(s0, 'play_cards', p1, {'cards': ['C3', 'D4', 'H5', 'S6', 'C7']});
      expect(state.lockedHandType, BigTwoCardPattern.straight.toJson());
      print("p1[$p1], p2[$p2], lastPlayedById: ${state.lastPlayedById}, lockedHandType: ${state.lockedHandType}");
      expect(state.lastPlayedById, p1);
      
      // P2 bombs with Quads 8s.
      state = delegate.processAction(state, 'play_cards', p2, {'cards': ['C8', 'D8', 'H8', 'S8', 'C9']});

      print("p1[$p1], p2[$p2], lastPlayedById: ${state.lastPlayedById}, lockedHandType: ${state.lockedHandType}");
      expect(state.lastPlayedById, p2);
      expect(state.lockedHandType, BigTwoCardPattern.fourOfAKind.toJson());
    });

    test('bomb logic: Straight Flush beats Four of a Kind', () {
      final newParticipants = List<BigTwoPlayer>.from(initialState.participants);
      // Give P1 a Quad
      newParticipants[0] = newParticipants[0].copyWith(cards: ['C2', 'C3', 'D3', 'H3', 'S3', 'C4']);
      // Give P2 a SF
      newParticipants[1] = newParticipants[1].copyWith(cards: ['C5', 'C6', 'C7', 'C8', 'C9', 'C10']);

      final s0 = initialState.copyWith(
        participants: newParticipants
      );

      var state = delegate.processAction(s0, 'play_cards', p1, {'cards': ['C3', 'D3', 'H3', 'S3', 'C4']});
      expect(state.lockedHandType, BigTwoCardPattern.fourOfAKind.toJson());
      expect(state.lastPlayedById, p1);

      // P2 bombs with SF
      state = delegate.processAction(state, 'play_cards', p2, {'cards': ['C5', 'C6', 'C7', 'C8', 'C9']});
      expect(state.lastPlayedById, p2);
      expect(state.lockedHandType, BigTwoCardPattern.straightFlush.toJson());
    });
    
    test('bomb logic: Four of a Kind beats smaller Four of a Kind', () {
       final newParticipants = List<BigTwoPlayer>.from(initialState.participants);
       // Give P1 a Quad
       newParticipants[0] = newParticipants[0].copyWith(cards: ['C2', 'C3', 'D3', 'H3', 'S3', 'C4']);
       // Give P2 a Quad
       newParticipants[1] = newParticipants[1].copyWith(cards: ['C5', 'D5', 'H5', 'S5', 'C6', 'C10']);

       final s0 = initialState.copyWith(
        participants: newParticipants
       );
      var state = delegate.processAction(s0, 'play_cards', p1, {'cards': ['C3', 'D3', 'H3', 'S3', 'C4']});
      
      state = delegate.processAction(state, 'play_cards', p2, {'cards': ['C5', 'D5', 'H5', 'S5', 'C6']});
      expect(state.lastPlayedById, p2);
    });

    test('round reset: lastPlayedHand should be empty after round over', () {
      var state = delegate.processAction(initialState, 'play_cards', p1, {'cards': ['C3']});
      
      state = delegate.processAction(state, 'pass_turn', p2, {});
      state = delegate.processAction(state, 'pass_turn', p3, {});
      state = delegate.processAction(state, 'pass_turn', p4, {});
      
      expect(state.currentPlayerId, p1);
      expect(state.lockedHandType, '');
      expect(state.lastPlayedHand, isEmpty); 
      expect(state.passCount, 0);
    });

  });
}
