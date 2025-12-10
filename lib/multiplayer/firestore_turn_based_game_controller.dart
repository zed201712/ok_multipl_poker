import 'dart:async';
import 'dart:convert';

import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/entities/room_request.dart';
import 'package:ok_multipl_poker/entities/room_state.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';
import 'package:ok_multipl_poker/services/error_message_service.dart';
import 'package:rxdart/rxdart.dart';

import 'firestore_room_state_controller.dart';
import 'turn_based_game_delegate.dart';
import 'turn_based_game_state.dart';

class FirestoreTurnBasedGameController<T> {
  final FirestoreRoomStateController _roomStateController;
  final TurnBasedGameDelegate<T> _delegate;
  final ErrorMessageService _errorMessageService;

  int _maxPlayers = 0;

  final _gameStateController = BehaviorSubject<TurnBasedGameState<T>?>.seeded(null);
  StreamSubscription? _roomStateSubscription;

  FirestoreTurnBasedGameController(
    this._roomStateController,
    this._delegate,
    this._errorMessageService,
  ) {
    _roomStateSubscription = _roomStateController.roomStateStream.listen(_onRoomStateChanged);
  }

  ValueStream<TurnBasedGameState<T>?> get gameStateStream => _gameStateController.stream;

  bool _isCurrentUserTheManager(Room room) {
    return _roomStateController.currentUserId == room.managerUid;
  }

  void _onRoomStateChanged(RoomState? roomState) {
    if (roomState == null || roomState.room == null) {
      _gameStateController.add(null);
      return;
    }

    final room = roomState.room!;
    TurnBasedGameState<T>? gameState;

    if (room.body.isNotEmpty) {
      try {
        gameState = _parseGameState(room.body);
        _gameStateController.add(gameState);
      } catch (e) {
        _errorMessageService.showError("Failed to parse game state: $e");
        _gameStateController.add(null);
      }
    } else {
      if (_isCurrentUserTheManager(room)) {
        final initialCustomState = _delegate.initializeGame([]);
        final newGameState = TurnBasedGameState(
          gameStatus: GameStatus.matching,
          turnOrder: [],
          customState: initialCustomState,
        );
        _updateRoomWithState(newGameState);
        return; 
      }
      _gameStateController.add(null);
    }

    if (_isCurrentUserTheManager(room)) {
      if (gameState?.gameStatus == GameStatus.matching &&
          room.participants.length >= _maxPlayers &&
          _maxPlayers > 0) {
        _handleStartGame(null);
        return;
      }
      _processRequests(gameState, roomState.requests);
    }
  }

  void _processRequests(TurnBasedGameState<T>? currentState, List<RoomRequest> requests) {
    for (final request in requests) {
      final action = request.body['action'];
      if (action == 'start_game') {
        if (currentState?.gameStatus == GameStatus.matching) {
          _handleStartGame(request);
        }
      } else if (action == 'game_action') {
        if (currentState != null && currentState.gameStatus == GameStatus.playing) {
          _handleGameAction(currentState, request);
        }
      }
      _roomStateController.deleteRequest(roomId: request.roomId, requestId: request.requestId);
    }
  }

  void _handleStartGame(RoomRequest? request) {
    final room = _roomStateController.roomStateStream.value?.room;
    if (room == null) return;

    List<String> turnOrder = List.from(room.participants);
    turnOrder.shuffle();
    final initialCustomState = _delegate.initializeGame(turnOrder);
    final newGameState = TurnBasedGameState(
      gameStatus: GameStatus.playing,
      turnOrder: turnOrder,
      currentPlayerId: _delegate.getCurrentPlayer(initialCustomState),
      winner: null,
      customState: initialCustomState,
    );

    _updateRoomWithState(newGameState);
    
    if (request == null) {
        final pendingRequests = _roomStateController.roomStateStream.value?.requests ?? [];
        final roomId = room.roomId;
        for (final req in pendingRequests) {
            if (req.body['action'] == 'start_game') {
                _roomStateController.deleteRequest(roomId: roomId, requestId: req.requestId);
            }
        }
    }
  }

  void _handleGameAction(TurnBasedGameState<T> currentState, RoomRequest request) {
    final actionName = request.body['name'] as String;
    final payload = request.body['payload'] as Map<String, dynamic>;

    final updatedCustomState = _delegate.processAction(
      currentState.customState,
      actionName,
      request.participantId,
      payload,
    );

    final winner = _delegate.getWinner(updatedCustomState);
    final newStatus = winner != null ? GameStatus.finished : GameStatus.playing;

    final newGameState = currentState.copyWith(
        gameStatus: newStatus,
        currentPlayerId: _delegate.getCurrentPlayer(updatedCustomState),
        winner: winner,
        customState: updatedCustomState);

    _updateRoomWithState(newGameState);
  }

  void _updateRoomWithState(TurnBasedGameState<T> gameState) {
    final room = _roomStateController.roomStateStream.value?.room;
    if (room == null) return;

    final serializedState = jsonEncode(gameState.toJson(_delegate));
    _roomStateController.updateRoom(roomId: room.roomId, data: {'body': serializedState});
  }

  TurnBasedGameState<T> _parseGameState(String body) {
    final decodedBody = jsonDecode(body) as Map<String, dynamic>;
    return TurnBasedGameState.fromJson(decodedBody, _delegate);
  }

  Future<String> matchAndJoinRoom({required int maxPlayers}) async {
    _maxPlayers = maxPlayers;
    try {
      return await _roomStateController.matchRoom(
        title: 'Turn Based Game',
        maxPlayers: maxPlayers,
        matchMode: 'turn_based',
        visibility: 'public',
      );
    } catch (e) {
      _errorMessageService.showError("Failed to match room: $e");
      rethrow;
    }
  }

  void setRoomId(String roomId) {
    _roomStateController.setRoomId(roomId);
  }

  Future<void> leaveRoom() async {
    final roomId = _roomStateController.roomStateStream.value?.room?.roomId;
    if (roomId != null) {
      try {
        await _roomStateController.leaveRoom(roomId: roomId);
      } catch (e) {
        _errorMessageService.showError("Failed to leave room: $e");
      }
    }
  }

  Future<void> startGame() async {
    final roomId = _roomStateController.roomStateStream.value?.room?.roomId;
    if (roomId == null) {
      _errorMessageService.showError("You are not currently in a room");
      return;
    }
    try {
      await _roomStateController.sendRequest(roomId: roomId, body: {'action': 'start_game'});
    } catch (e) {
      _errorMessageService.showError("Failed to send request: $e");
    }
  }

  Future<void> sendGameAction(String action, {Map<String, dynamic>? payload}) async {
    final roomId = _roomStateController.roomStateStream.value?.room?.roomId;
    if (roomId == null) {
      _errorMessageService.showError("You are not currently in a room");
      return;
    }
    try {
      await _roomStateController.sendRequest(
        roomId: roomId,
        body: {
          'action': 'game_action',
          'name': action,
          'payload': payload ?? {},
        },
      );
    } catch (e) {
      _errorMessageService.showError("Failed to send game action: $e");
    }
  }

  void dispose() {
    _roomStateSubscription?.cancel();
    _gameStateController.close();
  }
}
