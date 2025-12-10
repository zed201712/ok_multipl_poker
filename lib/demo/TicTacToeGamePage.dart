import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_room_state_controller.dart';
import 'package:ok_multipl_poker/services/error_message_service.dart';

import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';


// 1. 定義遊戲狀態物件
class TicTacToeState {
  // 3x3 的遊戲板，'X', 'O', 或 '' (空)
  final List<String> board;
  final String? winner;

  TicTacToeState({required this.board, this.winner});

  // 工廠建構子，用於從 JSON 建立物件
  factory TicTacToeState.fromJson(Map<String, dynamic> json) {
    return TicTacToeState(
      board: List<String>.from(json['board']),
      winner: json['winner'],
    );
  }

  // 將物件轉換為 JSON 的方法
  Map<String, dynamic> toJson() {
    return {
      'board': board,
      'winner': winner,
    };
  }
}


// 2. 實現遊戲規則
class TicTacToeDelegate extends TurnBasedGameDelegate<TicTacToeState> {
  List<String> _playerIds = [];

  // 從 JSON 還原遊戲狀態
  @override
  TicTacToeState stateFromJson(Map<String, dynamic> json) {
    return TicTacToeState.fromJson(json);
  }

  // 將遊戲狀態轉換為 JSON
  @override
  Map<String, dynamic> stateToJson(TicTacToeState state) {
    return state.toJson();
  }

  // 開始新遊戲，回傳初始狀態
  @override
  TicTacToeState initializeGame(List<String> playerIds) {
    _playerIds = playerIds;
    // 建立一個 3x3 的空遊戲板
    return TicTacToeState(board: List.filled(9, ''), winner: null);
  }

  // 處理玩家的動作（例如，下棋）
  @override
  TicTacToeState processAction(TicTacToeState currentState, String actionName,
      String participantId, Map<String, dynamic> payload) {
    // 只有輪到目前玩家才能動作
    if (participantId != getCurrentPlayer(currentState)) {
      return currentState; // 動作無效，回傳原狀態
    }

    if (actionName == 'place_mark') {
      int index = payload['index'] as int;
      // 如果該位置不是空的，則動作無效
      if (currentState.board[index].isNotEmpty) {
        return currentState;
      }

      final newBoard = List<String>.from(currentState.board);
      // 根據玩家順序決定是 'X' 還是 'O'
      final mark = _playerIds.indexOf(participantId) == 0 ? 'X' : 'O';
      newBoard[index] = mark;

      // 檢查是否有贏家... (此處省略檢查邏輯)
      String? winner = _checkWinner(newBoard);

      return TicTacToeState(board: newBoard, winner: winner);
    }
    return currentState;
  }

  // 取得現在輪到的玩家
  @override
  String getCurrentPlayer(TicTacToeState state) {
    if (getWinner(state) != null) return ''; // 遊戲結束
    // 計算 'X' 和 'O' 的數量來決定輪到誰
    int xCount = state.board
        .where((m) => m == 'X')
        .length;
    int oCount = state.board
        .where((m) => m == 'O')
        .length;
    // playerIds 是從 TurnBasedGameDelegate 繼承的
    return xCount > oCount ? _playerIds[1] : _playerIds[0];
  }

  // 取得遊戲狀態 (進行中/已結束)
  @override
  String getGameStatus(TicTacToeState state) {
    return getWinner(state) != null ? 'finished' : 'playing';
  }

  // 取得贏家
  @override
  String? getWinner(TicTacToeState state) {
    return state.winner;
  }

  // (輔助方法，檢查贏家)
  String? _checkWinner(List<String> board) {
    // ... 實作檢查井字遊戲勝利條件的邏輯 ...
    return null; // 暫時回傳 null
  }
}


// 3
class TicTacToeGamePage extends StatefulWidget {
  const TicTacToeGamePage({super.key});

  @override
  State<TicTacToeGamePage> createState() => _TicTacToeGamePageState();
}

class _TicTacToeGamePageState extends State<TicTacToeGamePage> {
  late final FirestoreTurnBasedGameController<TicTacToeState> _gameController;
  late final FirestoreRoomStateController _roomStateController;
  late final ErrorMessageService _errorMessageService;
  bool _isGameMatching = false;
  String _currentRoomId = "";

  @override
  void initState() {
    super.initState();

    // --- 核心整合部分 ---
    // 1. 建立您自訂的 Delegate
    final ticTacToeDelegate = TicTacToeDelegate();
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    _errorMessageService = ErrorMessageService();

    _roomStateController = FirestoreRoomStateController(firestore, auth, 'rooms');

    // 2. 將 Delegate 傳入 Controller 的建構子
    // (假設 _roomStateController 和 _errorMessageService 已經被建立)
    _gameController = FirestoreTurnBasedGameController(
      _roomStateController, // FirestoreRoomStateController 的實例
      ticTacToeDelegate, // 您剛建立的遊戲規則 Delegate
      _errorMessageService, // ErrorMessageService 的實例
    );

  }

  @override
  Widget build(BuildContext context) {
    // 監聽遊戲狀態的變化
    return StreamBuilder<TurnBasedGameState<TicTacToeState>?>(
      stream: _gameController.gameStateStream,
      builder: (context, snapshot) {
        final gameState = snapshot.data;
        if (gameState == null || gameState.gameStatus != GameStatus.playing) {

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 渲染遊戲板 (省略實作細節)
              Center(child: Text(_isGameMatching ? "等待遊戲開始..." : "")),

              ElevatedButton(
              onPressed: () => _isGameMatching ? _leaveRoom() : _matchRoom(),
              child: Text(_isGameMatching ? "離開房間" : "配對"),
              ),
            ],
          );
        }

        final customState = gameState.customState; // 這就是您的 TicTacToeState

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 渲染遊戲板 (省略實作細節)
            Text("輪到: ${gameState.currentPlayerId}"),

            // 玩家點擊遊戲板的格子時，呼叫 sendGameAction
            GestureDetector(
              onTap: () {
                // 假設玩家點擊了第一個格子 (index 0)
                _gameController.sendGameAction(
                    'place_mark',
                    payload: {'index': 0}
                );
              },
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
                child: Center(child: Text(customState.board[0])),
              ),
            ),

            // 只有房主可以看到開始遊戲的按鈕
            ElevatedButton(
              onPressed: () => _gameController.startGame(),
              child: const Text("開始遊戲"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _matchRoom() async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not initialized yet.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Searching for a room...')),
    );

    final roomId = await _gameController.matchAndJoinRoom(maxPlayers: 2);

    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Matched! Joined room: $roomId')),
      );
      setState(() {
        _currentRoomId = roomId;
        _isGameMatching = true;
      });
    }
  }

  Future<void> _leaveRoom() async {
    if (_currentRoomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('_currentRoomId.isEmpty')),
      );
      return;
    }
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not initialized yet.')),
      );
      return;
    }

    await _roomStateController.leaveRoom(roomId: _currentRoomId);

    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('leave room $_currentRoomId')),
      );
      setState(() {
        _currentRoomId = "";
        _isGameMatching = false;
      });
    }
  }

  @override
  void dispose() {
    _gameController.dispose();
    super.dispose();
  }
}