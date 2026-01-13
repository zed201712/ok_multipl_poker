import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/entities/room_state.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/entities/big_two_player.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';
import 'package:ok_multipl_poker/game_internals/big_two_delegate.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/game_internals/big_two_card_pattern.dart';
import 'dart:math';

import 'big_two_ai.dart';

class BigTwoPlayCardsAI implements BigTwoAI {
  static final _log = Logger('BigTwoPlayCardsAI');
  
  @override
  final String aiUserId;
  final BigTwoDelegate _delegate;
  final void Function(BigTwoState state) onAction;
  
  bool _isDisposed = false;
  bool _isProcessingTurn = false;

  BigTwoPlayCardsAI({
    required this.aiUserId,
    required BigTwoDelegate delegate,
    required this.onAction,
  }) : _delegate = delegate;

  @override
  void updateState(TurnBasedGameState<BigTwoState> gameState, RoomState roomState) {
    if (_isDisposed) return;
    _onGameStateUpdate(gameState, roomState.room!);
  }

  void _onGameStateUpdate(TurnBasedGameState<BigTwoState> gameState, Room room) {
    if (_isDisposed) return;

    if (gameState.gameStatus == GameStatus.playing &&
        gameState.currentPlayerId == aiUserId) {
      
      if (_isProcessingTurn) return;

      _performTurnAction(gameState.customState, room);
    }

    if (gameState.gameStatus == GameStatus.finished) {
      final alreadyRequested = gameState.customState.restartRequesters.contains(aiUserId);
      if (!alreadyRequested) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_isDisposed) {
             final newState = _delegate.processAction(room, gameState.customState, 'request_restart', aiUserId, {});
             onAction(newState);
          }
        });
      }
    }
  }

  Future<void> _performTurnAction(BigTwoState state, Room room) async {
    if (_isProcessingTurn) return;
    _isProcessingTurn = true;

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (_isDisposed) return;
      
      // Note: We use the passed 'state' as a snapshot. In a BotContext setup, 
      // the controller should ensure we only call this when it's still our turn.
      if (state.currentPlayerId != aiUserId) {
         _log.info('AI $aiUserId turn cancelled (state changed during think time)');
         return;
      }
      
      final myPlayer = state.participants.firstWhere(
        (p) => p.uid == aiUserId, 
        orElse: () => BigTwoPlayer(uid: aiUserId, name: '', cards: [])
      );
      
      if (myPlayer.cards.isEmpty) return;

      final hand = myPlayer.cards.toPlayingCards();
      final bestMove = findBestMove(state, hand);

      if (bestMove != null) {
         _log.info('AI $aiUserId playing: $bestMove');
         final newState = _delegate.processAction(room, state, 'play_cards', aiUserId, {'cards': bestMove});
         onAction(newState);
      } else {
         _log.info('AI $aiUserId choosing to PASS');
         final newState = _delegate.processAction(room, state, 'pass_turn', aiUserId, {});
         onAction(newState);
      }

    } catch (e) {
      _log.warning('AI failed to perform action', e);
    } finally {
      _isProcessingTurn = false;
    }
  }

  @visibleForTesting
  List<String>? findBestMove(BigTwoState state, List<PlayingCard> hand) {
    final sortedHand = _delegate.sortCardsByRank(hand);
    if (sortedHand.isEmpty) return null;
    final lowestCard = sortedHand.first;

    if (state.isFirstTurn) {
        final allCombos = _delegate.getAllPlayableCombinations(state, sortedHand);
        final validCombos = allCombos.where((combo) => combo.contains(lowestCard)).toList();
        
        if (validCombos.isEmpty) return null;
        
        final random = Random();
        final pickedCombos = validCombos[random.nextInt(validCombos.length)];
        return pickedCombos.toStringCards();
    }

    final playablePatterns = _delegate.getPlayablePatterns(state);
    const priorityList = [
        BigTwoCardPattern.straightFlush,
        BigTwoCardPattern.fourOfAKind,
        BigTwoCardPattern.fullHouse,
        BigTwoCardPattern.straight,
        BigTwoCardPattern.pair,
        BigTwoCardPattern.single,
    ];
    
    for (final pattern in priorityList) {
        if (!playablePatterns.contains(pattern)) continue;
        
        final candidates = _delegate.getPlayableCombinations(state, sortedHand, pattern);
        if (candidates.isEmpty) continue;
        
        List<List<PlayingCard>> verifiedCandidates = candidates;
        
        final lastPlayedCards = state.lastPlayedHand.toPlayingCards();
        if (state.lockedHandType.isNotEmpty) {
             final lockedPattern = BigTwoCardPattern.fromJson(state.lockedHandType);
             if (lockedPattern == pattern) {
                 verifiedCandidates = candidates.where((c) => _delegate.isBeating(c, lastPlayedCards)).toList();
             }
        }
        
        if (verifiedCandidates.isEmpty) continue;
        
        // Strategy: choose the smallest valid combination
        return verifiedCandidates.map((e)=>e.toStringCards()).first;
    }

    return null; 
  }

  @override
  void dispose() {
    _isDisposed = true;
  }
}
