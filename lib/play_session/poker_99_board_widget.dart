import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:ok_multipl_poker/entities/poker_99_play_payload.dart';
import 'package:ok_multipl_poker/game_internals/poker_99_action.dart';
import 'package:ok_multipl_poker/game_internals/poker_99_delegate.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_poker_99_controller.dart';
import 'package:ok_multipl_poker/widgets/card_container.dart';
import 'package:ok_multipl_poker/widgets/player_avatar_widget.dart';
import 'package:provider/provider.dart';

import 'package:ok_multipl_poker/entities/poker_99_state.dart';
import 'package:ok_multipl_poker/game_internals/card_player.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';
import 'package:ok_multipl_poker/style/my_button.dart';
import 'package:ok_multipl_poker/play_session/selectable_player_hand_widget.dart';
import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../entities/poker_player.dart';
import '../game_internals/card_suit.dart';
import '../services/error_message_service.dart';
import '../settings/settings.dart';
import '../style/confetti.dart';
import '../style/palette.dart';

class Poker99BoardWidget extends StatefulWidget {
  // 定義設計解析度 (Design Resolution)
  static const Size designSize = Size(896, 414);
  const Poker99BoardWidget({super.key});

  @override
  State<Poker99BoardWidget> createState() => _Poker99BoardWidgetState();
}

class _Poker99BoardWidgetState extends State<Poker99BoardWidget> {
  // 使用 FirestorePoker99Controller
  late final FirestorePoker99Controller _gameController;
  late final StreamSubscription _gameStateStreamSubscription;

  final CardPlayer _player = CardPlayer();
  // 保留本地 Delegate 用於 UI 解析 (myPlayer, otherPlayers)
  final _poker99Manager = Poker99Delegate();
  late final String _userId;

  final _debugTextController = TextEditingController();
  final _errorMessageServices = ErrorMessageService();

  static const _celebrationDuration = Duration(milliseconds: 2000);
  static const _preCelebrationDuration = Duration(milliseconds: 500);
  bool _duringCelebration = false;
  GameStatus _previousGameStatus = GameStatus.idle;

  _LocalMatchStatus _localMatchStatus = _LocalMatchStatus.idle;

  @override
  void initState() {
    super.initState();

    final auth = context.read<FirebaseAuth>();
    final store = context.read<FirebaseFirestore>();
    final settings = context.read<SettingsController>();

    if (settings.testModeOn.value) {
      _poker99Manager.setErrorMessageService(_errorMessageServices);
      _errorMessageServices.errorStream.listen((errorMessage) {
        _debugTextController.text = errorMessage;
      });
    }

    _userId = auth.currentUser!.uid;

    // 初始化 FirestorePoker99Controller
    _gameController = FirestorePoker99Controller(
        firestore: store,
        auth: auth,
        settingsController: settings,
        delegate: _poker99Manager
    );

    _gameStateStreamSubscription = _gameController.gameStateStream.listen((gameState) {
      final poker99State = gameState?.customState;
      if (poker99State == null) return;
      if (mounted && _localMatchStatus == _LocalMatchStatus.waiting) {
        setState(() {
          _localMatchStatus = _LocalMatchStatus.inRoom;
        });
      }
      else if (_isGameReadyState(gameState)) {
        _localMatchStatus = _LocalMatchStatus.idle;
      }

      if (_previousGameStatus == GameStatus.playing && gameState?.gameStatus == GameStatus.finished) {
        _playerWon();
      }
      if (gameState?.gameStatus != null) _previousGameStatus = gameState!.gameStatus;

      // 更新本地玩家 狀態
      final myPlayerState = _poker99Manager.myPlayer(_userId, poker99State);
      if (myPlayerState == null) return;

      _player.name = myPlayerState.name;
      // 將 String 轉回 PlayingCard 供 CardPlayer 使用
      final cards = myPlayerState.cards.map((c) => PlayingCard.fromString(c)).toList();
      _player.replaceWith(cards);
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
      _localMatchStatus = _LocalMatchStatus.waiting;
    });
    await _gameController.matchRoom();
  }

