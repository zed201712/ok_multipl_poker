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
          BigTwoPlayer(uid: p3, name: 'P3', cards: ['C9', 'D9', 'H9', 'S9', 'C10', 'D10', 'H10', 'S10', 'C2', 'D2']),
          BigTwoPlayer(uid: p4, name: 'P4', cards: ['C10', 'D10', 'H10', 'S10', 'C11', 'D11', 'H11', 'S11', 'C12', 'D12']),
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

      test('returns null for invalid Straight pattern', () {
        expect(delegate.getCardPattern(['D10', 'D11', 'D12', 'D13', 'C1', 'C2']), null);
        expect(delegate.getCardPattern(['D11', 'D12', 'D13', 'C1', 'C2']), null);
        expect(delegate.getCardPattern(['D12', 'D13', 'C1', 'C2', 'C3']), null);
      });

      // Spec 011: Strict Straight Validation
      test('identifies 10-J-Q-K-A as Straight', () {
          // 10, 11, 12, 13, 1
          expect(delegate.getCardPattern(['D10', 'D11', 'D12', 'D13', 'H1']), BigTwoCardPattern.straight);
      });
      test('identifies A-2-3-4-5 as Straight', () {
          // 1, 2, 3, 4, 5
          expect(delegate.getCardPattern(['D1', 'D2', 'D3', 'D4', 'H5']), BigTwoCardPattern.straight);
      });
      test('rejects J-Q-K-A-2 (11,12,13,1,2)', () {
          expect(delegate.getCardPattern(['D11', 'D12', 'D13', 'H1', 'H2']), null);
      });
      test('rejects Q-K-A-2-3 (12,13,1,2,3)', () {
          expect(delegate.getCardPattern(['D12', 'D13', 'H1', 'H2', 'H3']), null);
      });
      test('rejects K-A-2-3-4 (13,1,2,3,4)', () {
          expect(delegate.getCardPattern(['D13', 'H1', 'H2', 'H3', 'H4']), null);
      });
    });

    group('isBeating', () {
      test('Single comparison', () {
        expect(delegate.isBeating(['D3'], ['C3']), true); // Diamond > Club
        expect(delegate.isBeating(['C3'], ['D3']), false);
        expect(delegate.isBeating(['C4'], ['D3']), true);
      });
      test('Pair comparison', () {
        expect(delegate.isBeating(['S3', 'H3'], ['C3', 'D3']), true); // Spades/Hearts > Clubs/Diamonds
        expect(delegate.isBeating(['C4', 'D4'], ['S3', 'H3']), true);
      });
      test('FullHouse comparison (compare triplet)', () {
        // 44433 vs 33344
        expect(delegate.isBeating(['C4', 'D4', 'H4', 'S3', 'C3'], ['C3', 'D3', 'H3', 'S4', 'C4']), true);
      });
      test('FourOfAKind comparison (compare quad)', () {
        // 44443 vs 33334
        expect(delegate.isBeating(['C4', 'D4', 'H4', 'S4', 'C3'], ['C3', 'D3', 'H3', 'S3', 'C4']), true);
      });
      
      // Spec 010: Custom Straight Comparison
      test('Straight comparison: Normal vs Normal', () {
          // 3-4-5-6-7 (7-high) vs 8-9-10-J-Q (Q-high)
          expect(delegate.isBeating(['C8', 'C9', 'C10', 'C11', 'C12'], ['C3', 'C4', 'C5', 'C6', 'C7']), true);
          // Q-high vs 7-high
          expect(delegate.isBeating(['C3', 'C4', 'C5', 'C6', 'C7'], ['C8', 'C9', 'C10', 'C11', 'C12']), false);
      });

      test('Straight comparison: Min (A-2-3-4-5) vs Normal (3-4-5-6-7)', () {
         // A-2-3-4-5 is Level 0 (Min), 3-4-5-6-7 is Level 1 (Normal)
         // So Min should LOSE to Normal, even though 2 > 7 in rank.
         final minStraight = ['D1', 'D2', 'D3', 'D4', 'D5']; // A, 2, 3, 4, 5
         final normalStraight = ['C3', 'C4', 'C5', 'C6', 'C7']; // 7-high

         expect(delegate.isBeating(minStraight, normalStraight), false);
         expect(delegate.isBeating(normalStraight, minStraight), true);
      });

      test('Straight comparison: Min (A-2-3-4-5) vs Max (2-3-4-5-6)', () {
        // A-2-3-4-5 is Level 0 (Min), 3-4-5-6-7 is Level 1 (Normal)
        // So Min should LOSE to Normal, even though 2 > 7 in rank.
        final minStraight = ['D1', 'D2', 'D3', 'D4', 'D5']; // A, 2, 3, 4, 5
        final maxStraight = ['D2', 'D3', 'D4', 'D5', 'D6'];

        expect(delegate.isBeating(minStraight, maxStraight), false);
        expect(delegate.isBeating(maxStraight, minStraight), true);
      });

      // Spec 011: Verify 10-J-Q-K-A is Normal (Level 1)
      test('Straight comparison: Max (2-3-4-5-6) vs 10-J-Q-K-A (Normal)', () {
         // Max > Normal
         final maxStraight = ['D2', 'D3', 'D4', 'D5', 'D6'];
         final normalStraightA = ['D10', 'D11', 'D12', 'D13', 'H1']; // 10, J, Q, K, A

         expect(delegate.isBeating(maxStraight, normalStraightA), true);
         expect(delegate.isBeating(normalStraightA, maxStraight), false);
      });

      test('returns false for invalid Straight pattern C2', () {
        final maxStraight = ['D2', 'D3', 'D4', 'D5', 'D6'];
        final invalidStraight = ['D11', 'D12', 'D13', 'C1', 'C2'];

        expect(delegate.isBeating(maxStraight, invalidStraight), false);
        expect(delegate.isBeating(invalidStraight, maxStraight), false);
      });

      test('returns false for invalid Straight pattern C3', () {
        final maxStraight = ['D2', 'D3', 'D4', 'D5', 'D6'];
        final invalidStraight = ['D12', 'D13', 'C1', 'C2', 'C3'];

        expect(delegate.isBeating(maxStraight, invalidStraight), false);
        expect(delegate.isBeating(invalidStraight, maxStraight), false);
      });
      
      test('Straight comparison: 10-J-Q-K-A (Normal A-high) vs 3-4-5-6-7 (Normal 7-high)', () {
         // Both Normal, compare Rank. A > 7.
         final normalStraightA = ['D10', 'D11', 'D12', 'D13', 'H1'];
         final normalStraight7 = ['C3', 'C4', 'C5', 'C6', 'D7'];

         expect(delegate.isBeating(normalStraightA, normalStraight7), true);
         expect(delegate.isBeating(normalStraight7, normalStraightA), false);
      });

      test('Straight comparison: Max (D2-3-4-5-6) vs Max (C2-3-4-5-6)', () {
        // 2-3-4-5-6 is Level 2 (Max). J-Q-K-A-2 is Level 1 (Normal 2-high).
        // Max > Normal.
        final maxD2Straight = ['D2', 'D3', 'D4', 'D5', 'D6'];
        final maxC2Straight = ['C2', 'C3', 'C4', 'C5', 'C6'];

        expect(delegate.isBeating(maxD2Straight, maxC2Straight), true);
        expect(delegate.isBeating(maxC2Straight, maxD2Straight), false);
      });

      test('Straight comparison: Same Type (Min vs Min) compare suit of 2', () {
          // A-2-3-4-5 (Diamond 2) vs A-2-3-4-5 (Club 2)
          // Diamond > Club
          final minD = ['C1', 'S2', 'C3', 'C4', 'C5']; // Contains S2
          final minC = ['D1', 'C2', 'D3', 'D4', 'D5']; // Contains C2
          
          // Wait, 'S2' (Spade) > 'C2' (Club).
          // My setup above: minD has S2. minC has C2.
          expect(delegate.isBeating(minD, minC), true);
      });

      test('StraightFlush comparison: Min (A-2-3-4-5) vs Normal (3-4-5-6-7)', () {
          // Same logic applies to Straight Flush
          final minSF = ['D1', 'D2', 'D3', 'D4', 'D5'];
          final normalSF = ['C3', 'C4', 'C5', 'C6', 'C7'];
          
          expect(delegate.isBeating(minSF, normalSF), false); // Min < Normal
          expect(delegate.isBeating(normalSF, minSF), true);
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
