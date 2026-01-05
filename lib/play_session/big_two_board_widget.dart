import 'dart:async';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:ok_multipl_poker/play_session/big_two_board_card_area.dart';
import 'package:ok_multipl_poker/widgets/card_container.dart';
import 'package:ok_multipl_poker/widgets/player_avatar_widget.dart';
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
import '../style/palette.dart';

class BigTwoBoardWidget extends StatefulWidget {
  // 定義設計解析度 (Design Resolution)
  // 選擇一個較為修長的比例以適應現代手機，例如 iPhone 11 Pro Max / Pixel 的邏輯解析度範圍
  static const Size designSize = Size(896, 414);
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
      if (myPlayerState == null) return;

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
                    Text('game.matching_status'.tr(args: [_gameController.participantCount().toString()]))
                  else
                    Text('ready'.tr()),
                  if (_isMatching || (gameState?.gameStatus == GameStatus.matching))
                    ElevatedButton(
                      onPressed: _onStartGame,
                      child: Text('start'.tr()),
                    ),
                  const SizedBox(height: 20),
                  if (!_isMatching && gameState == null)
                    ElevatedButton(
                      onPressed: _onMatchRoom,
                      child: Text('match_room'.tr()),
                    ),

                  const SizedBox(height: 20),
                  _leaveButton(),
                  const SizedBox(height: 20),

