import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/entities/room_state.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_room_state_controller.dart';
import 'package:ok_multipl_poker/settings/persistence/memory_settings_persistence.dart';
import 'package:ok_multipl_poker/settings/settings.dart';
import 'package:ok_multipl_poker/test/stream_asserter.dart';

void main() {
  group('FirestoreRoomStateController Logic Tests (Spec 014 & 015)', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth authP1;
    late MockFirebaseAuth authP2;
    late FirestoreRoomStateController controllerP1;
    late FirestoreRoomStateController controllerP2;
    late SettingsController settingsP1;
    late SettingsController settingsP2;
    const collectionName = 'rooms';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      authP1 = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'user1'));
      authP2 = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'user2'));
      settingsP1 = SettingsController(store: MemoryOnlySettingsPersistence())..setPlayerName('Player1');
      settingsP2 = SettingsController(store: MemoryOnlySettingsPersistence())..setPlayerName('Player2');

      controllerP1 = FirestoreRoomStateController(firestore, authP1, collectionName, settingsP1);
      controllerP2 = FirestoreRoomStateController(firestore, authP2, collectionName, settingsP2);
    });

    tearDown(() {
      controllerP1.dispose();
      controllerP2.dispose();
    });

    Future<void> waitRoomStatePredicate(
        FirestoreRoomStateController controller,
        StreamPredicate<RoomState?> predicate, {
          Duration timeout = const Duration(seconds: 1),
        }) async {
      final start = DateTime.now();
      await StreamAsserter<RoomState?>(
        controller.roomStateStream,
        [predicate],
      ).expectWait(timeout: timeout);
      print("wait ${predicate.reason}, cost time: ${DateTime.now().difference(start).inMilliseconds} ms");
    }

    test('Single player endRoom deletes the room immediately', () async {
      // 1. P1 creates a room
      final roomId = await controllerP1.createRoom(
        title: 'Test Room',
        maxPlayers: 2,
        matchMode: 'test',
        visibility: 'public',
        randomizeSeats: false,
      );
      controllerP1.setRoomId(roomId);

      await waitRoomStatePredicate(
        controllerP1,
        StreamPredicate(
          predicate: (state) => state?.room != null,
          reason: 'Room created and loaded',
        ),
      );

      // 2. P1 calls endRoom
      await controllerP1.endRoom(roomId: roomId);

      // 3. Verify room is deleted
      // Since the stream might close or return null when doc is deleted
      // We can check firestore directly or the stream.
      // The controller sets state to null if roomId is cleared, but here roomId is still set,
      // however the doc listener will update with null/empty if doc deleted?
      // Actually Firestore stream returns exists=false.
      // The current controller implementation maps snapshots: doc.exists ? Room... : null.
      // So roomState.room becomes null.

      await waitRoomStatePredicate(
        controllerP1,
        StreamPredicate(
          predicate: (state) => state?.room == null,
          reason: 'Room should be null after deletion',
        ),
      );

      final doc = await firestore.collection(collectionName).doc(roomId).get();
      expect(doc.exists, isFalse);
    });

    test('Multiplayer endRoom sends request and Manager deletes room', () async {
      // 1. P1 creates room
      final roomId = await controllerP1.createRoom(
        title: 'Multi Room',
        maxPlayers: 3,
        matchMode: 'test',
        visibility: 'public',
        randomizeSeats: false,
      );
      controllerP1.setRoomId(roomId);
      controllerP2.setRoomId(roomId);

      await waitRoomStatePredicate(
        controllerP1,
        StreamPredicate(
          predicate: (state) => state?.room?.participants.length == 1,
          reason: 'create room',
        ),
      );

      // 2. P2 joins room
      // Need P2 to find the room or join by ID.
      // Since we know ID, let's use matchRoom logic or manually join.
      // Simplest is manual join request flow to test full interaction,
      // but matchRoom encapsulates it. Let's replicate matchRoom's join part.
      final p1Uid = authP1.currentUser!.uid;
      await controllerP2.sendRequest(roomId: roomId, managerUid: p1Uid, body: {
        'action': 'join',
        'name': 'Player2',
        'avatarNumber': 1,
      });

      // Wait for P1 (Manager) to process join
      await waitRoomStatePredicate(
        controllerP1,
        StreamPredicate(
          predicate: (state) => state?.room?.participants.length == 2,
          reason: 'P1 sees P2 joined',
        ),
      );

      // Ensure P2 also sees the updated room state
      await waitRoomStatePredicate(
        controllerP2,
        StreamPredicate(
          predicate: (state) => state?.room?.participants.length == 2,
          reason: 'P2 sees themselves joined',
        ),
      );

      // 3. P1 (Manager) calls endRoom
      // Spec 014 says: "若房間內有其他參與者...則發送 end_room 請求"
      // But wait, if P1 IS the manager, and calls endRoom, the code says:
      // "if (otherParticipants.isNotEmpty) { await sendRequest(..., 'end_room'); }"
      // And then P1's stream listener (managerRequestHandler) picks it up and deletes the room.
      // This seems to be the flow.

      await controllerP1.endRoom(roomId: roomId);

      // 4. Verify P1 processes the request and deletes the room
      await waitRoomStatePredicate(
        controllerP1,
        StreamPredicate(
          predicate: (state) => state?.room == null,
          reason: 'Room deleted after endRoom request processed',
        ),
      );

      final doc = await firestore.collection(collectionName).doc(roomId).get();
      expect(doc.exists, isFalse);
    });

    test('Non-manager (P2) calling endRoom sends request, Manager (P1) deletes room', () async {
       // 1. Setup Room with P1 (Manager) and P2
      final roomId = await controllerP1.createRoom(
        title: 'Multi Room 2',
        maxPlayers: 2,
        matchMode: 'test',
        visibility: 'public',
        randomizeSeats: false,
      );
      controllerP1.setRoomId(roomId);
      final p1Uid = authP1.currentUser!.uid;

      // P2 Joins
      await controllerP2.sendRequest(roomId: roomId, managerUid: p1Uid, body: {
        'action': 'join',
        'name': 'Player2',
        'avatarNumber': 1,
      });
      controllerP2.setRoomId(roomId);

      await waitRoomStatePredicate(
        controllerP1,
        StreamPredicate(
          predicate: (state) => state?.room?.participants.length == 2,
          reason: 'P1 sees P2 joined',
        ),
      );

      // 2. P2 (Non-Manager) calls endRoom
      await controllerP2.endRoom(roomId: roomId);

      // 3. P1 should receive the request (via stream) and delete the room
      // P1 needs to be listening. controllerP1 is listening.

      await waitRoomStatePredicate(
        controllerP1,
        StreamPredicate(
          predicate: (state) => state?.room == null,
          reason: 'Room deleted by P1 after P2 requested endRoom',
        ),
      );

      final doc = await firestore.collection(collectionName).doc(roomId).get();
      expect(doc.exists, isFalse);
    });

    test('Request filtering logic (Spec 015): Manager only sees their requests', () async {
      // Setup Room
      final roomId = await controllerP1.createRoom(
        title: 'Filter Room',
        maxPlayers: 3,
        matchMode: 'test',
        visibility: 'public',
        randomizeSeats: false,
      );
      controllerP1.setRoomId(roomId);
      final p1Uid = authP1.currentUser!.uid;

      // P2 joins
      await controllerP2.sendRequest(roomId: roomId, managerUid: p1Uid, body: {'action': 'join', 'name': 'P2', 'avatarNumber': 1,});
      controllerP2.setRoomId(roomId);
      await waitRoomStatePredicate(controllerP1, StreamPredicate(predicate: (s) => s?.room?.participants.length == 2, reason: 'Joined'));

      // Create a "rogue" request with a different managerUid (simulating old request or error)
      final requestCollection = firestore.collection(collectionName).doc(roomId).collection('requests');
      await requestCollection.add({
        'requestId': 'rogue_req',
        'roomId': roomId,
        'participantId': authP2.currentUser!.uid,
        'managerUid': 'some_other_manager_uid', // NOT P1
        'body': {'action': 'alive'},
        'createdAt': FieldValue.serverTimestamp(),
      });

      // P1 should NOT see this request because of the filter `where('managerUid', isEqualTo: currentUserId)`
      // We can verify this by checking P1's request stream directly or ensuring no side effect happens if it was a valid action.
      // But let's check the stream contents.

      // Wait a bit for sync
      //await Future.delayed(Duration(milliseconds: 500));

      final p1State = controllerP1.roomStateStream.value;
      final rogueRequests = p1State?.requests.where((r) => r.body['action'] == 'test').toList();

      // Since P1 filters by managerUid == p1Uid, it should be empty
      expect(rogueRequests, isEmpty);

      // Now add a valid request
      await controllerP2.sendRequest(roomId: roomId, managerUid: p1Uid, body: {'action': 'test'});

      await waitRoomStatePredicate(
        controllerP1,
        StreamPredicate(
          predicate: (s) => s!.requests.any((r) => r.body['action'] == 'test'),
          reason: 'P1 sees valid request'
        )
      );
      expect(controllerP1.roomStateStream.value?.requests.firstOrNull?.body['action'] == 'test', isTrue);
      expect(controllerP1.roomStateStream.value?.requests.length == 1, isTrue);
      expect(controllerP2.roomStateStream.value?.requests.isEmpty, isTrue);
    });
  });
}
