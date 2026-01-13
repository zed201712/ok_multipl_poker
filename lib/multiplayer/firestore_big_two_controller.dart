import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/multiplayer/big_two_ai/big_two_ai.dart';
import 'package:ok_multipl_poker/multiplayer/big_two_ai/big_two_play_cards_ai.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/strategy/bot_game_strategy.dart';
import 'package:ok_multipl_poker/multiplayer/strategy/game_play_strategy.dart';
import 'package:ok_multipl_poker/multiplayer/strategy/online_multiplayer_strategy.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/settings/settings.dart';

import '../entities/participant_info.dart';
import 'BotContext.dart';
import '../game_internals/big_two_delegate.dart';
import 'game_status.dart';

class FirestoreBigTwoController {
  /// 遊戲狀態的響應式數據流。
  late final Stream<TurnBasedGameState<BigTwoState>?> gameStateStream;

  /// 底層的回合制遊戲控制器。
  late final FirestoreTurnBasedGameController<BigTwoState> _gameController;
  
  /// 機器人列表
  final List<BigTwoAI> _bots = [];
  final BigTwoDelegate _delegate;
  late final BotContext<BigTwoState> _botContext;

  late GamePlayStrategy _gamePlayStrategy;

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

    final botsInfo = <ParticipantInfo>[];
    for (int i = 1; i <= 2; i++) {
      final aiUserId = 'bot_$i';
      botsInfo.add(ParticipantInfo(
        id: aiUserId,
        name: 'Bot $i',
        avatarNumber: i,
      ));

      final ai = BigTwoPlayCardsAI(
        aiUserId: aiUserId,
        delegate: _delegate,
        onAction: (newState) {
          _botContext.updateStateAndAddStream(newState);
        },
      );
      _bots.add(ai);
    }

    _botContext = BotContext<BigTwoState>(
      userInfo: ParticipantInfo(
        id: auth.currentUser!.uid,
        name: settingsController.playerName.value,
        avatarNumber: settingsController.playerAvatarNumber.value,
      ),
      botsInfo: botsInfo,
      controller: _gameController,
      delegate: _delegate,
      initialCustomState: BigTwoState(participants: [], seats: [], currentPlayerId: ''),
      onBotsAction: (gameState, roomState) {
        for (final bot in _bots) {
          // 在 Big Two 中，如果是 AI 的回合，或者遊戲結束 (處理重開請求)，則呼叫 AI
          if (gameState.currentPlayerId == bot.aiUserId || 
              gameState.gameStatus == GameStatus.finished) {
            bot.updateState(gameState, roomState);
          }
        }
      },
    );

    _gamePlayStrategy = OnlineMultiplayerStrategy<BigTwoState>(_gameController);
  }

  /// 匹配並加入一個最多4人的遊戲房間。
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
      _gamePlayStrategy = BotGameStrategy<BigTwoState>(_botContext);
      await _gamePlayStrategy.matchRoom(); // 初始化 Bot 房間
    }

    await _gamePlayStrategy.startGame();
  }

  /// 玩家出牌。
  /// [cards] 是一個代表玩家要出的牌的列表。
  Future<void> playCards(List<PlayingCard> cards) async {
    final cardStrings = cards.map((c) => PlayingCard.cardToString(c)).toList();
    await _gamePlayStrategy.sendGameAction('play_cards', payload: {'cards': cardStrings});
  }

  /// 玩家選擇 pass。
  Future<void> passTurn() async {
    await _gamePlayStrategy.sendGameAction('pass_turn');
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
    for (final bot in _bots) {
      bot.dispose();
    }
    _bots.clear();
  }
}
