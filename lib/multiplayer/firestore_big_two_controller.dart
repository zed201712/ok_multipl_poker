import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/multiplayer/big_two_ai/big_two_ai.dart';
import 'package:ok_multipl_poker/multiplayer/big_two_ai/big_two_play_cards_ai.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/settings/settings.dart';
import 'package:flutter/foundation.dart';

import '../game_internals/big_two_delegate.dart';

class FirestoreBigTwoController {
  /// 遊戲狀態的響應式數據流。
  late final Stream<TurnBasedGameState<BigTwoState>?> gameStateStream;

  /// 底層的回合制遊戲控制器。
  late final FirestoreTurnBasedGameController<BigTwoState> _gameController;
  
  /// 測試模式下的 AI 玩家列表
  final List<BigTwoAI> _testModeAIs = [];
  final BigTwoDelegate _delegate;

  /// 建構子，要求傳入 Firestore 和 Auth 實例。
  FirestoreBigTwoController({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required SettingsController settingsController,
    required BigTwoDelegate delegate,
  }) : _delegate = delegate {
    _gameController = FirestoreTurnBasedGameController<BigTwoState>(
      store: firestore,
      auth: auth,
      delegate: _delegate,
      collectionName: 'big_two_rooms',
      settingsController: settingsController,
    );
    gameStateStream = _gameController.gameStateStream;

    // 檢查測試模式並初始化 AI
    if (settingsController.testModeOn.value) {
      _initTestModeAIs(firestore, settingsController);
    }
  }

  void _initTestModeAIs(FirebaseFirestore firestore, SettingsController settingsController) {
    for (int i = 1; i <= 2; i++) {
      final mockAuth = MockFirebaseAuth(
        signedIn: true, 
        mockUser: MockUser(
          uid: 'ai_bot_$i', 
          displayName: 'Bot $i',
          //email: 'bot$i@example.com',
        ),
      );
      
      _testModeAIs.add(BigTwoPlayCardsAI(
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
      // You might want to log this error or rethrow a specific exception
      return null;
    }
  }

  /// 離開當前所在的房間。
  Future<void> leaveRoom() async {
    await _gameController.leaveRoom();
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

  BigTwoState? getCustomGameState() {
    return _gameController.getCustomGameState();
  }

  Future<void> debugSetState(BigTwoState newState) async {
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
