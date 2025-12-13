import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/demo/tic_tac_toe_game_page.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/test/stream_asserter.dart';

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

      // gameControllerP1.gameStateStream.listen((state) {
      //   // print(state?.forPrintJson(delegate) ?? 'nil');
      //   //
      //   final json = state?.toJson(delegate);
      //   final game = json?["customState"];
      //   print(game?['board'] ?? "nil");
      //   print(DateTime.now().difference(start).inMilliseconds);
      // });

      // 驗證玩家一的遊戲狀態流
      final p1Expectation = StreamAsserter<TurnBasedGameState<TicTacToeState>?>(
          gameControllerP1.gameStateStream,
          [
            // 初始 null 狀態
            StreamPredicate(predicate: (val) => val == null, reason: 'Should be null'),
            // 成功加入房間，等待其他玩家
            StreamPredicate(predicate: (val) => val?.gameStatus == GameStatus.matching, reason: 'matching'),
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
      final p1MatchFuture = gameControllerP1.matchAndJoinRoom(maxPlayers: 2, shuffleTurnOrder: false);
      final roomId = await p1MatchFuture;
      expect(roomId, isNotEmpty);

      // 玩家二配對同一房間
      final p2MatchFuture = gameControllerP2.matchAndJoinRoom(maxPlayers: 2);
      expect(await p2MatchFuture, roomId);

      // 玩家一下第一步
      await gameControllerP1.sendGameAction('place_mark', payload: {'index': 0});

      // 玩家二下第一步
      await gameControllerP2.sendGameAction('place_mark', payload: {'index': 1});
      // 玩家二離開房間
      await gameControllerP2.leaveRoom();

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

    // TODO race condition
    // test('game restart flow', () async {
    //   // 先完成一個遊戲
    //   await gameControllerP1.matchAndJoinRoom(maxPlayers: 2, shuffleTurnOrder: false);
    //   await gameControllerP2.matchAndJoinRoom(maxPlayers: 2);
    //
    //   final start = DateTime.now();
    //
    //   // 驗證玩家一的遊戲狀態流
    //   final p1Expectation = StreamAsserter<TurnBasedGameState<TicTacToeState>?>(
    //     gameControllerP1.gameStateStream,
    //     [
    //       // 初始 null 狀態
    //       StreamPredicate(predicate: (val) => val == null, reason: 'Should be null'),
    //       // 成功加入房間，等待其他玩家
    //       StreamPredicate(predicate: (val) => val?.gameStatus == GameStatus.matching, reason: 'matching'),
    //       // 驗證棋盤
    //       StreamPredicate(predicate: (val) => val?.customState.board[0] == 'X', reason: 'board[0]'),
    //       StreamPredicate(predicate: (val) => val?.customState.board[1] == 'O', reason: 'board[1]'),
    //       StreamPredicate(predicate: (val) => val?.customState.board[2] == 'X', reason: 'board[2]'),
    //       StreamPredicate(predicate: (val) => val?.customState.board[3] == 'O', reason: 'board[3]'),
    //       StreamPredicate(predicate: (val) => val?.customState.board[4] == 'X', reason: 'board[4]'),
    //       StreamPredicate(predicate: (val) => val?.customState.board[5] == 'O', reason: 'board[5]'),
    //       StreamPredicate(predicate: (val) => val?.customState.board[6] == 'X', reason: 'board[6]'),
    //       StreamPredicate(predicate: (val) => val?.customState.board[6] == 'X', reason: 'board[6]'),
    //       StreamPredicate(predicate: (val) => val?.gameStatus == GameStatus.finished &&
    //           val?.customState.winner != null, reason: 'winner'),
    //       StreamPredicate(predicate: (val) => val?.customState.board == List.filled(9, ''), reason: 'reset board'),
    //     ],
    //     onData: (data) {
    //
    //       print(data?.customState.restartRequesters ?? 'nil');
    //     }
    //   );
    //
    //   // X O X
    //   // O X O
    //   // X
    //   await gameControllerP1.sendGameAction('place_mark', payload: {'index': 0}); // X
    //   await gameControllerP2.sendGameAction('place_mark', payload: {'index': 1}); // O
    //   await gameControllerP1.sendGameAction('place_mark', payload: {'index': 2}); // X
    //   await gameControllerP2.sendGameAction('place_mark', payload: {'index': 3}); // O
    //   await gameControllerP1.sendGameAction('place_mark', payload: {'index': 4}); // X
    //   await gameControllerP2.sendGameAction('place_mark', payload: {'index': 5}); // O
    //   await gameControllerP1.sendGameAction('place_mark', payload: {'index': 6}); // X wins
    //
    //   // 1. 玩家二請求重置
    //   await gameControllerP2.sendGameAction('request_restart');
    //   // 2. 玩家一請求重置
    //   await gameControllerP1.sendGameAction('request_restart');
    //
    //   final p1Assert = await p1Expectation.expectWait(timeout: Duration(seconds: 1));
    //   print("cost time: ${DateTime.now().difference(start).inMilliseconds}");
    //   print("p1 PendingReasons: ${p1Expectation.getPendingReasons()}");
    //   expect(p1Assert, isTrue);
    //
    //   gameControllerP1.dispose();
    //   gameControllerP2.dispose();
    // });

  });
}
