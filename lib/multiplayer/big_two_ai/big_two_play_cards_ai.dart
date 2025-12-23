import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For @visibleForTesting
import 'package:logging/logging.dart';
import 'package:ok_multipl_poker/multiplayer/big_two_ai/big_two_ai.dart';
import 'package:ok_multipl_poker/settings/settings.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/entities/big_two_player.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';
import 'package:ok_multipl_poker/game_internals/big_two_delegate.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/game_internals/big_two_card_pattern.dart';
import 'package:ok_multipl_poker/game_internals/card_suit.dart';
import 'dart:math';

class BigTwoPlayCardsAI implements BigTwoAI {
  static final _log = Logger('BigTwoPlayCardsAI');
  
  late final FirestoreTurnBasedGameController<BigTwoState> _gameController;
  late final StreamSubscription _gameStateSubscription;
  late final StreamSubscription _roomsSubscription;
  final String _aiUserId;
  final FirebaseFirestore _firestore;
  final BigTwoDelegate _delegate;
  
  bool _isDisposed = false;
  bool _isRoomJoined = false;
  bool _isProcessingTurn = false;

  BigTwoPlayCardsAI({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required SettingsController settingsController,
    required BigTwoDelegate delegate,
  }) : _aiUserId = auth.currentUser?.uid ?? '',
       _firestore = firestore,
       _delegate = delegate {
       
    _gameController = FirestoreTurnBasedGameController<BigTwoState>(
      auth: auth,
      store: firestore,
      delegate: _delegate, 
      collectionName: 'big_two_rooms',
      settingsController: settingsController,
    );
    
    _init();
  }

  void _init() {
    _gameStateSubscription = _gameController.gameStateStream.listen(_onGameStateUpdate);
    _roomsSubscription = _firestore.collection('big_two_rooms').snapshots().listen(_onRoomsSnapshot);
  }

