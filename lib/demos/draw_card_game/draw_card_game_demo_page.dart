import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/demos/draw_card_game/draw_card_game_delegate.dart';
import 'package:ok_multipl_poker/demos/draw_card_game/draw_card_game_state.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_room_state_controller.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/services/error_message_service.dart';
import 'package:ok_multipl_poker/widgets/error_overlay_widget.dart';

class DrawCardGameDemoPage extends StatefulWidget {
  const DrawCardGameDemoPage({super.key});

  @override
  State<DrawCardGameDemoPage> createState() => _DrawCardGameDemoPageState();
}

class _DrawCardGameDemoPageState extends State<DrawCardGameDemoPage> {
  late final ErrorMessageService _errorMessageService;
  late final FirestoreRoomStateController _roomStateController;
  late final FirestoreTurnBasedGameController<DrawCardGameState> _gameController;
  String? _roomId;

  @override
  void initState() {
    super.initState();
    // In a real app, these would be provided by a dependency injection framework.
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    _errorMessageService = ErrorMessageService();

    _roomStateController = FirestoreRoomStateController(firestore, auth, 'rooms');
    _gameController = FirestoreTurnBasedGameController(
      _roomStateController,
      DrawCardGameDelegate(),
      _errorMessageService,
    );
  }

  @override
  void dispose() {
    _gameController.dispose();
    _roomStateController.dispose();
    _errorMessageService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw Card Game Demo'),
        actions: [
          TextButton(onPressed: _gameController.leaveRoom, child: const Text('Leave Room'))
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<TurnBasedGameState<DrawCardGameState>?>(
            stream: _gameController.gameStateStream,
            builder: (context, snapshot) {
              final gameState = snapshot.data;

              if (_roomId == null) {
                return _buildMatchRoomView();
              }

              if (gameState == null) {
                return _buildWaitingForGameView();
              }

              return _buildGameView(gameState);
            },
          ),
          ErrorOverlayWidget(errorMessageService: _errorMessageService),
        ],
      ),
    );
  }

  Widget _buildMatchRoomView() {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          final roomId = await _gameController.matchAndJoinRoom(maxPlayers: 2);
          setState(() {
            _roomId = roomId;
          });
          _gameController.setRoomId(roomId);
        },
        child: const Text('Match and Join Room'),
      ),
    );
  }

  Widget _buildWaitingForGameView() {
    final roomState = _roomStateController.roomStateStream.value;
    final isManager = roomState?.room?.managerUid == _roomStateController.currentUserId;
    final participants = roomState?.room?.participants ?? [];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Waiting for players...'),
          Text('Room ID: ${_roomId}'),
          Text('Players: ${participants.join(', ')}'),
          if (isManager)
            ElevatedButton(
              onPressed: _gameController.startGame,
              child: const Text('Start Game'),
            ),
        ],
      ),
    );
  }

  Widget _buildGameView(TurnBasedGameState<DrawCardGameState> gameState) {
    final myId = _roomStateController.currentUserId;
    final isMyTurn = gameState.currentPlayerId == myId;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Game Status: ${gameState.gameStatus}', style: Theme.of(context).textTheme.headlineSmall),
          if (gameState.winner != null) ...[
            Text('Winner: ${gameState.winner}', style: Theme.of(context).textTheme.headlineMedium),
          ] else ...[
            Text('Current Player: ${gameState.currentPlayerId}'),
          ],
          const SizedBox(height: 20),
          ...gameState.customState.playerCards.entries.map((entry) {
            final playerId = entry.key;
            final card = entry.value;
            return ListTile(
              title: Text('Player: $playerId'),
              trailing: Text(card?.toString() ?? 'No card drawn', style: Theme.of(context).textTheme.bodyLarge),
            );
          }),
          const Spacer(),
          if (isMyTurn && gameState.gameStatus == 'playing')
            Center(
              child: ElevatedButton(
                onPressed: () => _gameController.sendGameAction('draw_card'),
                child: const Text('Draw a Card'),
              ),
            ),
        ],
      ),
    );
  }
}
