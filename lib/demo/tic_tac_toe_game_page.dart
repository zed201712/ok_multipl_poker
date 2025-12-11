import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';
import 'package:ok_multipl_poker/multiplayer/mock_firestore_room_state_controller.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';

import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';


// 1. 定義遊戲狀態物件
class TicTacToeState {
  // 3x3 的遊戲板，'X', 'O', 或 '' (空)
  final List<String> board;
  final String? winner;
  final List<String> restartRequesters;

  TicTacToeState({required this.board, this.winner, this.restartRequesters = const []});

  // 工廠建構子，用於從 JSON 建立物件
  factory TicTacToeState.fromJson(Map<String, dynamic> json) {
    return TicTacToeState(
      board: List<String>.from(json['board']),
      winner: json['winner'],
      restartRequesters: json['restartRequesters'] != null ? List<String>.from(json['restartRequesters']) : [],
    );
  }

  // 將物件轉換為 JSON 的方法
  Map<String, dynamic> toJson() {
    return {
      'board': board,
      'winner': winner,
      'restartRequesters': restartRequesters,
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
    return TicTacToeState(board: List.filled(9, ''), winner: null, restartRequesters: []);
  }

  // 處理玩家的動作（例如，下棋）
  @override
  TicTacToeState processAction(TicTacToeState currentState, String actionName,
      String participantId, Map<String, dynamic> payload) {
    if (actionName == 'request_restart') {
      final newRequesters = List<String>.from(currentState.restartRequesters);
      if (!newRequesters.contains(participantId)) {
        newRequesters.add(participantId);
      }

      // 檢查是否所有玩家都已請求重新開始
      if (_playerIds.isNotEmpty && newRequesters.length >= _playerIds.length) {
        return initializeGame(_playerIds); // 重置遊戲
      }

      return TicTacToeState(
        board: currentState.board,
        winner: currentState.winner,
        restartRequesters: newRequesters,
      );
    }

    // 遊戲結束後或非目前玩家，則不處理動作
    if (currentState.winner != null || participantId != getCurrentPlayer(currentState)) {
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

      String? winner = _checkWinner(newBoard);

      return TicTacToeState(
        board: newBoard, 
        winner: winner,
        restartRequesters: currentState.restartRequesters
      );
    }
    return currentState;
  }

  // 取得現在輪到的玩家
  @override
  String getCurrentPlayer(TicTacToeState state) {
    if (getWinner(state) != null) return ''; // 遊戲結束
    // 計算 'X' 和 'O' 的數量來決定輪到誰
    int xCount = state.board.where((m) => m == 'X').length;
    int oCount = state.board.where((m) => m == 'O').length;
    
    return xCount > oCount ? _playerIds[1] : _playerIds[0];
  }

  // 取得贏家
  @override
  String? getWinner(TicTacToeState state) {
    return state.winner;
  }

  // (輔助方法，檢查贏家)
  String? _checkWinner(List<String> board) {
    const List<List<int>> winningLines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // 橫排
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // 豎排
      [0, 4, 8], [2, 4, 6]             // 對角線
    ];

    for (var line in winningLines) {
      final first = board[line[0]];
      if (first.isNotEmpty && first == board[line[1]] && first == board[line[2]]) {
        return first; // 回傳 'X' 或 'O'
      }
    }

    if (!board.contains('')) {
      return 'DRAW';
    }

    return null;
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
  bool _isGameMatching = false;
  String _currentRoomId = "";

  @override
  void initState() {
    super.initState();

    final ticTacToeDelegate = TicTacToeDelegate();
    _gameController = FirestoreTurnBasedGameController(
      delegate: ticTacToeDelegate,
      collectionName: 'rooms'
      //collectionName: 'rooms', controller: MockFirestoreRoomStateController()
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TurnBasedGameState<TicTacToeState>?>(
      stream: _gameController.gameStateStream,
      builder: (context, snapshot) {
        final gameState = snapshot.data;
        
        if (gameState == null || gameState.gameStatus != GameStatus.playing || !_isGameMatching) {
          String message = "歡迎來到井字棋！";
          if (_isGameMatching) {
            message = "等待玩家加入...";
          }
          if (gameState?.gameStatus == GameStatus.finished && gameState?.customState.winner != null) {
              final winner = gameState!.customState.winner;
              message = winner == 'DRAW' ? '平手！' : '贏家是 $winner！';
          }
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(child: Text(message)),
              ElevatedButton(
                onPressed: () => _isGameMatching ? _leaveRoom() : _matchRoom(),
                child: Text(_isGameMatching ? "離開房間" : "配對"),
              ),

              if (gameState != null && gameState.gameStatus == GameStatus.finished) ..._resetBox(
                  gameState.customState),
            ],
          );
        }

        final customState = gameState.customState;
        final isMyTurn = gameState.currentPlayerId == _gameController.roomStateController.currentUserId;
        final winner = customState.winner;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (winner != null)
              Text(winner == 'DRAW' ? '遊戲結束: 平手' : "贏家是: $winner", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),)
            else
              Text("輪到: ${isMyTurn ? '你' : '對手'}", style: const TextStyle(fontSize: 20)),
            
            const SizedBox(height: 20),

            AbsorbPointer(
              absorbing: !isMyTurn || winner != null,
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, i) {
                      return GestureDetector(
                        onTap: () {
                          _gameController.sendGameAction(
                              'place_mark',
                              payload: {'index': i}
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                          ),
                          child: Center(
                            child: Text(
                              customState.board[i],
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_gameController.isCurrentUserManager() && gameState.gameStatus != GameStatus.playing)
              ElevatedButton(
                onPressed: () => _gameController.startGame(),
                child: const Text("開始遊戲"),
              ),
            ElevatedButton(
              onPressed: () => _leaveRoom(),
              child: Text("離開房間"),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _resetBox(TicTacToeState customState) {
    return [
      const SizedBox(height: 20),
      Text("請求重新開始的玩家:"),
      Text(
        customState.restartRequesters.isEmpty
            ? "尚無"
            : customState.restartRequesters.join(', '),
      ),
      if (!customState.restartRequesters
          .contains(_gameController.roomStateController.currentUserId))
        ElevatedButton(
          onPressed: () =>
              _gameController.sendGameAction('request_restart'),
          child: Text("重新開始"),
        ),
    ];
  }

  Future<void> _matchRoom() async {
    if (_gameController.roomStateController.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not initialized yet.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在尋找房間...')),
    );

    final roomId = await _gameController.matchAndJoinRoom(maxPlayers: 2);

    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('配對成功！已加入房間: $roomId')),
      );
      setState(() {
        _currentRoomId = roomId;
        _isGameMatching = true;
      });
    }
  }

  Future<void> _leaveRoom() async {
    if (_currentRoomId.isEmpty) return;
    
    await _gameController.leaveRoom();

    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已離開房間 $_currentRoomId')),
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