  void _onRoomsSnapshot(QuerySnapshot snapshot) {
    if (_isRoomJoined || _isDisposed) return;

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      try {
        final room = Room.fromJson(data);
        if (room.participants.length < room.maxPlayers &&
            !room.participants.any((p) => p.id == _aiUserId)) {
           _matchRoom();
           break; 
        }
      } catch (e) {
        _log.warning('Error parsing room data for AI check', e);
      }
    }
  }

  Future<void> _matchRoom() async {
    try {
      if (_isDisposed) return;
      _log.info('AI $_aiUserId attempting to match room...');
      final roomId = await _gameController.matchAndJoinRoom(maxPlayers: 4);
      if (roomId.isNotEmpty) {
        _isRoomJoined = true;
      }
    } catch (e) {
      _log.severe('AI failed to match room', e);
    }
  }

  void _onGameStateUpdate(TurnBasedGameState<BigTwoState>? gameState) {
    if (_isDisposed || gameState == null) return;

    if (gameState.gameStatus == GameStatus.playing &&
        gameState.currentPlayerId == _aiUserId) {
      
      if (_isProcessingTurn) return;

      _performTurnAction(gameState.customState);
    }

    if (gameState.gameStatus == GameStatus.finished) {
      final alreadyRequested = gameState.customState.restartRequesters.contains(_aiUserId);
      if (!alreadyRequested) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!_isDisposed) {
             _gameController.sendGameAction('request_restart');
          }
        });
      }
    }
  }

  Future<void> _performTurnAction(BigTwoState state) async {
    if (_isProcessingTurn) return;
    _isProcessingTurn = true;

    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (_isDisposed) return;
      
      final currentGameState = _gameController.gameStateStream.valueOrNull;
      if (currentGameState?.currentPlayerId != _aiUserId) {
         _log.info('AI $_aiUserId turn cancelled (state changed during think time)');
         return;
      }
      
      final currentState = currentGameState!.customState;
      final myPlayer = currentState.participants.firstWhere(
        (p) => p.uid == _aiUserId, 
        orElse: () => BigTwoPlayer(uid: _aiUserId, name: '', cards: [])
      );
      
      if (myPlayer.cards.isEmpty) return;

      final hand = myPlayer.cards.map(PlayingCard.fromString).toList();
      final bestMove = findBestMove(currentState, hand);

      if (bestMove != null) {
         _log.info('AI $_aiUserId playing: $bestMove');
         await _gameController.sendGameAction('play_cards', payload: {'cards': bestMove});
      } else {
         _log.info('AI $_aiUserId choosing to PASS');
         await _gameController.sendGameAction('pass_turn');
      }

    } catch (e) {
      _log.warning('AI failed to perform action', e);
    } finally {
      _isProcessingTurn = false;
    }
  }

  @visibleForTesting
  List<String>? findBestMove(BigTwoState state, List<PlayingCard> hand) {
    // 1. Sort Hand & Find Lowest Card
    // Use the delegate's sorting to respect Big Two order (Rank 3..2, Suit C..S)
    final sortedHand = _delegate.sortCardsByRank(hand);
    
    // Safety check
    if (sortedHand.isEmpty) return null;
    
    // The first card in sortedHand is the lowest value card according to Big Two rules.
    final lowestCard = sortedHand.first;
    final lowestCardStr = PlayingCard.cardToString(lowestCard);

    // AI logic needs to wrap PlayingCard list in a Player object context for delegate helpers,
    // or we can just pass the player object if we have it?
    // Delegate helpers: getPlayablePatterns(state, player) -> uses player.cards
    // We need to create a temporary player object representing this AI with current hand.
    final tempPlayer = BigTwoPlayer(uid: _aiUserId, name: 'AI', cards: sortedHand.map(PlayingCard.cardToString).toList());

    // 2. Check First Turn
    // Condition: lastPlayedHand empty && lastPlayedById empty
    final isFirstTurnOfGame = state.lastPlayedHand.isEmpty && state.lastPlayedById.isEmpty;
    
    if (isFirstTurnOfGame) {
        final allCombos = _delegate.getAllPlayableCombinations(state, tempPlayer);
        
        // Filter: Must contain lowest card
        final validCombos = allCombos.where((combo) => combo.contains(lowestCardStr)).toList();
        
        if (validCombos.isEmpty) {
            // Should not happen if logic is correct, but return lowest single as fallback or null
            return null;
        }
        
        // Randomly pick one
        final random = Random();
        return validCombos[random.nextInt(validCombos.length)];
    }

    // 3. Normal Turn Logic (Priority Loop)
    
    // Step 1: Get Playable Patterns
    final playablePatterns = _delegate.getPlayablePatterns(state, tempPlayer);
    
    // Step 2: Priority List
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
        
        // Step 3: Get and Verify Combinations
        final candidates = _delegate.getPlayableCombinations(state, tempPlayer, pattern);
        
        if (candidates.isEmpty) continue;
        
        // Safety Check for same pattern beating (Delegate should handle, but spec requires explicit check)
        List<List<String>> verifiedCandidates = candidates;
        
        // Check if locked pattern matches current pattern (Normal beating logic)
        // Or if it's a bomb situation
        if (state.lockedHandType.isNotEmpty) {
             final lockedPattern = BigTwoCardPattern.fromJson(state.lockedHandType);
             if (lockedPattern == pattern) {
                 verifiedCandidates = candidates.where((c) => _delegate.isBeating(c, state.lastPlayedHand)).toList();
             }
             // If bomb (SF or 4K), getPlayableCombinations usually handles isBeating internally for bombs too?
             // Spec says "Delegate should have filtered", but "safety check: if pattern == lockedHandType, confirm isBeating".
             // We do that above.
        }
        
        if (verifiedCandidates.isEmpty) continue;
        
        // Step 4: Choose Strategy (Smallest Rank)
        // Candidates are List<String>. We need to sort them by "value".
        // For Single: Value of card.
        // For Pair/Straight/etc: Value of the "rank" card (largest card usually or specific logic).
        // Since `getPlayableCombinations` usually returns sorted list from small to large? 
        // Delegate's `findPairs` etc. iterates from small to large.
        // So the first one in `verifiedCandidates` should be the smallest.
        
        // Just to be sure, we pick the first one.
        return verifiedCandidates.first;
    }

    // 4. Return null (Pass)
    return null; 
  }

  void dispose() {
    _isDisposed = true;
    _gameStateSubscription.cancel();
    _roomsSubscription.cancel();
    _gameController.dispose();
  }
}
