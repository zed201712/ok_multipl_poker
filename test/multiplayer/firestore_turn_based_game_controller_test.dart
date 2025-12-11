import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/demo/tic_tac_toe_game_page.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';

void main() {
  group('FirestoreTurnBasedGameController with Mock Controller', () {
    final delegate = TicTacToeDelegate();
    late FirebaseFirestore store;
    late MockFirebaseAuth authP1;
    late MockFirebaseAuth authP2;
    late FirestoreTurnBasedGameController<TicTacToeState> gameControllerP1;
    late FirestoreTurnBasedGameController<TicTacToeState> gameControllerP2;

    setUp(() {
      print("setUp\n____________");
      store = FakeFirebaseFirestore();
      // authP1 = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'p1_uid'));
      // authP2 = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'p2_uid'));
      authP1 = MockFirebaseAuth();
      authP2 = MockFirebaseAuth();

      gameControllerP1 = FirestoreTurnBasedGameController<TicTacToeState>(
        store: store,
        auth: authP1,
        delegate: delegate,
        collectionName: 'rooms',
      );

      gameControllerP2 = FirestoreTurnBasedGameController<TicTacToeState>(
        store: store,
        auth: authP2,
        delegate: delegate,
        collectionName: 'rooms',
      );
    });

    Future<void> expectWithCallback(
        Object matcher,
        Matcher expectation,
        void Function(Object error, StackTrace st) onFail,
        ) async {
      try {
        await expectLater(matcher, expectation);
      } catch (e, st) {
        onFail(e, st);
        rethrow;
      }
    }

    Future<void> expectWithP1Json(
        Object matcher,
        Matcher expectation,) async {
      expectWithCallback(matcher, expectation, (e, st) {
        //print(gameControllerP1.gameStateStream.value?.forPrintJson(delegate) ?? 'nil');
      });
    }

    test('full game flow: match, start, play, and leave', () async {
      final start = DateTime.now();

      gameControllerP1.gameStateStream.listen((state) {
        // print(state?.forPrintJson(delegate) ?? 'nil');
        //
        final json = state?.toJson(delegate);
        final game = json?["customState"];
        print(game?['board'] ?? "nil");
        print(DateTime.now().difference(start).inMilliseconds);
      });

      // 驗證玩家一的遊戲狀態流
      final p1Expectation = expectLater(
        gameControllerP1.gameStateStream,
        emitsInOrder([
          // 初始 null 狀態
          null,
          // 1. 成功加入房間，等待其他玩家
          emitsThrough(
            isA<TurnBasedGameState<TicTacToeState>>()
                .having((s) => s.gameStatus, 'status', GameStatus.matching),
          ),
          // 2. 驗證玩家一的狀態更新：遊戲開始
          emitsThrough(
            isA<TurnBasedGameState<TicTacToeState>>()
                .having((s) => s.gameStatus, 'status', GameStatus.playing)
                .having((s) => s.customState.board, 'board', List.filled(9, '')),
          ),

          // 4. 輪流行動, 玩家一下第一步
          // 驗證棋盤更新
          emitsThrough(
            isA<TurnBasedGameState<TicTacToeState>>().having((s) {
              return s.customState.board[0];
            }, 'board[0]', 'X'),
          ),
          // // 玩家二下第一步
          emitsThrough(
            isA<TurnBasedGameState<TicTacToeState>>().having((s) {
              return s.customState.board[1];
            }, 'board[1]', 'O'),
          ),
        ]),
      );

      // 驗證玩家二的狀態流
      final p2Expectation = expectLater(
        gameControllerP2.gameStateStream,
        emitsInOrder([
          null,
          // 成功加入房間，開始遊戲
          emitsThrough(
            isA<TurnBasedGameState<TicTacToeState>>()
                .having((s) => s.gameStatus, 'status', GameStatus.playing),
          ),
        ]),
      );

      // 1. 玩家一配對房間
      final p1MatchFuture = gameControllerP1.matchAndJoinRoom(maxPlayers: 2);

      final roomId = await p1MatchFuture;
      expect(roomId, isNotEmpty);

      // 2. 玩家二配對同一房間
      final p2MatchFuture = gameControllerP2.matchAndJoinRoom(maxPlayers: 2);
      expect(await p2MatchFuture, roomId);

      // 3. 玩家一 (管理員) 開始遊戲
      final p1StartFuture = gameControllerP1.startGame();
      //final p1StartFuture = gameControllerP1.setTurnOrder(gameControllerP1.roomStateController.roomStateStream.value!.room!.participants);

      await p1StartFuture;

      // 4. 輪流行動
      // 玩家一下第一步
      await gameControllerP1.sendGameAction('place_mark', payload: {'index': 0});

      // 玩家二下第一步
      await gameControllerP2.sendGameAction('place_mark', payload: {'index': 1});

      // 5. 玩家二離開房間
      await gameControllerP2.leaveRoom();

      // 驗證玩家二的 Stream 結束
      //expect(gameControllerP2.gameStateStream, emits(null));

      await Future.delayed(Duration(milliseconds: 1000));

      gameControllerP1.dispose();
      gameControllerP2.dispose();
    });

    test('game restart flow', () async {
      // 先完成一個遊戲
      await gameControllerP1.matchAndJoinRoom(maxPlayers: 2);
      final roomId = await gameControllerP2.matchAndJoinRoom(maxPlayers: 2);
      await gameControllerP1.startGame();

      // X O X
      // O X O
      // X   
      await gameControllerP1.sendGameAction('place_mark', payload: {'index': 0}); // X
      await gameControllerP2.sendGameAction('place_mark', payload: {'index': 1}); // O
      await gameControllerP1.sendGameAction('place_mark', payload: {'index': 2}); // X
      await gameControllerP2.sendGameAction('place_mark', payload: {'index': 3}); // O
      await gameControllerP1.sendGameAction('place_mark', payload: {'index': 4}); // X
      await gameControllerP2.sendGameAction('place_mark', payload: {'index': 5}); // O
      await gameControllerP1.sendGameAction('place_mark', payload: {'index': 6}); // X wins

      // 驗證遊戲結束，X 獲勝
      await expectLater(
        gameControllerP1.gameStateStream,
        emits(
           isA<TurnBasedGameState<TicTacToeState>>()
            .having((s) => s.gameStatus, 'status', GameStatus.finished)
            .having((s) => s.customState.winner, 'winner', 'X'),
        ),
      );

      // 1. 玩家二請求重置
      await gameControllerP2.sendGameAction('request_restart');

      // 驗證 P2 的請求被記錄
      await expectLater(
        gameControllerP1.gameStateStream,
        emits(
           isA<TurnBasedGameState<TicTacToeState>>()
            .having((s) => s.customState.restartRequesters, 'requesters', ['player2']),
        ),
      );

      // 2. 玩家一請求重置
      await gameControllerP1.sendGameAction('request_restart');

      // 驗證遊戲已重置，棋盤為空
      await expectLater(
        gameControllerP1.gameStateStream,
        emits(
           isA<TurnBasedGameState<TicTacToeState>>()
            .having((s) => s.customState.board, 'board', List.filled(9, ''))
            .having((s) => s.customState.winner, 'winner', null)
            .having((s) => s.customState.restartRequesters, 'requesters', isEmpty),
        ),
      );

      gameControllerP1.dispose();
      gameControllerP2.dispose();
    });

  });
}
