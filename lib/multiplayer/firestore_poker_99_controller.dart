import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:ok_multipl_poker/entities/poker_99_state.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/multiplayer/poker_99_ai/poker_99_ai.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/settings/settings.dart';
import 'package:flutter/foundation.dart';

import '../game_internals/poker_99_delegate.dart';

class FirestorePoker99Controller {
  /// 遊戲狀態的響應式數據流。
  late final Stream<TurnBasedGameState<Poker99State>?> gameStateStream;

  /// 底層的回合制遊戲控制器。
  late final FirestoreTurnBasedGameController<Poker99State> _gameController;
  
  /// 測試模式下的 AI 玩家列表
  final List<Poker99AI> _testModeAIs = [];
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
    for (int i = 1; i <= 3; i++) { // Poker 99 通常更多人
      final mockAuth = MockFirebaseAuth(
        signedIn: true, 
        mockUser: MockUser(
          uid: 'ai_bot_$i', 
          displayName: 'Bot $i',
        ),
      );
      
      _testModeAIs.add(Poker99AI(
        firestore: firestore,
        auth: mockAuth, // 每個 AI 使用獨立的 Mock Auth
        settingsController: settingsController,
        delegate: _delegate,
      ));
    }
  }

  /// 匹配並加入一個最多4人的遊戲房間。
  /// 成功時返回房間 ID。
  Future<String?> matchRoom() async {
    try {
      final roomId = await _gameController.matchAndJoinRoom(maxPlayers: 4);
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
    _gameController.startGame();
  }

  /// 玩家出牌。
  /// [cards] 是一個代表玩家要出的牌的列表。
  Future<void> playCards(List<PlayingCard> cards) async {
    final cardStrings = cards.map((c) => PlayingCard.cardToString(c)).toList();
    _gameController.sendGameAction('play_cards', payload: {'cards': cardStrings});
  }

  /// 玩家選擇 pass。
  Future<void> passTurn() async {
    _gameController.sendGameAction('pass_turn');
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
