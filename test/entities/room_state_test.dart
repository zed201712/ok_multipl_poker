import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/entities/room_request.dart';
import 'package:ok_multipl_poker/entities/room_response.dart';
import 'package:ok_multipl_poker/entities/room_state.dart';

void main() {
  group('RoomState', () {
    test('copyWith creates a new instance with updated values', () {
      final originalRoom = Room(
        roomId: 'room1',
        creatorUid: 'user1',
        managerUid: 'user1',
        title: 'Test Room',
        maxPlayers: 4,
        state: 'open',
        body: 'body',
        matchMode: 'rank',
        visibility: 'public',
        randomizeSeats: true,
        participants: [],
        createdAt: null,
        updatedAt: null,
      );

      final originalState = RoomState(
        room: originalRoom,
        requests: [],
        responses: [],
      );

      final newRequest = RoomRequest(
        requestId: 'req1',
        roomId: 'room1',
        participantId: 'user1',
        managerUid: 'user1',
        body: {'action': 'test'},
        createdAt: null,
      );

      final newState = originalState.copyWith(
        requests: [newRequest],
      );

      expect(newState.room, equals(originalRoom));
      expect(newState.requests.length, 1);
      expect(newState.requests.first, equals(newRequest));
      expect(newState.responses, isEmpty);
      
      // Verify immutability of original state
      expect(originalState.requests, isEmpty);
    });

    test('copyWith keeps original values if parameters are null', () {
      final originalRoom = Room(
        roomId: 'room1',
        creatorUid: 'user1',
        managerUid: 'user1',
        title: 'Test Room',
        maxPlayers: 4,
        state: 'open',
        body: 'body',
        matchMode: 'rank',
        visibility: 'public',
        randomizeSeats: true,
        participants: [],
        createdAt: null,
        updatedAt: null,
      );
      
      final originalState = RoomState(
        room: originalRoom,
        requests: [],
        responses: [],
      );

      final newState = originalState.copyWith();

      expect(newState, equals(originalState));
    });
  });
}
