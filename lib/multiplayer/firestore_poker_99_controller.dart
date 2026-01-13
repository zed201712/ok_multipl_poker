import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ok_multipl_poker/entities/poker_99_state.dart';
import 'package:ok_multipl_poker/entities/poker_99_play_payload.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/entities/room_state.dart';
import 'package:ok_multipl_poker/game_internals/poker_99_delegate.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/poker_99_ai/poker_99_ai.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/settings/settings.dart';

import '../entities/participant_info.dart';
import 'game_status.dart';

class _BotContext<T extends TurnBasedCustomState> {
  final TurnBasedGameDelegate<T> _delegate;
  /// 用於管理與反應遊戲狀態變化的 Subject
  final FirestoreTurnBasedGameController<T> controller;
  StreamSubscription? _streamSubscription;
  final ParticipantInfo userInfo;
  final List<ParticipantInfo> botsInfo;
  final void Function(TurnBasedGameState<T> gameState, RoomState roomState) onBotsAction;

  bool _isRoomCreated = false;
  bool _isGameStarted = false;
  RoomState _roomState = RoomState();
  TurnBasedGameState<T> _turnBasedGameState;

  _BotContext({
    required this.userInfo,
    required this.botsInfo,
    required this.controller,
    required TurnBasedGameDelegate<T> delegate,
    required T initialCustomState,
    required this.onBotsAction,
  })  : _delegate = delegate,
        _turnBasedGameState = TurnBasedGameState<T>(customState: initialCustomState);

  void createRoom() {
    List<ParticipantInfo> infoList = List.from(botsInfo);
    infoList.insert(
        Random().nextInt(infoList.length + 1),
        userInfo
    );

    _roomState = RoomState(
      room: Room(
          creatorUid: userInfo.id,
          managerUid: userInfo.id,
          title: 'Bot Game',
          maxPlayers: botsInfo.length + 1,
          state: '',
          body: '',
          matchMode: '',
          visibility: '',
          randomizeSeats: false,
          participants: infoList,
      ),
      requests: [],
      responses: [],
    );

    _isRoomCreated = true;
  }

  void _notifyBots() {
    if (!_isRoomCreated || !_isGameStarted) return;
    onBotsAction(_turnBasedGameState, _roomState);
  }

  void sendAction(String action, {Map<String, dynamic>? payload}) {
    final newState = _delegate.processAction(_roomState.room!, _turnBasedGameState.customState, action, userInfo.id, payload ?? {});
    _updateStateAndAddStream(newState);
  }

  void startGame() {
    final initialCustomState = _delegate.initializeGame(_roomState.room!);
    _turnBasedGameState = _turnBasedGameState.copyWith(
      gameStatus: GameStatus.playing,
      currentPlayerId: _delegate.getCurrentPlayer(initialCustomState),
      winner: null,
      customState: initialCustomState,
    );

    _isGameStarted = true;
    _streamSubscription?.cancel();
    _streamSubscription = controller.gameStateStream.listen((gameState) {
      _notifyBots();
    });
    _updateState(initialCustomState);
  }

  void _updateState(T customState) {
    _turnBasedGameState = _turnBasedGameState.copyWith(
      customState: customState,
      currentPlayerId: customState.currentPlayerId,
      winner: customState.winner,
      gameStatus: customState.winner != null ? GameStatus.finished : GameStatus.playing,
    );
    if (customState.winner != null) {
      _streamSubscription?.cancel();
    }
  }
  void _updateStateAndAddStream(T customState) {
    _updateState(customState);
    controller.debugLocalAddStream(_turnBasedGameState);
  }
}

class FirestorePoker99Controller {
  /// 遊戲狀態的響應式數據流。
  late final Stream<TurnBasedGameState<Poker99State>?> gameStateStream;

  /// 底層的回合制遊戲控制器。
  late final FirestoreTurnBasedGameController<Poker99State> _gameController;

  /// 測試模式下的 AI 玩家列表
  final List<Poker99AI> _bots = [];
  final Poker99Delegate _delegate;
  late final _BotContext<Poker99State> _botContext;
  StreamSubscription? _gameStateSubscription;
  bool _isBotPlaying = false;

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
          _botContext._updateStateAndAddStream(newState);
        },
      );
      _bots.add(ai);
    }

    _botContext = _BotContext<Poker99State>(
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
    if (_isBotPlaying) {
      _botContext.createRoom();
      _botContext.startGame();
      return;
    }
    _gameController.sendGameAction('request_restart');
  }

  Future<void> startGame() async {
    if ((_gameController.roomStateController.roomStateStream.value?.room?.participants.length ?? 0) <= 1) {
      await leaveRoom();
      _isBotPlaying = true;
      _botContext.createRoom();
      _botContext.startGame();
      return;
    }

    await _gameController.startGame();
  }

  /// 玩家出牌。
  /// [payload] 包含出牌內容與對應的行動 (Poker99Action)。
  Future<void> playCards(Poker99PlayPayload payload) async {
    if (_isBotPlaying) {
      _botContext.sendAction('play_cards', payload: payload.toJson());
      return;
    }
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
    _gameStateSubscription?.cancel();
    _gameController.dispose();
    // 釋放 AI 資源
    for (final bot in _bots) {
      bot.dispose();
    }
  }
}
