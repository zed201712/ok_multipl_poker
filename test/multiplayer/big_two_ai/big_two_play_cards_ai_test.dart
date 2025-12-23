import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/game_internals/big_two_delegate.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/multiplayer/big_two_ai/big_two_play_cards_ai.dart';
import 'package:ok_multipl_poker/settings/settings.dart';

class FakeSettingsController extends Fake implements SettingsController {
  @override
  ValueNotifier<String> get playerName => ValueNotifier('AI Player');
  
  @override
  ValueNotifier<bool> get muted => ValueNotifier(false);
  
  @override
  ValueNotifier<bool> get soundsOn => ValueNotifier(true);
  
  @override
  ValueNotifier<bool> get musicOn => ValueNotifier(true);
}

void main() {
  group('BigTwoPlayCardsAI Strategy (with Real Delegate)', () {
    late BigTwoDelegate realDelegate;
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth fakeAuth;
    late FakeSettingsController fakeSettings;
    
    late BigTwoPlayCardsAI ai;
    const aiUserId = 'ai_user_id';

    setUp(() {
      realDelegate = BigTwoDelegate();
      fakeFirestore = FakeFirebaseFirestore();
      fakeAuth = MockFirebaseAuth();
      fakeSettings = FakeSettingsController();

      ai = BigTwoPlayCardsAI(
        firestore: fakeFirestore,
        auth: fakeAuth,
        settingsController: fakeSettings,
        delegate: realDelegate,
      );
    });

    test('First Turn: Must play combination containing lowest card', () {
      // Arrange
      // C3 is lowest. Hand: C3, D3, H3
      final c3 = PlayingCard.fromString('C3');
      final d3 = PlayingCard.fromString('D3');
      final h3 = PlayingCard.fromString('H3');
      final hand = [d3, c3, h3]; // Not sorted initially

      final state = BigTwoState(
        participants: [],
        seats: [aiUserId],
        currentPlayerId: aiUserId,
        lastPlayedHand: [],
        lastPlayedById: '', // First turn
        lockedHandType: '',
      );

      // Act
      final result = ai.findBestMove(state, hand);

      // Assert
      expect(result, isNotNull);
      // Result must contain C3
      expect(result, contains('C3'));
      // Real delegate logic should find ['C3'] or ['C3', 'D3'] or ['C3', 'D3', 'H3'] (if valid triplet? No, FullHouse needs 5)
      // Or ['C3', 'D3', 'H3'] is a triplet, but BigTwo usually doesn't play 3-card unless variant.
      // Standard Big Two patterns: Single, Pair, 5-card.
      // So valid: ['C3'] (Single), ['C3', 'D3'] (Pair with D3? No, C3 and D3 is pair).
      // Pairs: (C3, D3), (C3, H3), (D3, H3).
      // C3 must be present.
      // So ['C3'] or ['C3', 'D3'] or ['C3', 'H3'].
      // Also check 5-card combos if any.
    });

    test('Free Turn: Prioritizes Straight Flush over other patterns', () {
      // Arrange: Hand contains a Straight Flush and a Single
      // Hand: C3, C4, C5, C6, C7, H9
      final hand = [
        PlayingCard.fromString('C3'),
        PlayingCard.fromString('C4'),
        PlayingCard.fromString('C5'),
        PlayingCard.fromString('C6'),
        PlayingCard.fromString('C7'),
        PlayingCard.fromString('H9')
      ];
      
      final state = BigTwoState(
        participants: [],
        seats: [aiUserId],
        currentPlayerId: aiUserId,
        lastPlayedHand: [], 
        lastPlayedById: aiUserId, // Free turn
        lockedHandType: '',
      );

      // Act
      final result = ai.findBestMove(state, hand);

      // Assert
      // Should prioritize Straight Flush (5 cards)
      expect(result, unorderedEquals(['C3', 'C4', 'C5', 'C6', 'C7']));
    });

    test('Free Turn: Prioritizes Full House over Straight', () {
      // Arrange: Hand contains Full House and Straight
      // Hand: 3,3,3, 4,4 (FH), 3,4,5,6,7 (Straight - impossible with cards above, let's construct carefully)
      // Hand: C3, D3, H3 (Trips), C4, D4 (Pair), S5, S6, S7
      // Wait, 3,4,5,6,7 needs 3,4,5,6,7.
      // Let's use:
      // FH: 4,4,4, 5,5 -> C4, D4, H4, C5, D5
      // Straight: 3,4,5,6,7 -> C3, S4 (reuse value?), S5, S6, S7
      // Distinct cards: C3, C4, D4, H4, C5, D5, S6, S7
      // FH: (C4,D4,H4, C5,D5) -> Valid
      // Straight: No straight here (3,4,5,6,7 needs 3,4,5,6,7 ranks).
      // Let's give: C3, D4, H5, S6, C7 (Straight) AND S9, H9, D9, C8, D8 (Full House)
      final hand = [
        PlayingCard.fromString('C3'),
        PlayingCard.fromString('D4'),
        PlayingCard.fromString('H5'),
        PlayingCard.fromString('S6'),
        PlayingCard.fromString('C7'), // Straight
        PlayingCard.fromString('C8'),
        PlayingCard.fromString('D8'),
        PlayingCard.fromString('S9'),
        PlayingCard.fromString('H9'),
        PlayingCard.fromString('D9'), // Full House (99988)
      ];

      final state = BigTwoState(
        participants: [],
        seats: [aiUserId],
        currentPlayerId: aiUserId,
        lastPlayedHand: [], 
        lastPlayedById: aiUserId,
        lockedHandType: '',
      );

      // Act
      final result = ai.findBestMove(state, hand);

      // Assert
      // Priority: SF > 4K > FH > Straight
      // Should pick Full House
      expect(result!.length, 5);
      // Check if it's the full house (contains 9s)
      expect(result.any((c) => c.contains('9')), isTrue);
    });

    test('Normal Turn (Follow): Selects smallest beating combination', () {
      // Arrange
      // Hand: Pairs of 4s and Pairs of 5s.
      // D4, S4 (Pair 4, S high)
      // D5, S5 (Pair 5, S high)
      // Last played: Pair 3s (C3, D3)
      final hand = [
        PlayingCard.fromString('D4'), 
        PlayingCard.fromString('S4'),
        PlayingCard.fromString('D5'), 
        PlayingCard.fromString('S5')
      ];
      
      final state = BigTwoState(
        participants: [],
        seats: [aiUserId],
        currentPlayerId: aiUserId,
        lastPlayedHand: ['C3', 'D3'],
        lastPlayedById: 'other', 
        lockedHandType: 'Pair',
      );

      // Act
      final result = ai.findBestMove(state, hand);

      // Assert
      // Should pick Pair 4s (D4, S4) because it's smallest valid move
      expect(result, unorderedEquals(['D4', 'S4']));
    });

    test('Normal Turn (Follow): Filters out non-beating combinations', () {
       // Arrange
      // Hand: Pair 3s (C3, D3)
      // Last played: Pair 4s (C4, D4)
      final hand = [
        PlayingCard.fromString('C3'), 
        PlayingCard.fromString('D3')
      ];
      
      final state = BigTwoState(
        participants: [],
        seats: [aiUserId],
        currentPlayerId: aiUserId,
        lastPlayedHand: ['C4', 'D4'],
        lastPlayedById: 'other', 
        lockedHandType: 'Pair',
      );

      // Act
      final result = ai.findBestMove(state, hand);

      // Assert
      expect(result, isNull); // Cannot beat
    });
    
    test('Bomb Logic: Four of a Kind beats Straight', () {
       // Arrange
       // Hand: 4444 (C4, D4, H4, S4) + others
       final hand = [
         PlayingCard.fromString('C4'),
         PlayingCard.fromString('D4'),
         PlayingCard.fromString('H4'),
         PlayingCard.fromString('S4'),
         PlayingCard.fromString('C5')
       ];
       
       // Locked: Straight
       final state = BigTwoState(
         participants: [],
         seats: [aiUserId],
         currentPlayerId: aiUserId,
         lastPlayedHand: ['C3', 'D4', 'H5', 'S6', 'C7'], 
         lastPlayedById: 'other', 
         lockedHandType: 'Straight',
       );
       
       // Act
       final result = ai.findBestMove(state, hand);
       
       // Assert
       // Should select 4Kind
       expect(result, isNotNull);
       expect(result!.length, 5);
       // Should contain all 4s
       expect(result, containsAll(['C4', 'D4', 'H4', 'S4']));
    });

    test('Pass: Returns null when no move is possible', () {
      // Arrange
      final hand = [PlayingCard.fromString('C3')];
      final state = BigTwoState(
        participants: [],
        seats: [aiUserId],
        currentPlayerId: aiUserId,
        lastPlayedHand: ['D3'], // Higher than C3
        lastPlayedById: 'other', 
        lockedHandType: 'Single',
      );

      // Act
      final result = ai.findBestMove(state, hand);

      // Assert
      expect(result, isNull);
    });
  });
}