                  if (gameState != null && gameState.gameStatus == GameStatus.matching)
                    const CircularProgressIndicator(),
                ],
              ),
            );
          }

          // 遊戲進行中 (Playing) 或 結束 (Finished)
          final bigTwoState = gameState.customState;

          // 1. 判斷是否輪到我
          final isMyTurn = gameState.currentPlayerId == _userId;
          
          // 2. 按鈕生成
          // 使用 BigTwoCardPattern Enum 替代硬編碼
          final handTypeButtons = BigTwoCardPattern.values.map((pattern) {
            final isEnable = isMyTurn && _selectNextPattern(bigTwoState, pattern).isNotEmpty;;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: MyButton(
                // 若不持有該牌型，禁用按鈕
                onPressed: isEnable ? () {
                  final nextSelection = _selectNextPattern(bigTwoState, pattern);
                   if (nextSelection.isNotEmpty) {
                     _player.setCardSelection(nextSelection);
                   }
                } : null,
                child: Text('patterns.${pattern.name}'.tr()),
              ),
            );
          }).toList();

          final otherPlayers = _bigTwoManager.otherPlayers(_userId, bigTwoState);

          return Provider<BigTwoState>.value(
            value: bigTwoState,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: BigTwoBoardWidget.designSize.width,
                    height: BigTwoBoardWidget.designSize.height,
                    child: Column(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: Row(
                              spacing: 30,
                              children: [
                                const Expanded(child: SizedBox.shrink()),

                                _buildLeftOpponent(otherPlayers, bigTwoState),
                                _buildTopOpponent(otherPlayers, bigTwoState),
                                _buildRightOpponent(otherPlayers, bigTwoState),

                                const Expanded(child: SizedBox.shrink()),
                              ],
                            )
                          ),
                        ),

                        Expanded(
                          flex: 10,
                          child: Row(
                            children: [
                              // Left Opponent (20%)
                              SizedBox(width: BigTwoBoardWidget.designSize.width * 0.1,),

                              // Table Card Area (Center)
                              Expanded(
                                child: Center(
                                  child: BigTwoBoardCardArea(),
                                ),
                              ),

                              // Right Opponent (20%)
                              SizedBox(width: BigTwoBoardWidget.designSize.width * 0.1,),
                            ],
                          ),
                        ),

                        Expanded(
                          flex: 14,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // 標示自己是否為 Current Player
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PlayerAvatarWidget(
                                    avatarNumber: settings.playerAvatarNumber.value,
                                    size: 30, // Adjust size as needed
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 2),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isMyTurn ? Colors.amber : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "your_turn".tr(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isMyTurn ? Colors.black : Colors.transparent,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 20),
                                  // --- 操作按鈕區域 (Play / Pass) ---
                                  _functionButtons(bigTwoState),
                                ],
                              ),

                              ChangeNotifierProvider.value(
                                value: _player,
                                child: SelectablePlayerHandWidget(
                                  buttonWidgets: handTypeButtons,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Use Overlay or a separate top-level Stack for overlays like "Winner" or Debug tools
              // For now, simple overlays can be added here if needed, but keeping the main game logic inside the Grid.
              floatingActionButton: gameState.gameStatus == GameStatus.finished
                  ? Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'game.winner_status'.tr(args: [
                              gameState.customState.getParticipantByID(gameState.winner ?? "")?.name ?? gameState.winner ?? "",
                              bigTwoState.restartRequesters.length.toString(),
                              bigTwoState.participants.length.toString()
                            ]),
                            style: const TextStyle(color: Colors.white, fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _gameController.restart();
                            },
                            child: Text('game.restart'.tr()),
                          ),
                          _leaveButton()
                        ],
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  // --- Helper Methods to map opponents to positions ---
  
  // Note: The logic for mapping otherPlayers list to specific positions depends on 
  // how _bigTwoManager.otherPlayers returns the list (ordered by turn order or seat).
  // Assuming otherPlayers[0] is Top, [1] is Left, [2] is Right is NOT always correct 
  // without consistent rotation logic.
  // Below we use the same index logic as previous Stack implementation for consistency.
  // previous logic: 
  // 1 player -> Top
  // 2 players -> Top, Left
  // 3 players -> Top, Left, Right
  // (Based on: 
  //   List<int> fourPlayerSeatOrder = [1, 2, 0]; 
  //   playersBySeatOrder[0] -> Top
  //   playersBySeatOrder[1] -> Left
  //   playersBySeatOrder[2] -> Right
  // )

  List<BigTwoPlayer> _getOrderedOpponents(List<BigTwoPlayer> otherPlayers) {
     if (otherPlayers.isEmpty) return [];
     
     // Reuse the logic from previous _otherPlayerWidgets to maintain consistency
     // The previous code had a specific mapping for 3 opponents.
     // If fewer, it just took them in order.
     
     List<int> fourPlayerSeatOrder = [1, 2, 0];
     if (otherPlayers.length == 3) {
       return fourPlayerSeatOrder.map((i) => otherPlayers[i]).toList();
     }
     return otherPlayers;
  }

  Widget _buildTopOpponent(List<BigTwoPlayer> otherPlayers, BigTwoState bigTwoState) {
    final ordered = _getOrderedOpponents(otherPlayers);
    if (ordered.isNotEmpty) {
      return _OpponentHand(bigTwoState: bigTwoState, player: ordered[0]);
    }
    return const SizedBox();
  }

  Widget _buildLeftOpponent(List<BigTwoPlayer> otherPlayers, BigTwoState bigTwoState) {
    final ordered = _getOrderedOpponents(otherPlayers);
    if (ordered.length > 1) {
       // Left player was rotated in Stack layout. In Grid, we can keep it vertical or standard.
       // Let's keep the rotation for visual consistency with "sides".
      return _OpponentHand(bigTwoState: bigTwoState, player: ordered[1]);
    }
    return const SizedBox();
  }

  Widget _buildRightOpponent(List<BigTwoPlayer> otherPlayers, BigTwoState bigTwoState) {
    final ordered = _getOrderedOpponents(otherPlayers);
    if (ordered.length > 2) {
      return _OpponentHand(bigTwoState: bigTwoState, player: ordered[2]);
    }
    return const SizedBox();
  }


  Widget _leaveButton() {
    return ElevatedButton(
      onPressed: () {
        _gameController.leaveRoom();
        GoRouter.of(context).go('/');
      },
      child: Text('leave'.tr(), style: TextStyle(color: Palette().ink)),
    );
  }

  List<PlayingCard> _selectNextPattern(
      BigTwoState bigTwoState,
      BigTwoCardPattern pattern,
      ) {
    return _bigTwoManager.selectNextPattern(
      bigTwoState: bigTwoState,
      hand: _player.hand,
      currentSelection: _player.selectedCards,
      pattern: pattern,
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
              child: Text('pass'.tr()),
            ),

            const SizedBox(width: 40),

            // Cancel
            MyButton(
              onPressed: selectedCards.isNotEmpty
                  ? () {
                player.setCardSelection([]);
              }
                  : null,
              child: Text('cancel'.tr()),
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
              child: Text('play_action'.tr()),
            ),
          ],
        );
      },
    );
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
    final hasPassed = player.hasPassed;

    final Color backgroundColor = hasPassed
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.55);

    final Color nameColor = hasPassed
        ? Colors.grey.shade400
        : (isCurrentTurn ? Colors.amberAccent : Colors.white);

    final Color countColor = hasPassed
        ? Colors.grey.shade300
        : Colors.white;

    final Color iconColor = hasPassed
        ? Colors.grey.shade500
        : Colors.blueGrey.shade200;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: CardContainer(
        color: backgroundColor,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            PlayerAvatarWidget(
              avatarNumber: player.avatarNumber,
              size: 30,
            ),

            const SizedBox(width: 8),

            // Name + Card Count
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Player name
                Text(
                  playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: nameColor,
                    fontWeight:
                    hasPassed ? FontWeight.w500 : FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 6),

                // Card count
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.style,
                      color: iconColor,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$cardCount',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: countColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
