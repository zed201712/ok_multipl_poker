import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/entities/room_request.dart';
import 'package:ok_multipl_poker/entities/room_state.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';
import 'package:ok_multipl_poker/services/error_message_service.dart';
import 'package:rxdart/rxdart.dart';

import '../settings/settings.dart';
import 'firestore_room_state_controller.dart';
import 'turn_based_game_delegate.dart';
import 'turn_based_game_state.dart';

class FirestoreTurnBasedGameController<T> {
  final TurnBasedGameDelegate<T> _delegate;

  late final FirestoreRoomStateController roomStateController;
  final ErrorMessageService errorMessageService = ErrorMessageService();

  Room? _currentRoom;
  int _maxPlayers = 0;

  final _gameStateController = BehaviorSubject<TurnBasedGameState<T>?>.seeded(null);
  StreamSubscription? _roomStateSubscription;

  FirestoreTurnBasedGameController({
    required FirebaseAuth auth,
    required FirebaseFirestore store,
    required TurnBasedGameDelegate<T> delegate,
    required String collectionName,
    required SettingsController settingsController,
  }) : _delegate = delegate {
      roomStateController = FirestoreRoomStateController(store, auth, collectionName, settingsController);

    _roomStateSubscription = roomStateController.roomStateStream.listen(_onRoomStateChanged);
  }

  ValueStream<TurnBasedGameState<T>?> get gameStateStream => _gameStateController.stream;

  bool isCurrentUserManager() {
    if (_currentRoom == null) return false;
    return _isCurrentUserTheManager(_currentRoom!);
  }

  bool _isCurrentUserTheManager(Room room) {
    return roomStateController.currentUserId == room.managerUid;
  }

  void _onRoomStateChanged(RoomState? roomState) {
    _currentRoom = roomState?.room;
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
        errorMessageService.showError("Failed to parse game state: $e");
        _gameStateController.add(null);
      }
    } else {
      if (_isCurrentUserTheManager(room)) {
        final initialCustomState = _delegate.initializeGame(room);
        final newGameState = TurnBasedGameState(
          gameStatus: GameStatus.matching,
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
        _handleStartGame(room, null);
        return;
      }
      _processRequests(room, gameState, roomState.requests);
    }
  }

  void _processRequests(Room room, TurnBasedGameState<T>? currentState, List<RoomRequest> requests) {
    for (final request in requests) {
      final action = request.body['action'];
      if (action == 'start_game') {
        if (currentState?.gameStatus == GameStatus.matching) {
          _handleStartGame(room, request);
        }
      } else if (action == 'game_action') {
        if (currentState != null) {
          _handleGameAction(currentState, request);
        }
      }
      roomStateController.deleteRequest(roomId: request.roomId, requestId: request.requestId);
    }
  }

  void _handleStartGame(Room room, RoomRequest? request) {
    final room = roomStateController.roomStateStream.value?.room;
    if (room == null) return;

    final initialCustomState = _delegate.initializeGame(room);
    final newGameState = TurnBasedGameState(
      gameStatus: GameStatus.playing,
      currentPlayerId: _delegate.getCurrentPlayer(initialCustomState),
      winner: null,
      customState: initialCustomState,
    );

    _updateRoomWithState(newGameState);

    if (request == null) {
        final pendingRequests = roomStateController.roomStateStream.value?.requests ?? [];
        final roomId = room.roomId;
        for (final req in pendingRequests) {
            if (req.body['action'] == 'start_game') {
                roomStateController.deleteRequest(roomId: roomId, requestId: req.requestId);
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

  Future<void> _updateRoomWithState(TurnBasedGameState<T> gameState) async {
    final room = roomStateController.roomStateStream.value?.room;
    if (room == null) return;

    final serializedState = jsonEncode(gameState.toJson(_delegate));
    await roomStateController.updateRoom(roomId: room.roomId, data: {'body': serializedState});
  }

  TurnBasedGameState<T> _parseGameState(String body) {
    final decodedBody = jsonDecode(body) as Map<String, dynamic>;
    return TurnBasedGameState.fromJson(decodedBody, _delegate);
  }

  Future<String> matchAndJoinRoom({
    required int maxPlayers,
    bool randomizeSeats = true
  }) async {
    _maxPlayers = maxPlayers;
    try {
      return await roomStateController.matchRoom(
        title: 'Turn Based Game',
        maxPlayers: maxPlayers,
        matchMode: 'turn_based',
        visibility: 'public',
        randomizeSeats: randomizeSeats,
      );
    } catch (e) {
      errorMessageService.showError("Failed to match room: $e");
      rethrow;
    }
  }

  void setRoomId(String roomId) {
    roomStateController.setRoomId(roomId);
  }

  Future<void> leaveRoom() async {
    final roomId = roomStateController.roomStateStream.value?.room?.roomId;
    if (roomId != null) {
      try {
        await roomStateController.leaveRoom(roomId: roomId);
      } catch (e) {
        errorMessageService.showError("Failed to leave room: $e");
      }
    }
  }

  Future<void> startGame() async {
    final roomId = roomStateController.roomStateStream.value?.room?.roomId;
    if (roomId == null) {
      errorMessageService.showError("You are not currently in a room");
      return;
    }
    try {
      await roomStateController.sendRequest(roomId: roomId, body: {'action': 'start_game'});
    } catch (e) {
      errorMessageService.showError("Failed to send request: $e");
    }
  }

  Future<void> sendGameAction(String action, {Map<String, dynamic>? payload}) async {
    final roomId = roomStateController.roomStateStream.value?.room?.roomId;
    if (roomId == null) {
      errorMessageService.showError("You are not currently in a room");
      return;
    }
    try {
      await roomStateController.sendRequest(
        roomId: roomId,
        body: {
          'action': 'game_action',
          'name': action,
          'payload': payload ?? {},
        },
      );
    } catch (e) {
      errorMessageService.showError("Failed to send game action: $e");
    }
  }

  void dispose() {
    roomStateController.dispose();
    _roomStateSubscription?.cancel();
    _gameStateController.close();
    errorMessageService.dispose();
  }
}
