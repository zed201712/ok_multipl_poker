import 'dart:async';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:ok_multipl_poker/entities/poker_99_play_payload.dart';
import 'package:ok_multipl_poker/entities/room_state.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/game_internals/poker_99_action.dart';
import 'package:ok_multipl_poker/entities/poker_99_state.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';

import '../../entities/room.dart';
import '../../game_internals/card_suit.dart';
import '../../game_internals/poker_99_delegate.dart';

class Poker99AI {
  static final _log = Logger('Poker99AI');

  final Poker99Delegate _delegate;
  final String aiUserId;
  final void Function(Poker99State state) onAction;

  bool _isDisposed = false;
  bool _isProcessingTurn = false;
  StreamSubscription? _stateSubscription;

  Poker99AI({
    required this.aiUserId,
    required Poker99Delegate delegate,
    required this.onAction,
  })  : _delegate = delegate;

  /// 供外部 (Controller) 或本地修改狀態。
  /// 呼叫後會觸發 _stateSubject 的發送，進而執行 AI 邏輯。
  void updateState(TurnBasedGameState<Poker99State> gameState, RoomState roomState) {
    if (_isDisposed) return;
    _onGameStateUpdate(gameState, roomState.room!);
  }

  void _onGameStateUpdate(TurnBasedGameState<Poker99State> gameState, Room room) async {
    if (_isDisposed) return;

    // 1. 處理出牌
    if (gameState.gameStatus == GameStatus.playing &&
        gameState.currentPlayerId == aiUserId) {
      // 如果正在處理回合，則跳過，避免重複發送
      if (_isProcessingTurn) return;

      _performTurnAction(gameState.customState, room);
    }

    // 2. 處理遊戲結束 -> 請求重開
    if (gameState.gameStatus == GameStatus.finished) {
      final alreadyRequested =
          gameState.customState.restartRequesters.contains(aiUserId);
      if (!alreadyRequested) {
        await Future.delayed(const Duration(milliseconds: 100), () {
          if (!_isDisposed) {
            final newState = _delegate.processAction(room, gameState.customState, 'request_restart', aiUserId, {});
            onAction(newState);
          }
        });
      }
    }
  }

  Future<void> _performTurnAction(Poker99State state, Room room) async {
    if (_isProcessingTurn) return;
    _isProcessingTurn = true;

    try {
      // 模擬思考時間
      await Future.delayed(const Duration(milliseconds: 300));
      if (_isDisposed) return;

      // 再次檢查是否仍輪到自己 (使用快照中的狀態判斷，或由外部 updateState 控制)
      if (state.currentPlayerId != aiUserId) {
        _log.info('AI $aiUserId turn cancelled (state changed during think time)');
        return;
      }

      // 找出 AI 自己
      final player = state.participants.firstWhereOrNull((p) => p.uid == aiUserId);
      if (player == null || player.cards.isEmpty) return;

      // 找出可出的牌
      final handCards = player.cards.toPlayingCards();
      final playableCards = _delegate.getPlayableCards(state, handCards);

      if (playableCards.isEmpty) {
        _log.info('AI $aiUserId has no playable cards.');
        return;
      }

      // 選擇優先權最高的牌: Joker > K(13) > Q(12) > ... > A(1)
      playableCards.sort((a, b) {
        if (a.isJoker()) return -1;
        if (b.isJoker()) return 1;
        return b.value.compareTo(a.value);
      });

      final cardToPlay = playableCards.first;
      Poker99Action action = Poker99Action.increase;
      int value = cardToPlay.value;
      String targetPlayerId = '';

      if (cardToPlay.isJoker()) {
        action = Poker99Action.setTo99;
      } else {
        switch (cardToPlay.value) {
          case 13: // K
            action = Poker99Action.setTo99;
            break;
          case 12: // Q
            if (state.currentScore + 20 <= 99) {
              action = Poker99Action.increase;
              value = 20;
            } else {
              action = Poker99Action.decrease;
              value = -20;
            }
            break;
          case 10: // 10
            if (state.currentScore + 10 <= 99) {
              action = Poker99Action.increase;
              value = 10;
            } else {
              action = Poker99Action.decrease;
              value = -10;
            }
            break;
          case 5: // Assign
            action = Poker99Action.target;
            targetPlayerId = _calculateTargetPlayerId(state);
            break;
          case 4:
            action = Poker99Action.reverse;
            break;
          case 11:
            action = Poker99Action.skip;
            break;
          case 1:
            // 黑桃 A 歸零
            if (cardToPlay.suit == CardSuit.spades) {
              action = Poker99Action.setToZero;
            } else {
              action = Poker99Action.increase;
              value = 1;
            }
            break;
          default:
            action = Poker99Action.increase;
            value = cardToPlay.value;
        }
      }

      final payload = Poker99PlayPayload(
        cards: [PlayingCard.cardToString(cardToPlay)],
        action: action,
        value: value,
        targetPlayerId: targetPlayerId,
      );
      final newState = _delegate.processAction(room, state, 'play_cards', aiUserId, payload.toJson());
      onAction(newState);
    } catch (e) {
      _log.warning('AI failed to perform action', e);
    } finally {
      // 無論成功與否，都要釋放鎖
      _isProcessingTurn = false;
    }
  }

  String _calculateTargetPlayerId(Poker99State state) {
    final seats = state.seats;
    final myIndex = seats.indexOf(aiUserId);
    if (myIndex == -1) return '';

    // 邏輯: 根據 state.isReverse 選擇「上一個玩家」
    // 如果 !isReverse (順時針), 則上家是 index - 1
    // 如果 isReverse (逆時針), 則上家是 index + 1
    int step = state.isReverse ? 1 : -1;
    int targetIdx = (myIndex + step) % seats.length;
    if (targetIdx < 0) targetIdx += seats.length;

    // 確保目標玩家還有手牌 (未淘汰)
    int count = 0;
    while (state.participants
            .firstWhere((p) => p.uid == seats[targetIdx])
            .cards
            .isEmpty &&
        count < seats.length) {
      targetIdx = (targetIdx + step) % seats.length;
      if (targetIdx < 0) targetIdx += seats.length;
      count++;
    }

    return seats[targetIdx];
  }

  void dispose() {
    _isDisposed = true;
    _stateSubscription?.cancel();
  }
}
