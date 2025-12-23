import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/entities/big_two_player.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/entities/participant_info.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/game_internals/big_two_card_pattern.dart';
import 'package:ok_multipl_poker/game_internals/big_two_delegate.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';

void main() {
  late BigTwoDelegate delegate;
  late BigTwoPlayer player;

  setUp(() {
    delegate = BigTwoDelegate();
    player = BigTwoPlayer(
      uid: 'player1',
      name: 'Player 1',
      cards: ['C3', 'D3', 'H3', 'S3', 'C4', 'D4', 'H4', 'S4', 'C5', 'D5', 'H5', 'S5', 'C10'], // 13 cards
    );
  });

  group('BigTwoDelegate AI Helpers', () {
    test('getPlayablePatterns returns all patterns on free turn', () {
      final state = BigTwoState(
        participants: [player],
        seats: ['player1'],
        currentPlayerId: 'player1',
        lockedHandType: '', // Free turn
      );

      final handCards = player.cards.map(PlayingCard.fromString).toList();
      final patterns = delegate.getPlayablePatterns(state, handCards);
      
      expect(patterns, containsAll(BigTwoCardPattern.values));
    });

    test('getPlayablePatterns returns locked pattern + bombs on locked turn', () {
      final state = BigTwoState(
        participants: [player],
        seats: ['player1'],
        currentPlayerId: 'player1',
        lockedHandType: 'Single',
      );

      final handCards = player.cards.map(PlayingCard.fromString).toList();
      final patterns = delegate.getPlayablePatterns(state, handCards);
      
      expect(patterns, contains(BigTwoCardPattern.single));
      expect(patterns, contains(BigTwoCardPattern.fourOfAKind)); // Bomb
      expect(patterns, contains(BigTwoCardPattern.straightFlush)); // Bomb
      expect(patterns, isNot(contains(BigTwoCardPattern.pair)));
    });

    test('getPlayableCombinations returns correct singles', () {
      // Last played: D3
      final state = BigTwoState(
        participants: [player],
        seats: ['player1'],
        currentPlayerId: 'player1',
        lockedHandType: 'Single',
        lastPlayedHand: ['D3'],
      );

      final handCards = player.cards.map(PlayingCard.fromString).toList();
      final combos = delegate.getPlayableCombinations(state, handCards, BigTwoCardPattern.single);
      
      // Should beat D3 (Value: 3, Suit: Diamonds=2)
      // C3 (3, Clubs=1) -> No
      // H3 (3, Hearts=3) -> Yes
      // S3 (3, Spades=4) -> Yes
      // All 4s, 5s, As -> Yes

      // Check specific examples
      expect(combos.any((c) => c.contains('C3')), isFalse);
      expect(combos.any((c) => c.contains('H3')), isTrue);
      expect(combos.any((c) => c.contains('C10')), isTrue);
    });

    test('getPlayableCombinations returns correct pairs', () {
      // Last played: Pair 3s (C3, D3) -> Rank 3, High Suit D (2)
      final state = BigTwoState(
        participants: [player],
        seats: ['player1'],
        currentPlayerId: 'player1',
        lockedHandType: 'Pair',
        lastPlayedHand: ['C3', 'D3'],
      );
      
      // Player has 3s (C,D,H,S), 4s...
      // Pairs of 3s:
      // (C3,D3) -> Same as last played (can't beat itself usually, need strictly greater)
      // (C3,H3) -> High H3 > D3 -> Yes
      // (H3,S3) -> High S3 > D3 -> Yes
      
      final handCards = player.cards.map(PlayingCard.fromString).toList();
      final combos = delegate.getPlayableCombinations(state, handCards, BigTwoCardPattern.pair);

      // Verify
      // C3,D3 pair is the one played.
      // C3,H3
      expect(combos.any((c) => c.contains('C3') && c.contains('H3')), isTrue);
      
      // 4s pairs
      expect(combos.any((c) => c.contains('C4') && c.contains('D4')), isTrue);
    });

    test('getAllPlayableCombinations aggregates results', () {
       final state = BigTwoState(
        participants: [player],
        seats: ['player1'],
        currentPlayerId: 'player1',
        lockedHandType: 'Single',
        lastPlayedHand: ['D3'],
      );

      final handCards = player.cards.map(PlayingCard.fromString).toList();
      final allCombos = delegate.getAllPlayableCombinations(state, handCards);
      
      // Should contain singles > D3
      expect(allCombos.any((c) => c.length == 1 && c.contains('H3')), isTrue);
      
      // Should contain bombs (Four of a Kind) if any
      // Player has 3333, 4444, 5555.
      expect(allCombos.any((c) => c.length == 5 && delegate.isFourOfAKind(c.map(PlayingCard.fromString).toList())), isTrue);
    });
  });

  group('BigTwoDelegate Initialization Logic', () {
    test('Initializes 2-player game with Virtual Player', () {
      final room = Room(
        roomId: 'room1',
        creatorUid: 'p1',
        managerUid: 'p1',
        title: 'room1',
        maxPlayers: 4,
        state: 'open',
        body: '',
        matchMode: '',
        visibility: 'public',
        randomizeSeats: false,
        participants: [
          ParticipantInfo(id: 'p1', name: 'P1'),
          ParticipantInfo(id: 'p2', name: 'P2'),
        ],
      );

      final state = delegate.initializeGame(room);

      expect(state.participants.length, 3);
      expect(state.participants.any((p) => p.isVirtualPlayer), isTrue);
      expect(state.participants.firstWhere((p) => p.isVirtualPlayer).uid, 'virtual_player');
    });

    test('Distributes remainder card to lowest card holder (Human)', () {
       // Mock a scenario or check statistically?
       // It's hard to mock deck shuffling in unit test without dependency injection of deck factory.
       // But we can check card counts.
       // 52 cards. 3 players.
       // 17, 17, 17. Remainder 1.
       // One player should have 18. The others 17.
       
       final room = Room(
         roomId: 'room1',
         creatorUid: 'p1',
         managerUid: 'p1',
         title: 'room1',
         maxPlayers: 4,
         state: 'open',
         body: '',
         matchMode: '',
         visibility: 'public',
         randomizeSeats: false,
         participants: [
           ParticipantInfo(id: 'p1', name: 'P1'),
           ParticipantInfo(id: 'p2', name: 'P2'),
           ParticipantInfo(id: 'p3', name: 'P3'),
         ],
      );
      
      final state = delegate.initializeGame(room);
      
      final lengths = state.participants.map((p) => p.cards.length).toList();
      expect(lengths, containsAll([17, 17, 18])); // One must be 18
      
      // Verify the one with 18 is the one with the lowest card
      // We need to re-find lowest card
      final lowestCardStr = delegate.getLowestHumanCard_ForTest(state.participants); // Need to expose private method or use similar logic
      
      final holder = state.participants.firstWhere((p) => p.cards.contains(lowestCardStr));
      expect(holder.cards.length, 18);
    });
  });
}

// Extension to access private method for testing if needed, or just copy logic
extension BigTwoDelegateTestExt on BigTwoDelegate {
    String getLowestHumanCard_ForTest(List<BigTwoPlayer> players) {
         // Copy of _findLowestHumanCard logic
        PlayingCard? lowestCard;
        for (final player in players) {
          if (player.isVirtualPlayer) continue;
          final hand = player.cards.map(PlayingCard.fromString).toList();
          if (hand.isEmpty) continue;
          final sortedHand = sortCardsByRank(hand);
          final playerLowest = sortedHand.first;
          if (lowestCard == null) {
            lowestCard = playerLowest;
          } else {
            if (_compareCards_ForTest(playerLowest, lowestCard) < 0) {
              lowestCard = playerLowest;
            }
          }
        }
        return lowestCard != null ? PlayingCard.cardToString(lowestCard) : 'C3';
    }

    int _compareCards_ForTest(PlayingCard a, PlayingCard b) {
        final rankComp = getBigTwoValue(a.value).compareTo(getBigTwoValue(b.value));
        if (rankComp != 0) return rankComp;
        return getSuitValue(a.suit).compareTo(getSuitValue(b.suit));
    }
}
