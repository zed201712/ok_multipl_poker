import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/multiplayer/mock_firestore_room_state_controller.dart';
import 'package:matcher/matcher.dart';

void main() {
  final MockFirestoreRoomStateController controller = MockFirestoreRoomStateController();
  late String initialUserId = controller.currentUserId!;

  setUp(() {
    initialUserId = controller.currentUserId!;
  });

  tearDown(() {

  });

  group('MockFirestoreRoomStateController', () {

    test('createRoom should emit an updated list of rooms', () async {
      expect(
        controller.roomsStream,
        emitsInOrder([
          isEmpty,
              (dynamic rooms) => rooms is List<Room> && rooms.length == 1,
          isEmpty,
        ]),
      );

      final roomId = await controller.createRoom(
        title: 'Test Room',
        maxPlayers: 2,
        matchMode: 'test',
        visibility: 'public',
      );

      final room = controller.roomsStream.value.first;
      expect(room.roomId, roomId);
      expect(room.creatorUid, initialUserId);
      expect(room.managerUid, initialUserId);
      await controller.leaveRoom(roomId: roomId);
    });

    test('leaveRoom as manager (last participant) should delete the room', () async {
      final roomId = await controller.createRoom(
        title: 'Solo Room', maxPlayers: 1, matchMode: 'test', visibility: 'public');

      // Expect the room to be created, then the list to become empty
      expect(
        controller.roomsStream,
        emitsInOrder([
          (dynamic rooms) => rooms.length == 1,
          isEmpty,
        ]),
      );

      // Set the room context before leaving
      controller.setRoomId(roomId);
      controller.printJson();
      await controller.leaveRoom(roomId: roomId);
    });

    test('matchRoom finds no available room and creates a new one', () async {
      expect(controller.roomsStream.value, isEmpty);

      final roomId = await controller.matchRoom(
        title: 'Matching Game',
        maxPlayers: 2,
        matchMode: 'test',
        visibility: 'public',
      );

      expect(roomId, isNotEmpty);
      final rooms = controller.roomsStream.value;
      expect(rooms.length, 1);
      expect(rooms.first.roomId, roomId);
      expect(rooms.first.visibility, 'public');
    });
  });
}