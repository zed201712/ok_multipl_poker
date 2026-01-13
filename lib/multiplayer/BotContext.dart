

import 'dart:async';
import 'dart:math';

import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';

import '../entities/participant_info.dart';
import '../entities/room.dart';
import '../entities/room_state.dart';
import 'firestore_turn_based_game_controller.dart';
import 'game_status.dart';

class BotContext<T extends TurnBasedCustomState> {
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

  BotContext({
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
    updateStateAndAddStream(newState);
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
  }
  void updateStateAndAddStream(T customState) {
    _updateState(customState);
    controller.debugLocalAddStream(_turnBasedGameState);
  }
}