  Future<void> _onStartGame() async {
    await _gameController.startGame();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return ChangeNotifierProvider<CardPlayer>.value(
      value: _player,
      child: StreamBuilder<TurnBasedGameState<Poker99State>?>(
        stream: _gameController.gameStateStream,
        builder: (context, snapshot) {
          final gameState = snapshot.data;

          if (gameState == null || !_isGameReadyState(gameState)) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_localMatchStatus == _LocalMatchStatus.idle)
                    _buildMatchStatusIdleUI(),
                  if (_localMatchStatus == _LocalMatchStatus.waiting)
                    _buildMatchStatusWaitingUI(),
                  if (_localMatchStatus == _LocalMatchStatus.inRoom)
                    _buildRoomMatchingUI(),
                ],
              ),
            );
          }

          final poker99State = gameState.customState;
          final isMyTurn = gameState.currentPlayerId == _userId;
          final otherPlayers = _poker99Manager.otherPlayers(_userId, poker99State);

          return Provider<Poker99State>.value(
            value: poker99State,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                  children: [
                    Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: Poker99BoardWidget.designSize.width,
                          height: Poker99BoardWidget.designSize.height,
                          child: Column(
                            children: [
                              // 第一列: 對手
                              Expanded(
                                flex: 2,
                                child: Center(
                                    child: Row(
                                      spacing: 30,
                                      children: [
                                        const Expanded(child: SizedBox.shrink()),
                                        ..._buildOpponents(otherPlayers, poker99State),
                                        const Expanded(child: SizedBox.shrink()),
                                      ],
                                    )
                                ),
                              ),

                              // 第二列: 中央牌區 (顯示分數)
                              Expanded(
                                flex: 12,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'poker_99.current_score'.tr(),
                                        style: const TextStyle(fontSize: 18, color: Colors.white70),
                                      ),
                                      Text(
                                        '${poker99State.currentScore}',
                                        style: TextStyle(
                                          fontSize: 64,
                                          fontWeight: FontWeight.bold,
                                          color: poker99State.currentScore > 90 ? Colors.redAccent : Colors.white,
                                          shadows: [
                                            Shadow(blurRadius: 10, color: Colors.black45, offset: Offset(2, 2))
                                          ]
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // 第三列: 玩家手牌與操作
                              Expanded(
                                flex: 15,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PlayerAvatarWidget(
                                          avatarNumber: settings.playerAvatarNumber.value,
                                          size: 30,
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
                                      ],
                                    ),

                                    // 單選邏輯與動態按鈕
                                    Consumer<CardPlayer>(
                                      builder: (context, player, _) {
                                        // 強制單選
                                        if (player.selectedCards.length > 1) {
                                          final last = player.selectedCards.last;
                                          Future.microtask(() => player.setCardSelection([last]));
                                        }

                                        final actionButtons = _buildActionButtons(poker99State, isMyTurn);

                                        return SelectablePlayerHandWidget(
                                          buttonWidgets: actionButtons,
                                        );
                                      },
                                    ),
                                    const Expanded(child: SizedBox.shrink()),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox.expand(
                      child: Visibility(
                        visible: _duringCelebration,
                        child: IgnorePointer(
                          child: Confetti(isStopped: !_duringCelebration),
                        ),
                      ),
                    ),
                  ]
              ),
              floatingActionButton: gameState.gameStatus == GameStatus.finished
                  ? _gameOverUI(gameState, poker99State)
                  : null,
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildActionButtons(Poker99State state, bool isMyTurn) {
    if (!isMyTurn || _player.selectedCards.isEmpty) {
      return [const SizedBox(height: 22)];
    }

    final card = _player.selectedCards.first;
    final List<Widget> buttons = [];

    void addActionButton(String label, Poker99Action action, {int value = 0, String targetId = ''}) {
      // 檢查此行動是否會導致超過 99 分
      int nextScore = state.currentScore;
      if (action == Poker99Action.increase || action == Poker99Action.decrease) {
        nextScore += value;
      } else if (action == Poker99Action.setTo99) {
        nextScore = 99;
      } else if (action == Poker99Action.setToZero) {
        nextScore = 0;
      }
      
      final bool isEnabled = nextScore <= 99;

      buttons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: MyButton(
            onPressed: isEnabled ? () {
              _gameController.playCards(Poker99PlayPayload(
                cards: [PlayingCard.cardToString(card)],
                action: action,
                value: value,
                targetPlayerId: targetId,
              ));
              _player.setCardSelection([]);
            } : null,
            child: Text(label),
          ),
        )
      );
    }

    void addTargetButtons() {
      final otherPlayers = _poker99Manager.otherPlayers(_userId, state);
      for (final p in otherPlayers) {
        if (p.cards.isNotEmpty) {
          addActionButton('poker_99.target_player'.tr(args: [p.name]), Poker99Action.target, targetId: p.uid);
        }
      }
    }

    if (card.isJoker()) {
      addActionButton('99', Poker99Action.setTo99);
      addActionButton('0', Poker99Action.setToZero);
      addTargetButtons();
      addActionButton('poker_99.reverse'.tr(), Poker99Action.reverse);
      addActionButton('poker_99.skip'.tr(), Poker99Action.skip);
    } else {
      switch (card.value) {
        case 13:
          addActionButton('99', Poker99Action.setTo99);
          break;
        case 12:
          addActionButton('+20', Poker99Action.increase, value: 20);
          addActionButton('-20', Poker99Action.decrease, value: -20);
          break;
        case 11:
          addActionButton('poker_99.skip'.tr(), Poker99Action.skip);
          break;
        case 10:
          addActionButton('+10', Poker99Action.increase, value: 10);
          addActionButton('-10', Poker99Action.decrease, value: -10);
          break;
        case 5:
          addTargetButtons();
          break;
        case 4:
          addActionButton('poker_99.reverse'.tr(), Poker99Action.reverse);
          break;
        case 1:
          if (card.suit == CardSuit.spades) {
            addActionButton('0', Poker99Action.setToZero);
          } else {
            addActionButton('play_action'.tr(), Poker99Action.increase, value: 1);
          }
          break;
        default:
          addActionButton('play_action'.tr(), Poker99Action.increase, value: card.value);
      }
    }

    return [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: buttons),
      )
    ];
  }

  Future<void> _playerWon() async {
    await Future<void>.delayed(_preCelebrationDuration);
    if (!mounted) return;

    setState(() {
      _duringCelebration = true;
    });

    final audioController = context.read<AudioController>();
    audioController.playSfx(SfxType.congrats);

    await Future<void>.delayed(_celebrationDuration);
    if (!mounted) return;

    setState(() {
      _duringCelebration = false;
    });
  }

  bool _isGameReadyState(TurnBasedGameState<Poker99State>? state) {
    return !(state == null || state.gameStatus == GameStatus.matching);
  }

  Widget _gameOverUI(TurnBasedGameState<Poker99State> gameState, Poker99State poker99State) {
    return Container(
        color: Colors.black54,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'game.winner_status'.tr(args: [
                gameState.customState.getParticipantByID(gameState.winner ?? "")?.name ?? gameState.winner ?? "",
                poker99State.restartRequesters.length.toString(),
                poker99State.participants.length.toString()
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
            SizedBox(height: 20),
            _endButton()
          ],
        ),
      );
  }

  Widget _buildMatchStatusIdleUI() {
    return Column(
      children: [
        Text('ready'.tr()),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _onMatchRoom,
          child: Text('match_room'.tr()),
        ),
        const SizedBox(height: 20),
        _leaveButton(),
      ],
    );
  }

  Widget _buildMatchStatusWaitingUI() {
    return Column(
      children: [
        Text('game.matching_status'.tr(args: [_gameController.participantCount().toString()])),
        const CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildRoomMatchingUI() {
    return Column(
      children: [
        Text('game.matching_status'.tr(args: [_gameController.participantCount().toString()])),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _onStartGame,
          child: Text('start'.tr()),
        ),
        const SizedBox(height: 20),
        _leaveButton(),
      ],
    );
  }

  List<Widget> _buildOpponents(List<PokerPlayer> otherPlayers, Poker99State poker99State) {
    return otherPlayers.map((e)=>_OpponentHand(poker99State: poker99State, player: e)).toList();
  }

  Widget _leaveButton() {
    return ElevatedButton(
      onPressed: () {
        _localMatchStatus = _LocalMatchStatus.idle;
        _gameController.leaveRoom();
        GoRouter.of(context).go('/');
      },
      child: Text('leave'.tr(), style: TextStyle(color: Palette().ink)),
    );
  }

  Widget _endButton() {
    return ElevatedButton(
      onPressed: () {
        _localMatchStatus = _LocalMatchStatus.idle;
        _gameController.endRoom();
        GoRouter.of(context).go('/');
      },
      child: Text('leave'.tr(), style: TextStyle(color: Palette().ink)),
    );
  }
}

class _OpponentHand extends StatelessWidget {
  final Poker99State poker99State;
  final PokerPlayer player;

  const _OpponentHand({
    required this.poker99State,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cardCount = player.cards.length;
    final playerName = player.name;
    final isCurrentTurn = player.uid == poker99State.currentPlayerId;
    final isNextTurn = player.uid == poker99State.nextPlayerId();

    final Color backgroundColor = Colors.black.withValues(alpha: 0.55);
    final Color nameColor = isCurrentTurn ? Colors.amberAccent : Colors.white;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CardContainer(
            color: backgroundColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PlayerAvatarWidget(
                  avatarNumber: player.avatarNumber,
                  size: 30,
                ),
                const SizedBox(width: 8),
                Text(
                  playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: nameColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.style,
                  color: Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  '$cardCount',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (isNextTurn)
            Positioned(
              top: -15,
              right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'poker_99.next_turn'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _LocalMatchStatus {
  idle,
  waiting,
  inRoom,
}
