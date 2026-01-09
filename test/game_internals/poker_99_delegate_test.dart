import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/entities/big_two_player.dart';
import 'package:ok_multipl_poker/entities/poker_99_play_payload.dart';
import 'package:ok_multipl_poker/entities/poker_99_state.dart';
import 'package:ok_multipl_poker/entities/participant_info.dart';
import 'package:ok_multipl_poker/entities/poker_player.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/game_internals/poker_99_delegate.dart';
import 'package:ok_multipl_poker/game_internals/poker_99_action.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';

void main() {
  group('Poker99Delegate', () {
    late Poker99Delegate delegate;

    setUp(() {
      delegate = Poker99Delegate();
    });

    Room createRoom(List<String> playerIds) {
      return Room(
        roomId: 'room1',
        creatorUid: playerIds.first,
        managerUid: playerIds.first,
        title: 'Poker 99 Room',
        maxPlayers: 4,
        state: 'open',
        body: '',
        matchMode: '',
        visibility: 'public',
        randomizeSeats: false,
        participants: playerIds
            .map((id) => ParticipantInfo(id: id, name: 'Player $id'))
            .toList(),
      );
    }

    group('initializeGame', () {
      test('should initialize with 1 real player and 3 virtual players', () {
        final room = createRoom(['p1']);
        final state = delegate.initializeGame(room);

        expect(state.participants[0].uid, 'p1');
        expect(state.participants.every((p) => p.cards.length == 5), true);
        expect(state.currentPlayerId, 'p1');
      });

      test('should initialize with 2 real players and 2 virtual players', () {
        final room = createRoom(['p1', 'p2']);
        final state = delegate.initializeGame(room);

        expect(state.participants[0].uid, 'p1');
        expect(state.participants[1].uid, 'p2');
      });
    });

    group('processAction: play_cards', () {
      late Room room;
      late Poker99State initialState;

      setUp(() {
        room = createRoom(['p1', 'p2', 'p3', 'p4']);
        initialState = delegate.initializeGame(room);
      });

      test('Normal numeric card (e.g., 3) increases score', () {
        final p1 = initialState.participants[0].copyWith(cards: ['C3', 'D4', 'H6', 'S7', 'C8']);
        var state = initialState.copyWith(participants: [p1, ...initialState.participants.sublist(1)], currentScore: 0);

        final payload = Poker99PlayPayload(
          cards: ['C3'],
          action: Poker99Action.increase,
          value: 3,
        );

        state = delegate.processAction(room, state, 'play_cards', 'p1', payload.toJson());

        expect(state.currentScore, 3);
        expect(state.currentPlayerId, 'p2');
        expect(state.participants[0].cards.length, 5); 
        expect(state.discardCards.first, 'C3');
      });

      test('Spades Ace can set score to zero', () {
        final p1 = initialState.participants[0].copyWith(cards: ['S1', 'D4', 'H6', 'S7', 'C8']);
        var state = initialState.copyWith(
          participants: [p1, ...initialState.participants.sublist(1)],
          currentScore: 50,
        );

        final payload = Poker99PlayPayload(
          cards: ['S1'],
          action: Poker99Action.setToZero,
        );

        state = delegate.processAction(room, state, 'play_cards', 'p1', payload.toJson());

        expect(state.currentScore, 0);
      });

      test('King (13) sets score to 99', () {
        final p1 = initialState.participants[0].copyWith(cards: ['C13', 'D4', 'H6', 'S7', 'C8']);
        var state = initialState.copyWith(
          participants: [p1, ...initialState.participants.sublist(1)],
          currentScore: 10,
        );

        final payload = Poker99PlayPayload(
          cards: ['C13'],
          action: Poker99Action.setTo99,
        );

        state = delegate.processAction(room, state, 'play_cards', 'p1', payload.toJson());

        expect(state.currentScore, 99);
      });

      test('Joker can be used for skip', () {
        final p1 = initialState.participants[0].copyWith(cards: ['S0', 'D4', 'H6', 'S7', 'C8']);
        var state = initialState.copyWith(
          participants: [p1, ...initialState.participants.sublist(1)],
        );

        final payload = Poker99PlayPayload(
          cards: ['S0'],
          action: Poker99Action.skip,
        );

        state = delegate.processAction(room, state, 'play_cards', 'p1', payload.toJson());

        expect(state.currentPlayerId, 'p2');
      });

      test('Reverse card (4) toggles isReverse and changes direction', () {
        final p1 = initialState.participants[0].copyWith(cards: ['C4', 'D4', 'H6', 'S7', 'C8']);
        var state = initialState.copyWith(
          participants: [p1, ...initialState.participants.sublist(1)],
          isReverse: false,
        );

        final payload = Poker99PlayPayload(
          cards: ['C4'],
          action: Poker99Action.reverse,
        );

        state = delegate.processAction(room, state, 'play_cards', 'p1', payload.toJson());

        expect(state.isReverse, true);
        expect(state.currentPlayerId, 'p4'); 
      });

      test('10 can decrease score', () {
        final p1 = initialState.participants[0].copyWith(cards: ['C10', 'D4', 'H6', 'S7', 'C8']);
        var state = initialState.copyWith(
          participants: [p1, ...initialState.participants.sublist(1)],
          currentScore: 50,
        );

        final payload = Poker99PlayPayload(
          cards: ['C10'],
          action: Poker99Action.decrease,
          value: -10,
        );

        state = delegate.processAction(room, state, 'play_cards', 'p1', payload.toJson());

        expect(state.currentScore, 40);
      });

      test('Score clamped to 0 if decreased below 0', () {
        final p1 = initialState.participants[0].copyWith(cards: ['C10', 'D4', 'H6', 'S7', 'C8']);
        var state = initialState.copyWith(
          participants: [p1, ...initialState.participants.sublist(1)],
          currentScore: 5,
        );

        final payload = Poker99PlayPayload(
          cards: ['C10'],
          action: Poker99Action.decrease,
          value: -10,
        );

        state = delegate.processAction(room, state, 'play_cards', 'p1', payload.toJson());

        expect(state.currentScore, 0);
      });

      test('Playing card that exceeds 99 should be ignored', () {
        final p1 = initialState.participants[0].copyWith(cards: ['C9', 'D4', 'H6', 'S7', 'C8']);
        var state = initialState.copyWith(
          participants: [p1, ...initialState.participants.sublist(1)],
          currentScore: 95,
        );

        final payload = Poker99PlayPayload(
          cards: ['C9'],
          action: Poker99Action.increase,
          value: 9,
        );

        final nextState = delegate.processAction(room, state, 'play_cards', 'p1', payload.toJson());

        expect(nextState, state); 
      });
    });

    group('Win Conditions and Logic', () {
      late Room room;
      late Poker99State initialState;

      setUp(() {
        room = createRoom(['p1', 'p2', 'p3', 'p4']);
        initialState = delegate.initializeGame(room);
      });

      test('No reshuffling when deck is empty', () {
        final p1 = initialState.participants[0].copyWith(cards: ['C3']);
        var state = initialState.copyWith(
          participants: [p1, ...initialState.participants.sublist(1)],
          deckCards: [],
          discardCards: ['D2', 'H2'],
        );

        final payload = Poker99PlayPayload(
          cards: ['C3'],
          action: Poker99Action.increase,
          value: 3,
        );

        state = delegate.processAction(room, state, 'play_cards', 'p1', payload.toJson());

        expect(state.participants[0].cards.isEmpty, true);
        expect(state.deckCards.isEmpty, true);
        expect(state.discardCards.length, 3);
      });

      test('Players with empty hands are skipped', () {
        final p1 = initialState.participants[0].copyWith(cards: ['C3']);
        final p2 = initialState.participants[1].copyWith(cards: []);
        var state = initialState.copyWith(
          participants: [p1, p2, ...initialState.participants.sublist(2)],
          currentPlayerId: 'p1',
        );

        final payload = Poker99PlayPayload(
          cards: ['C3'],
          action: Poker99Action.increase,
          value: 3,
        );

        state = delegate.processAction(room, state, 'play_cards', 'p1', payload.toJson());

        expect(state.currentPlayerId, 'p3');
      });

      test('Everyone wins if all hands are empty', () {
        final participants = initialState.participants.map((p) => p.copyWith(cards: [])).toList();
        participants[0] = participants[0].copyWith(cards: ['C3']);
        
        var state = initialState.copyWith(
          participants: participants,
          currentPlayerId: 'p1',
          deckCards: [],
        );

        final payload = Poker99PlayPayload(
          cards: ['C3'],
          action: Poker99Action.increase,
          value: 3,
        );

        state = delegate.processAction(room, state, 'play_cards', 'p1', payload.toJson());

        expect(state.winner != null, true);
        for (var p in state.participants) {
          expect(state.winner!.contains(p.name), true);
        }
      });

      test('Player loses if no playable cards, others win', () {
        final p1 = initialState.participants[0].copyWith(cards: ['C3']);
        final p2 = initialState.participants[1].copyWith(cards: ['S9', 'H9', 'D9', 'C9', 'S8']);
        var state = initialState.copyWith(
          participants: [p1, p2, ...initialState.participants.sublist(2)],
          currentScore: 95,
          currentPlayerId: 'p1',
        );

        final payload = Poker99PlayPayload(
          cards: ['C3'],
          action: Poker99Action.increase,
          value: 3,
        );

        state = delegate.processAction(room, state, 'play_cards', 'p1', payload.toJson());

        expect(state.winner != null, true);
        expect(state.winner!.contains(p2.name), false);
        expect(state.winner!.contains(p1.name), true);
      });
    });
  });
}
