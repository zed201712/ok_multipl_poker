import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ok_multipl_poker/entities/poker_99_state.dart';
import 'package:ok_multipl_poker/entities/poker_99_play_payload.dart';
import 'package:ok_multipl_poker/game_internals/poker_99_delegate.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/poker_99_ai/poker_99_ai.dart';
import 'package:ok_multipl_poker/multiplayer/strategy/bot_game_strategy.dart';
import 'package:ok_multipl_poker/multiplayer/strategy/game_play_strategy.dart';
import 'package:ok_multipl_poker/multiplayer/strategy/online_multiplayer_strategy.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/settings/settings.dart';

import '../entities/participant_info.dart';
import 'BotContext.dart';
import 'game_status.dart';

class FirestorePoker99Controller {
  /// 遊戲狀態的響應式數據流。
  late final Stream<TurnBasedGameState<Poker99State>?> gameStateStream;

  /// 底層的回合制遊戲控制器。
  late final FirestoreTurnBasedGameController<Poker99State> _gameController;

  /// 測試模式下的 AI 玩家列表
  final List<Poker99AI> _bots = [];
  final Poker99Delegate _delegate;
  late final BotContext<Poker99State> _botContext;
  StreamSubscription? _gameStateSubscription;

  late GamePlayStrategy _gamePlayStrategy;

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

    final botsInfo = <ParticipantInfo>[];
    for (int i = 1; i <= 2; i++) {
      final aiUserId = 'bot_$i';
      botsInfo.add(ParticipantInfo(
        id: aiUserId,
        name: aiUserId,
        avatarNumber: i,
      ));

      final ai = Poker99AI(
        aiUserId: aiUserId,
        delegate: _delegate,
        onAction: (newState) {
          _botContext.updateStateAndAddStream(newState);
        },
      );
      _bots.add(ai);
    }

    _botContext = BotContext<Poker99State>(
      userInfo: ParticipantInfo(
        id: auth.currentUser!.uid,
        name: settingsController.playerName.value,
        avatarNumber: settingsController.playerAvatarNumber.value,
      ),
      botsInfo: botsInfo,
      controller: _gameController,
      delegate: _delegate,
      initialCustomState: Poker99State(participants: [], seats: [], currentPlayerId: ''),
      onBotsAction: (gameState, roomState) {
        for (final bot in _bots) {
          if (gameState.customState.currentPlayerId == bot.aiUserId || 
              gameState.gameStatus == GameStatus.finished) {
            bot.updateState(gameState, roomState);
          }
        }
      },
    );

    _gamePlayStrategy = OnlineMultiplayerStrategy<Poker99State>(_gameController);
  }

  /// 匹配並加入一個最多 6 人的遊戲房間。
  /// 成功時返回房間 ID。
  Future<String?> matchRoom() async {
    return _gamePlayStrategy.matchRoom();
  }

  /// 離開當前所在的房間。
  Future<void> leaveRoom() async {
    await _gamePlayStrategy.leaveRoom();
  }

  Future<void> endRoom() async {
    await _gamePlayStrategy.endRoom();
  }

  /// 發起重新開始遊戲的請求。
  /// 所有玩家都請求後，遊戲將會重置。
  Future<void> restart() async {
    await _gamePlayStrategy.restart();
  }

  Future<void> startGame() async {
    if ((_gameController.roomStateController.roomStateStream.value?.room?.participants.length ?? 0) <= 1) {
      await _gameController.leaveRoom();
      _gamePlayStrategy = BotGameStrategy<Poker99State>(_botContext);
      await _gamePlayStrategy.matchRoom(); // 初始化 Bot 房間
    }

    await _gamePlayStrategy.startGame();
  }

  /// 玩家出牌。
  /// [payload] 包含出牌內容與對應的行動 (Poker99Action)。
  Future<void> playCards(Poker99PlayPayload payload) async {
    await _gamePlayStrategy.sendGameAction('play_cards', payload: payload.toJson());
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
    _gameStateSubscription?.cancel();
    _gameController.dispose();
    // 釋放 AI 資源
    for (final bot in _bots) {
      bot.dispose();
    }
  }
}
