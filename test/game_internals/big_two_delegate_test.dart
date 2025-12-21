import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/entities/big_two_player.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/game_internals/big_two_delegate.dart';
import 'package:ok_multipl_poker/game_internals/big_two_card_pattern.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';

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
      // Must start with C3 or be free turn. Let's assume free turn after C3 played.
      // But C3 is in hand, so first turn must include C3.
      // To test pair, we play Pair of 3s (C3, D3)
      final state = delegate.processAction(initialState, 'play_cards', p1, {'cards': ['C3', 'D3']});
      
      expect(state.lastPlayedHand, unorderedEquals(['C3', 'D3']));
      expect(state.lockedHandType, BigTwoCardPattern.pair.toJson());
      expect(state.currentPlayerId, p2);
    });

    test('should validate turn logic: must beat last played hand', () {
      // P1 plays C3
      var state = delegate.processAction(initialState, 'play_cards', p1, {'cards': ['C3']});
      
      // P2 tries to play C2 (beats C3) -> OK (Wait, C2 > C3? Yes in Big Two)
      // P2 has C5. Let's play C5 (beats C3)
      state = delegate.processAction(state, 'play_cards', p2, {'cards': ['C5']});
      expect(state.lastPlayedById, p2);
      expect(state.lastPlayedHand, ['C5']);

      // P3 plays C2 (beats C5)
      state = delegate.processAction(state, 'play_cards', p3, {'cards': ['C2']});
      expect(state.lastPlayedById, p3);

      // P4 tries to play C10 (smaller than C2) -> Fail, state unchanged
      final oldState = state;
      state = delegate.processAction(state, 'play_cards', p4, {'cards': ['C10']});
      expect(state, oldState);
    });

    test('should validate turn logic: must match pattern', () {
      // P1 plays pair 3s
      var state = delegate.processAction(initialState, 'play_cards', p1, {'cards': ['C3', 'D3']});
      
      // P2 tries to play single C5 -> Fail
      final oldState = state;
      state = delegate.processAction(state, 'play_cards', p2, {'cards': ['C5']});
      expect(state, oldState);
      
      // P2 plays pair 5s -> Success
      state = delegate.processAction(state, 'play_cards', p2, {'cards': ['C5', 'D5']});
      expect(state.lastPlayedById, p2);
      expect(state.lastPlayedHand, unorderedEquals(['C5', 'D5']));
    });

    test('bomb logic: Four of a Kind beats Straight', () {
      // Setup: P1 plays Straight 3-4-5-6-7
      final s0 = initialState.copyWith(
        participants: [
           initialState.participants[0].copyWith(cards: ['C3', 'D4', 'H5', 'S6', 'C7']),
           initialState.participants[1].copyWith(cards: ['C8', 'D8', 'H8', 'S8', 'C9']), // P2 has Quads
        ]
      );
      
      var state = delegate.processAction(s0, 'play_cards', p1, {'cards': ['C3', 'D4', 'H5', 'S6', 'C7']});
      expect(state.lockedHandType, BigTwoCardPattern.straight.toJson());
      
      // P2 bombs with Quads 8s
      state = delegate.processAction(state, 'play_cards', p2, {'cards': ['C8', 'D8', 'H8', 'S8', 'C9']});
      
      expect(state.lastPlayedById, p2);
      expect(state.lockedHandType, BigTwoCardPattern.fourOfAKind.toJson());
    });

    test('bomb logic: Straight Flush beats Four of a Kind', () {
      // Setup: P1 plays Quads
      final s0 = initialState.copyWith(
        participants: [
           initialState.participants[0].copyWith(cards: ['C3', 'D3', 'H3', 'S3', 'C4']), // Quads 3
           initialState.participants[1].copyWith(cards: ['C5', 'C6', 'C7', 'C8', 'C9']), // SF
        ]
      );

      var state = delegate.processAction(s0, 'play_cards', p1, {'cards': ['C3', 'D3', 'H3', 'S3', 'C4']});
      expect(state.lockedHandType, BigTwoCardPattern.fourOfAKind.toJson());

      // P2 bombs with SF
      state = delegate.processAction(state, 'play_cards', p2, {'cards': ['C5', 'C6', 'C7', 'C8', 'C9']});
      expect(state.lastPlayedById, p2);
      expect(state.lockedHandType, BigTwoCardPattern.straightFlush.toJson());
    });

    test('round reset: lastPlayedHand should be empty after round over', () {
      // P1 plays C3
      var state = delegate.processAction(initialState, 'play_cards', p1, {'cards': ['C3']});
      
      // P2 pass, P3 pass, P4 pass
      state = delegate.processAction(state, 'pass_turn', p2, {});
      state = delegate.processAction(state, 'pass_turn', p3, {});
      state = delegate.processAction(state, 'pass_turn', p4, {});
      
      // Now it should be P1's turn again (Round Over)
      expect(state.currentPlayerId, p1);
      expect(state.lockedHandType, '');
      expect(state.lastPlayedHand, isEmpty); // Check reset
      expect(state.passCount, 0);
    });

  });
}
