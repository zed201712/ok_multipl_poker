import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/demo/tic_tac_toe_game_page.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/settings/fake_settings_controller.dart';
import 'package:ok_multipl_poker/test/stream_asserter.dart';

void main() {
  group('FirestoreTurnBasedGameController with Mock Controller', () {
    final delegate = TicTacToeDelegate();
    late FirebaseFirestore store;
    late MockFirebaseAuth authP1;
    late MockFirebaseAuth authP2;
    late FirestoreTurnBasedGameController<TicTacToeState> gameControllerP1;
    late FirestoreTurnBasedGameController<TicTacToeState> gameControllerP2;

    final p1Name = 'PlayerOne';
    final p2Name = 'PlayerTwo';

    setUp(() {
      print("____________\nsetUp");
      store = FakeFirebaseFirestore();
      authP1 = MockFirebaseAuth();
      authP2 = MockFirebaseAuth();

      final p1Settings = FakeSettingsController();
      p1Settings.setPlayerName(p1Name);
      final p2Settings = FakeSettingsController();
      p2Settings.setPlayerName(p2Name);
      gameControllerP1 = FirestoreTurnBasedGameController<TicTacToeState>(
        store: store,
        auth: authP1,
        delegate: delegate,
        collectionName: 'rooms',
        settingsController: p1Settings,
      );

      gameControllerP2 = FirestoreTurnBasedGameController<TicTacToeState>(
        store: store,
        auth: authP2,
        delegate: delegate,
        collectionName: 'rooms',
        settingsController: p2Settings,
      );
    });

    Future<void> waitStreamPredicate(StreamPredicate<TurnBasedGameState<TicTacToeState>?> streamPredicate) async {
      final start = DateTime.now();
      await StreamAsserter<TurnBasedGameState<TicTacToeState>?>(
        gameControllerP1.gameStateStream,
        [
          streamPredicate,
        ],
      ).expectWait(timeout: Duration(seconds: 1));
      print("wait ${streamPredicate.reason}, cost time: ${DateTime.now().difference(start).inMilliseconds} ms");
    }

    Future<void> waitStreamRoomPredicate(StreamPredicate<List<Room>?> streamPredicate) async {
      final start = DateTime.now();
      await StreamAsserter<List<Room>?>(
        gameControllerP1.roomStateController.roomsStream,
        [
          streamPredicate,
        ],
      ).expectWait(timeout: Duration(seconds: 1));
      print("wait ${streamPredicate.reason}, cost time: ${DateTime.now().difference(start).inMilliseconds} ms");
    }

    test('full game flow: match, start, play, and leave', () async {
      final start = DateTime.now();

      // 驗證玩家一的遊戲狀態流
      final p1Expectation = StreamAsserter<TurnBasedGameState<TicTacToeState>?>(
          gameControllerP1.gameStateStream,
          [
            // 初始 null 狀態
            StreamPredicate(predicate: (val) => val == null, reason: 'Should be null'),
            // 成功加入房間，等待其他玩家
            StreamPredicate(predicate: (val) => val?.gameStatus == GameStatus.matching, reason: 'matching'),
            StreamPredicate(predicate: (val) => val?.gameStatus == GameStatus.playing, reason: 'playing'),
            // 驗證玩家一的狀態更新：遊戲開始
            // StreamPredicate(
            //     predicate: (val) => val?.gameStatus == GameStatus.playing &&
            //         val?.customState.board == List.filled(9, ''),
            //     reason: 'playing'),
            // 驗證棋盤更新
            StreamPredicate(predicate: (val) => val?.customState.board[0] == 'X', reason: 'board[0]'),
            // // 玩家二下第一步
            StreamPredicate(predicate: (val) => val?.customState.board[1] == 'O', reason: 'board[1]'),
          ],
          // onData: (data) {
          //   print(data?.forPrintJson(delegate) ?? 'nil');
          // }
      );

      // 驗證玩家二的狀態流
      final p2Expectation = StreamAsserter<TurnBasedGameState<TicTacToeState>?>(
        gameControllerP2.gameStateStream,
        [
          // 初始 null 狀態
          StreamPredicate(predicate: (val) => val == null, reason: 'Should be null'),
          // 成功加入房間，遊戲開始
          StreamPredicate(predicate: (val) => val?.gameStatus == GameStatus.playing, reason: 'playing'),
        ],
      );

      // 玩家一配對房間
      final p1MatchFuture = gameControllerP1.matchAndJoinRoom(maxPlayers: 2, randomizeSeats: false);
      final roomId = await p1MatchFuture;
      expect(roomId, isNotEmpty);

      // 玩家二配對同一房間
      final p2MatchFuture = gameControllerP2.matchAndJoinRoom(maxPlayers: 2);
      expect(await p2MatchFuture, roomId);

      await waitStreamPredicate(
        StreamPredicate(predicate: (val) => (val?.gameStatus == GameStatus.playing), reason: 'playing'),
      );
      // 玩家一下第一步
      await gameControllerP1.sendGameAction('place_mark', payload: {'index': 0});

      // 玩家二下第一步
      await gameControllerP2.sendGameAction('place_mark', payload: {'index': 1});
      // 玩家二離開房間
      await gameControllerP2.leaveRoom();

      await waitStreamRoomPredicate(
          StreamPredicate(predicate: (val) => (val?.firstOrNull?.participants.length ?? 2) < 2, reason: 'leaveRoom')
      );
      final participantsCount = gameControllerP1.roomStateController.roomsStream.value.firstOrNull?.participants.length;
      expect((participantsCount ?? -1), 1);

      final p1Assert = await p1Expectation.expectWait(timeout: Duration(seconds: 1));
      final p2Assert = await p2Expectation.expectWait(timeout: Duration(seconds: 1));
      print("cost time: ${DateTime.now().difference(start).inMilliseconds}");
      print("p1 PendingReasons: ${p1Expectation.getPendingReasons()}");
      print("p2 PendingReasons: ${p2Expectation.getPendingReasons()}");
      expect(p1Assert, isTrue);
      expect(p2Assert, isTrue);

      gameControllerP1.dispose();
      gameControllerP2.dispose();
    });

    test('game restart flow', () async {
      // 先完成一個遊戲
      await gameControllerP1.matchAndJoinRoom(maxPlayers: 2, randomizeSeats: false);
      await gameControllerP2.matchAndJoinRoom(maxPlayers: 2);

      final start = DateTime.now();

      // 驗證玩家一的遊戲狀態流
      final p1Expectation = StreamAsserter<TurnBasedGameState<TicTacToeState>?>(
        gameControllerP1.gameStateStream,
        [
          // 初始 null 狀態
          StreamPredicate(predicate: (val) => val == null, reason: 'Should be null'),
          // 成功加入房間，等待其他玩家
          StreamPredicate(predicate: (val) => val?.gameStatus == GameStatus.matching, reason: 'matching'),
          // 驗證棋盤
          StreamPredicate(predicate: (val) => val?.customState.board[0] == 'X', reason: 'board[0]'),
          StreamPredicate(predicate: (val) => val?.customState.board[1] == 'O', reason: 'board[1]'),
          StreamPredicate(predicate: (val) => val?.customState.board[2] == 'X', reason: 'board[2]'),
          StreamPredicate(predicate: (val) => val?.customState.board[3] == 'O', reason: 'board[3]'),
          StreamPredicate(predicate: (val) => val?.customState.board[4] == 'X', reason: 'board[4]'),
          StreamPredicate(predicate: (val) => val?.customState.board[5] == 'O', reason: 'board[5]'),
          StreamPredicate(predicate: (val) => val?.customState.board[6] == 'X', reason: 'board[6]'),
          StreamPredicate(predicate: (val) => val?.customState.board[6] == 'X', reason: 'board[6]'),
          StreamPredicate(predicate: (val) => val?.gameStatus == GameStatus.finished &&
              val?.customState.winner != null, reason: 'winner'),
          StreamPredicate(predicate: (val) => equals(List.filled(9, "")).matches(val?.customState.board, {}), reason: 'reset board'),
        ],
        onData: (data) {
          //print(data?.forPrintJson(delegate) ?? 'nil');
          //print(data?.customState.restartRequesters ?? 'nil');
        }
      );

      await waitStreamPredicate(
        StreamPredicate(predicate: (val) => (val?.gameStatus == GameStatus.playing), reason: 'playing'),
      );
      // X O X
      // O X O
      // X
      await gameControllerP1.sendGameAction('place_mark', payload: {'index': 0}); // X
      await waitStreamPredicate(
        StreamPredicate(predicate: (val) => val?.customState.board[0] == 'X', reason: 'board[0]'),
      );
      await gameControllerP2.sendGameAction('place_mark', payload: {'index': 1}); // O
      await waitStreamPredicate(
        StreamPredicate(predicate: (val) => val?.customState.board[1] == 'O', reason: 'board[1]'),
      );
      await gameControllerP1.sendGameAction('place_mark', payload: {'index': 2}); // X
      await waitStreamPredicate(
        StreamPredicate(predicate: (val) => val?.customState.board[2] == 'X', reason: 'board[2]'),
      );
      await gameControllerP2.sendGameAction('place_mark', payload: {'index': 3}); // O
      await waitStreamPredicate(
        StreamPredicate(predicate: (val) => val?.customState.board[3] == 'O', reason: 'board[3]'),
      );
      await gameControllerP1.sendGameAction('place_mark', payload: {'index': 4}); // X
      await waitStreamPredicate(
        StreamPredicate(predicate: (val) => val?.customState.board[4] == 'X', reason: 'board[4]'),
      );
      await gameControllerP2.sendGameAction('place_mark', payload: {'index': 5}); // O
      await waitStreamPredicate(
        StreamPredicate(predicate: (val) => val?.customState.board[5] == 'O', reason: 'board[1]'),
      );
      await gameControllerP1.sendGameAction('place_mark', payload: {'index': 6}); // X wins

      await waitStreamPredicate(
          StreamPredicate(predicate: (val) => val?.gameStatus == GameStatus.finished &&
              val?.customState.winner != null, reason: 'winner')
      );

      // 1. 玩家二請求重置
      await gameControllerP2.sendGameAction('request_restart');
      await waitStreamPredicate(
        StreamPredicate(predicate: (val) => (val?.customState.restartRequesters.length ?? 0) > 0, reason: 'reset board'),
      );

      // 2. 玩家一請求重置
      await gameControllerP1.sendGameAction('request_restart');

      final p1Assert = await p1Expectation.expectWait(timeout: Duration(seconds: 1));
      print("cost time: ${DateTime.now().difference(start).inMilliseconds}");
      print("p1 PendingReasons: ${p1Expectation.getPendingReasons()}");
      expect(p1Assert, isTrue);

      gameControllerP1.dispose();
      gameControllerP2.dispose();
    });

    test('matchAndJoinRoom: creates new room for first player and joins for second', () async {
      // 1. Player 1 matches and should create a new room.
      final roomId = await gameControllerP1.matchAndJoinRoom(maxPlayers: 2);
      expect(roomId, isNotEmpty);

      // Wait for the room to appear in the stream for P1
      await waitStreamRoomPredicate(
        StreamPredicate(
          predicate: (rooms) => rooms != null && rooms.isNotEmpty && rooms.first.roomId == roomId,
          reason: 'P1 creates a room'
        )
      );

      var room = gameControllerP1.roomStateController.roomsStream.value.first;
      expect(room.participants.length, 1);
      expect(room.participants.first.id, authP1.currentUser!.uid);
      expect(room.participants.first.name, p1Name);
      expect(room.managerUid, authP1.currentUser!.uid);

      // 2. Player 2 matches and should join the existing room.
      final p2RoomId = await gameControllerP2.matchAndJoinRoom(maxPlayers: 2);
      expect(p2RoomId, roomId);

      // Wait for P2 to appear in the participants list
      await waitStreamRoomPredicate(
        StreamPredicate(
          predicate: (rooms) => rooms!.first.participants.length == 2,
          reason: 'P2 joins the room'
        )
      );

      room = gameControllerP1.roomStateController.roomsStream.value.first;
      expect(room.participants.length, 2);
      expect(room.participants.any((p) => p.id == authP2.currentUser!.uid && p.name == p2Name), isTrue);

      gameControllerP1.dispose();
      gameControllerP2.dispose();
    });

    test('leaveRoom: non-manager leaves', () async {
      // Setup: Create and join a 2-player room
      await gameControllerP1.matchAndJoinRoom(maxPlayers: 2);
      await gameControllerP2.matchAndJoinRoom(maxPlayers: 2);
      await waitStreamRoomPredicate(
        StreamPredicate(predicate: (rooms) => rooms!.first.participants.length == 2, reason: 'Wait for P2 to join')
      );
      
      final p1Uid = authP1.currentUser!.uid;
      var room = gameControllerP1.roomStateController.roomsStream.value.first;
      expect(room.managerUid, p1Uid); // P1 is the manager

      // Action: P2 (non-manager) leaves
      await gameControllerP2.leaveRoom();

      // Verification
      await waitStreamRoomPredicate(
        StreamPredicate(predicate: (rooms) => rooms!.first.participants.length == 1, reason: 'Wait for P2 to leave')
      );

      room = gameControllerP1.roomStateController.roomsStream.value.first;
      expect(room.participants.length, 1);
      expect(room.participants.first.id, p1Uid);
      expect(room.managerUid, p1Uid); // Manager should not change

      gameControllerP1.dispose();
      gameControllerP2.dispose();
    });

    test('leaveRoom: manager leaves with successor', () async {
      // Setup: Create and join a 2-player room
      await gameControllerP1.matchAndJoinRoom(maxPlayers: 2);
      await gameControllerP2.matchAndJoinRoom(maxPlayers: 2);
      await waitStreamRoomPredicate(
        StreamPredicate(predicate: (rooms) => rooms!.first.participants.length == 2, reason: 'Wait for P2 to join')
      );

      final p1Uid = authP1.currentUser!.uid;
      final p2Uid = authP2.currentUser!.uid;
      var room = gameControllerP1.roomStateController.roomsStream.value.first;
      expect(room.managerUid, p1Uid); // P1 is the manager

      // Action: P1 (manager) leaves
      await gameControllerP1.leaveRoom();
      
      // Verification: P2 should become the new manager
      await waitStreamRoomPredicate(
        StreamPredicate(
          predicate: (rooms) => rooms!.first.managerUid == p2Uid && rooms.first.participants.length == 1, 
          reason: 'Wait for manager handover and P1 leave'
        )
      );

      room = gameControllerP1.roomStateController.roomsStream.value.first;
      expect(room.participants.length, 1);
      expect(room.participants.first.id, p2Uid);
      expect(room.managerUid, p2Uid); // P2 is the new manager

      gameControllerP1.dispose();
      gameControllerP2.dispose();
    });

    test('leaveRoom: last player leaves, deleting the room', () async {
      // Setup: Create a 1-player room
      final roomId = await gameControllerP1.matchAndJoinRoom(maxPlayers: 2);
      await waitStreamRoomPredicate(
        StreamPredicate(predicate: (rooms) => rooms!.isNotEmpty, reason: 'Wait for room creation')
      );

      var rooms = gameControllerP1.roomStateController.roomsStream.value;
      expect(rooms.length, 1);
      expect(rooms.first.roomId, roomId);

      // Action: The last player leaves
      await gameControllerP1.leaveRoom();

      // Verification: The room should be deleted
      await waitStreamRoomPredicate(
        StreamPredicate(predicate: (rooms) => rooms!.isEmpty, reason: 'Wait for room deletion')
      );

      rooms = gameControllerP1.roomStateController.roomsStream.value;
      expect(rooms, isEmpty);

      gameControllerP1.dispose();
      gameControllerP2.dispose();
    });

  });
}
