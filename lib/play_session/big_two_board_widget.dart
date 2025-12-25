import 'dart:async';

import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:ok_multipl_poker/play_session/big_two_board_card_area.dart';
import 'package:ok_multipl_poker/widgets/card_container.dart';
import 'package:provider/provider.dart';

import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/game_internals/big_two_delegate.dart';
import 'package:ok_multipl_poker/game_internals/card_player.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/game_internals/big_two_card_pattern.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_big_two_controller.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';
import 'package:ok_multipl_poker/play_session/show_only_card_area_widget.dart';
import 'package:ok_multipl_poker/style/my_button.dart';
import 'package:ok_multipl_poker/play_session/selectable_player_hand_widget.dart';
import 'package:ok_multipl_poker/play_session/debug_text_widget.dart';
import '../entities/big_two_player.dart';
import '../services/error_message_service.dart';
import '../settings/settings.dart';

class BigTwoBoardWidget extends StatefulWidget {
  const BigTwoBoardWidget({super.key});

  @override
  State<BigTwoBoardWidget> createState() => _BigTwoBoardWidgetState();
}

class _BigTwoBoardWidgetState extends State<BigTwoBoardWidget> {
  // 使用 FirestoreBigTwoController
  late final FirestoreBigTwoController _gameController;
  late final StreamSubscription _gameStateStreamSubscription;

  final CardPlayer _player = CardPlayer();
  // 保留本地 Delegate 用於 UI 解析 (myPlayer, otherPlayers)
  final _bigTwoManager = BigTwoDelegate(); 
  late final String _userId;

  final _debugTextController = TextEditingController();
  final _errorMessageServices = ErrorMessageService();

  bool _isMatching = false;

  @override
  void initState() {
    super.initState();

    final auth = context.read<FirebaseAuth>();
    final store = context.read<FirebaseFirestore>();
    final settings = context.read<SettingsController>();

    if (settings.testModeOn.value) {
      _bigTwoManager.setErrorMessageService(_errorMessageServices);
      _errorMessageServices.errorStream.listen((errorMessage) {
        _debugTextController.text = errorMessage;
      });
    }
    
    _userId = auth.currentUser!.uid;
    
    // 初始化 FirestoreBigTwoController
    _gameController = FirestoreBigTwoController(
      firestore: store,
      auth: auth,
      settingsController: settings,
      delegate: _bigTwoManager
    );

    _gameStateStreamSubscription = _gameController.gameStateStream.listen((gameState) {
      final bigTwoState = gameState?.customState;
      if (bigTwoState == null) return;

      // 更新本地玩家 狀態
      final myPlayerState = _bigTwoManager.myPlayer(_userId, bigTwoState);
      _player.name = myPlayerState.name;
      // 將 String 轉回 PlayingCard 供 CardPlayer 使用
      final sortedCards = _bigTwoManager.sortCardsByRank(myPlayerState.cards.map((c) => PlayingCard.fromString(c)).toList());;
      _player.replaceWith(sortedCards);
    });
  }

  @override
  void dispose() {
    _debugTextController.dispose();
    _gameController.dispose();
    _player.dispose();
    _gameStateStreamSubscription.cancel();
    super.dispose();
  }
  
  Future<void> _onMatchRoom() async {
    setState(() {
      _isMatching = true;
    });
    await _gameController.matchRoom();
    // matchRoom 完成後，Stream 應會更新狀態
    if (mounted) {
      setState(() {
        _isMatching = false;
      });
    }
  }

