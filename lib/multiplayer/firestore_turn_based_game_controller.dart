import 'dart:async';
import 'dart:convert';

import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/entities/room_request.dart';
import 'package:ok_multipl_poker/entities/room_state.dart';
import 'package:rxdart/rxdart.dart';

import 'firestore_room_state_controller.dart';
import 'turn_based_game_delegate.dart';
import 'turn_based_game_state.dart';

class FirestoreTurnBasedGameController<T> {
  final FirestoreRoomStateController _roomStateController;
  final TurnBasedGameDelegate<T> _delegate;

  final _gameStateController = BehaviorSubject<TurnBasedGameState<T>?>.seeded(null);
  StreamSubscription? _roomStateSubscription;

  FirestoreTurnBasedGameController(
    this._roomStateController,
    this._delegate,
  ) {
    _roomStateSubscription = _roomStateController.roomStateStream.listen(_onRoomStateChanged);
  }

  ValueStream<TurnBasedGameState<T>?> get gameStateStream => _gameStateController.stream;

  void _onRoomStateChanged(RoomState? roomState) {
    if (roomState?.room == null || roomState!.room!.body.isEmpty) {
      _gameStateController.add(null);
      return;
    }

    final room = roomState.room!;
    final TurnBasedGameState<T> gameState = _parseGameState(room.body);
    _gameStateController.add(gameState);

    // Only the manager processes requests.
    if (_roomStateController.currentUserId == room.managerUid) {
      _processRequests(gameState, roomState.requests);
    }
  }

  void _processRequests(TurnBasedGameState<T> currentState, List<RoomRequest> requests) {
    for (final request in requests) {
      final action = request.body['action'];
      if (action == 'start_game') {
        _handleStartGame(request);
      } else if (action == 'game_action') {
        _handleGameAction(currentState, request);
      }      // Clean up processed request
      _roomStateController.deleteRequest(roomId: request.roomId, requestId: request.requestId);
    }
  }

  void _handleStartGame(RoomRequest request) {
    final room = _roomStateController.roomStateStream.value?.room;
    if (room == null) return;

    final initialCustomState = _delegate.initializeGame(room.participants);
    final newGameState = TurnBasedGameState(
      gameStatus: _delegate.getGameStatus(initialCustomState),
      turnOrder: room.participants,
      currentPlayerId: _delegate.getCurrentPlayer(initialCustomState),
      winner: null,
      customState: initialCustomState,
    );

    _updateRoomWithState(newGameState);
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
    
    final newGameState = currentState.copyWith(
        gameStatus: _delegate.getGameStatus(updatedCustomState),
        currentPlayerId: _delegate.getCurrentPlayer(updatedCustomState),
        winner: _delegate.getWinner(updatedCustomState),
        customState: updatedCustomState
    );

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

  // --- Public Methods ---

  Future<String> matchAndJoinRoom() {
    return _roomStateController.matchRoom(
      title: 'Turn Based Game',
      maxPlayers: 2,
      matchMode: 'turn_based',
      visibility: 'public',
    );
  }
  
  void setRoomId(String roomId) {
      _roomStateController.setRoomId(roomId);
  }

  Future<void> leaveRoom() {
    final roomId = _roomStateController.roomStateStream.value?.room?.roomId;
    if (roomId != null) {
      return _roomStateController.leaveRoom(roomId: roomId);
    }
    return Future.value();
  }

  Future<void> startGame() {
    final roomId = _roomStateController.roomStateStream.value?.room?.roomId;
    if (roomId == null) throw Exception("Not in a room");
    return _roomStateController.sendRequest(roomId: roomId, body: {'action': 'start_game'});
  }

  Future<void> sendGameAction(String action, {Map<String, dynamic>? payload}) {
    final roomId = _roomStateController.roomStateStream.value?.room?.roomId;
    if (roomId == null) throw Exception("Not in a room");
    return _roomStateController.sendRequest(
      roomId: roomId,
      body: {
        'action': 'game_action',
        'name': action,
        'payload': payload ?? {},
      },
    );
  }

  void dispose() {
    _roomStateSubscription?.cancel();
    _gameStateController.close();
  }
}
