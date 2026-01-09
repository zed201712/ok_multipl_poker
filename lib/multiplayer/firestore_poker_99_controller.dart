import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ok_multipl_poker/entities/poker_99_state.dart';
import 'package:ok_multipl_poker/entities/poker_99_play_payload.dart';
import 'package:ok_multipl_poker/game_internals/poker_99_delegate.dart';
import 'package:ok_multipl_poker/multiplayer/big_two_ai/big_two_ai.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/settings/settings.dart';

class FirestorePoker99Controller {
  /// 遊戲狀態的響應式數據流。
  late final Stream<TurnBasedGameState<Poker99State>?> gameStateStream;

  /// 底層的回合制遊戲控制器。
  late final FirestoreTurnBasedGameController<Poker99State> _gameController;
  
  /// 測試模式下的 AI 玩家列表
  /// TODO: 建立 Poker99AI 並替換 BigTwoAI
  final List<BigTwoAI> _testModeAIs = [];
  final Poker99Delegate _delegate;

  /// 建構子，要求傳入 Firestore 和 Auth 實例。
  FirestorePoker99Controller({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required SettingsController settingsController,
    required Poker99Delegate delegate,
  }) : _delegate = delegate {
    _gameController = FirestoreTurnBasedGameController<Poker99State>(
      store: firestore,
      auth: auth,
      delegate: _delegate,
      collectionName: 'poker_99_rooms',
      settingsController: settingsController,
    );
    gameStateStream = _gameController.gameStateStream;

    // 檢查測試模式並初始化 AI
    if (settingsController.testModeOn.value) {
      _initTestModeAIs(firestore, settingsController);
    }
  }

  void _initTestModeAIs(FirebaseFirestore firestore, SettingsController settingsController) {
    // TODO: 實作 Poker 99 專用的 AI
    // 目前暫時標記為 TODO，並參考 BigTwo 的初始化邏輯
    /*
    for (int i = 1; i <= 2; i++) {
      final mockAuth = MockFirebaseAuth(
        signedIn: true, 
        mockUser: MockUser(
          uid: 'ai_bot_p99_$i', 
          displayName: 'P99 Bot $i',
        ),
      );
      
      // 暫時無法直接使用 BigTwoPlayCardsAI，因為它綁定了 BigTwoDelegate/State
      // 需待 Poker99PlayCardsAI 實作後補上
    }
    */
  }

  /// 匹配並加入一個最多 6 人的遊戲房間。
  /// 成功時返回房間 ID。
  Future<String?> matchRoom() async {
    try {
      final roomId = await _gameController.matchAndJoinRoom(maxPlayers: 6);
      return roomId;
    } catch (e) {
      return null;
    }
  }

  /// 離開當前所在的房間。
  Future<void> leaveRoom() async {
    await _gameController.leaveRoom();
  }

  Future<void> endRoom() async {
    await _gameController.endRoom();
  }

  /// 發起重新開始遊戲的請求。
  /// 所有玩家都請求後，遊戲將會重置。
  Future<void> restart() async {
    _gameController.sendGameAction('request_restart');
  }

  Future<void> startGame() async {
    await _gameController.startGame();
  }

  /// 玩家出牌。
  /// [payload] 包含出牌內容與對應的行動 (Poker99Action)。
  Future<void> playCards(Poker99PlayPayload payload) async {
    _gameController.sendGameAction('play_cards', payload: payload.toJson());
  }

  Poker99State? getCustomGameState() {
    return _gameController.getCustomGameState();
  }

  Future<void> debugSetState(Poker99State newState) async {
    await _gameController.updateCustomGameState(newState);
  }

  int participantCount() {
    final room = _gameController.roomStateController.roomStateStream.value?.room;
    return room?.participants.length ?? 0;
  }

  /// 釋放資源，關閉數據流。
  void dispose() {
    _gameController.dispose();
    // 釋放 AI 資源
    for (final ai in _testModeAIs) {
      ai.dispose();
    }
    _testModeAIs.clear();
  }
}