  Future<void> _onStartGame() async {
    await _gameController.startGame();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>(); // watch for changes

    return ChangeNotifierProvider<CardPlayer>(
      create: (_) => _player,
      child: StreamBuilder<TurnBasedGameState<BigTwoState>?>(
        stream: _gameController.gameStateStream,
        builder: (context, snapshot) {
          final gameState = snapshot.data;

          // 若無狀態或不在遊戲中，顯示配對介面
          if (gameState == null || gameState.gameStatus == GameStatus.matching) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isMatching || (gameState?.gameStatus == GameStatus.matching))
                    Text('配對中 / 目前玩家(${_gameController.participantCount()})')
                  else
                    const Text('準備開始大老二'),
                  if (_isMatching || (gameState?.gameStatus == GameStatus.matching))
                    ElevatedButton(
                      onPressed: _onStartGame,
                      child: const Text('開始遊戲'),
                    ),
                  const SizedBox(height: 20),
                  if (!_isMatching && gameState == null)
                    ElevatedButton(
                      onPressed: _onMatchRoom,
                      child: const Text('開始配對 (Match Room)'),
                    ),
                  if (gameState != null && gameState.gameStatus == GameStatus.matching)
                    const CircularProgressIndicator(),
                ],
              ),
            );
          }

          // 遊戲進行中 (Playing) 或 結束 (Finished)
          final bigTwoState = gameState.customState;

          // 1. 取得所有持有的牌型
          final holdingPatterns = _bigTwoManager.getHoldingPatterns(_player.hand);
          
          // 2. 按鈕生成
          // 使用 BigTwoCardPattern Enum 替代硬編碼
          final handTypeButtons = BigTwoCardPattern.values.map((pattern) {
            final isHolding = holdingPatterns.contains(pattern);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: MyButton(
                // 若不持有該牌型，禁用按鈕
                onPressed: isHolding ? () {
                   final nextSelection = _bigTwoManager.selectNextPattern(
                     hand: _player.hand,
                     currentSelection: _player.selectedCards,
                     pattern: pattern, 
                   );
                   if (nextSelection.isNotEmpty) {
                     _player.setCardSelection(nextSelection);
                   }
                } : null,
                child: Text(pattern.displayName),
              ),
            );
          }).toList();

          final otherPlayers = _bigTwoManager.otherPlayers(_userId, bigTwoState);

          // 判斷是否輪到我
          final isMyTurn = gameState.currentPlayerId == _userId;
          return Provider<BigTwoState>.value(
            value: bigTwoState,
            child: Scaffold(
              body: Stack(
                children: [
                  // --- 桌面區域 (Last Played Hand & Deck) ---

                  Transform.translate(
                    offset: const Offset(0, -100),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 100),
                        child: BigTwoBoardCardArea(),
                      ),
                    ),
                  ),

                  // --- 對手區域 ---
                  ..._otherPlayerWidgets(otherPlayers, bigTwoState),

                  // --- 玩家手牌區域 ---
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child:
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 標示自己是否為 Current Player
                            if (isMyTurn)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "YOUR TURN",
                                  style: TextStyle(fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                              ),
                            ChangeNotifierProvider.value(
                              value: _player,
                              child: SelectablePlayerHandWidget(
                                buttonWidgets: handTypeButtons,
                              ),
                            ),

                            // --- 操作按鈕區域 (Play / Pass) ---
                            _functionButtons(bigTwoState),
                          ],
                        )
                    ),
                  ),


                  // --- 狀態提示 ---
                  if (gameState.gameStatus == GameStatus.finished)
                    Center(
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Winner: ${gameState.customState.getParticipantByID(gameState.winner ?? "")?.name ?? gameState.winner}',
                              style: const TextStyle(color: Colors.white, fontSize: 24),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _gameController.restart();
                              },
                              child: const Text('Restart'),
                            ),
                            TextButton(
                              onPressed: () {
                                _gameController.leaveRoom();
                                GoRouter.of(context).go('/');
                              },
                              child: const Text('Leave', style: TextStyle(color: Colors.white)),
                            )
                          ],
                        ),
                      ),
                    ),

                  // --- 除錯工具 ---
                  ..._debugWidgets(bigTwoState),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _debugWidgets(BigTwoState bigTwoState) {
    final settings = context.watch<SettingsController>(); // watch for changes
    return [
    if (settings.testModeOn.value)
      Positioned(
        top: 40,
        left: 20,
        right: 20,
        child: Material(
          type: MaterialType.transparency,
          child: DebugTextWidget(
            controller: _debugTextController,
            onGet: () {
              _debugTextController.text = bigTwoState.toJsonString();
            },
            onSet: (jsonString) {
              try {
                BigTwoState? currentState = _gameController.getCustomGameState();
                if (currentState == null) return;
                final inputState = BigTwoState.fromJsonString(jsonString);
                final newState = currentState.copyWith(
                  lastPlayedHand: inputState.lastPlayedHand,
                  deckCards: inputState.deckCards,
                  lockedHandType: inputState.lockedHandType,
                );
                _gameController.debugSetState(newState);
              } catch (e) {
                // 顯示錯誤提示
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error parsing state: $e')),
                );
              }
            },
          ),
        ),
      ),
    ];
  }
  Widget _functionButtons(BigTwoState bigTwoState) {
    final isMyTurn = bigTwoState.currentPlayerId == _userId;

    return Consumer<CardPlayer>(
      builder: (context, player, _) {
        final selectedCards = player.selectedCards;

        final playButtonEnable =
            isMyTurn &&
                _bigTwoManager.checkPlayValidity(
                  bigTwoState,
                  selectedCards,
                );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pass
            MyButton(
              onPressed: isMyTurn && !bigTwoState.isFirstTurn
                  ? () {
                _gameController.passTurn();
              }
                  : null,
              child: const Text('Pass'),
            ),

            const SizedBox(width: 40),

            // Cancel
            MyButton(
              onPressed: selectedCards.isNotEmpty
                  ? () {
                player.setCardSelection([]);
              }
                  : null,
              child: const Text('Cancel'),
            ),

            const SizedBox(width: 20),

            // Play
            MyButton(
              onPressed: playButtonEnable
                  ? () {
                if (selectedCards.isNotEmpty) {
                  _gameController.playCards(selectedCards);
                  player.setCardSelection([]);
                }
              }
                  : null,
              child: const Text('Play'),
            ),
          ],
        );
        // Positioned(
        //   bottom: 40,
        //   right: 40,
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       passButton,
        //       SizedBox(width: 40),
        //       cancelButton,
        //       SizedBox(width: 20),
        //       playButton
        //     ],
        //   ),
        // );
      },
    );
  }

  // --- 對手區域 ---
  List<Widget> _otherPlayerWidgets(List<BigTwoPlayer> otherPlayers, BigTwoState bigTwoState) {
    List<int> fourPlayerSeatOrder = [
      1, //topCenter
      2, //centerLeft
      0, //centerRight
    ];
    final playersBySeatOrder = (otherPlayers.length == 3) ?
      fourPlayerSeatOrder.map((i)=>otherPlayers[i]).toList() :
      otherPlayers;
    return [
      if (otherPlayers.isNotEmpty)
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 40.0),
            child: _OpponentHand(
              bigTwoState: bigTwoState,
              player: playersBySeatOrder[0],
            ),
          ),
        ),
      if (otherPlayers.length > 1)
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: RotatedBox(
              quarterTurns: 1,
              child: _OpponentHand(
                bigTwoState: bigTwoState,
                player: playersBySeatOrder[1],
              ),
            ),
          ),
        ),
      if (otherPlayers.length > 2)
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: RotatedBox(
              quarterTurns: 3,
              child: _OpponentHand(
                bigTwoState: bigTwoState,
                player: playersBySeatOrder[2],
              ),
            ),
          ),
        ),
    ];
  }
}

class _OpponentHand extends StatelessWidget {
  final BigTwoState bigTwoState;
  final BigTwoPlayer player;

  const _OpponentHand({
    required this.bigTwoState,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardCount = player.cards.length;
    final playerName = player.name;
    final isCurrentTurn = player.uid == bigTwoState.currentPlayerId;

    final playerNameColor = player.hasPassed ? Colors.grey : (isCurrentTurn ? Colors.amber : null);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
            playerName, 
            style: theme.textTheme.titleMedium?.copyWith(
                color: playerNameColor,
                fontWeight: player.hasPassed ? FontWeight.bold : null,
            )
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.style, color: Colors.blueGrey, size: 30),
            const SizedBox(width: 8),
            Text(
              '$cardCount',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
