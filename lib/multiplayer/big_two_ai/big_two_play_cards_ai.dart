import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class BigTwoPlayCardsAI implements BigTwoAI {
  static final _log = Logger('BigTwoPlayCardsAI');
  
  late final FirestoreTurnBasedGameController<BigTwoState> _gameController;
  late final StreamSubscription _gameStateSubscription;
  late final StreamSubscription _roomsSubscription;
  final String _aiUserId;
  final FirebaseFirestore _firestore;
  final BigTwoDelegate _delegate = BigTwoDelegate();
  
  bool _isDisposed = false;
  bool _isRoomJoined = false;
  bool _isProcessingTurn = false;

  BigTwoPlayCardsAI({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required SettingsController settingsController,
  }) : _aiUserId = auth.currentUser?.uid ?? '',
       _firestore = firestore {
       
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
      final bestMove = _findBestMove(currentState, hand);

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

  List<String>? _findBestMove(BigTwoState state, List<PlayingCard> hand) {
    final isFreeTurn = state.lastPlayedById == _aiUserId || (state.lastPlayedHand.isEmpty && state.lastPlayedById.isEmpty);
    final isFirstTurnOfGame = state.lastPlayedHand.isEmpty && state.lastPlayedById.isEmpty;
    final mustContainC3 = isFirstTurnOfGame;

    if (isFreeTurn) {
      final finders = [
        _delegate.findStraightFlushes,
        _delegate.findFourOfAKinds,
        _delegate.findFullHouses,
        _delegate.findStraights,
        _delegate.findPairs,
        _delegate.findSingles,
      ];

      for (final finder in finders) {
        var candidates = finder(hand);
        
        if (mustContainC3) {
          candidates = candidates.where((c) => c.any((card) => card.suit == CardSuit.clubs && card.value == 3)).toList();
        }

        if (candidates.isNotEmpty) {
          // Choose smallest valid candidate (assume sorted)
          return candidates.first.map(PlayingCard.cardToString).toList();
        }
      }
    } else {
      if (state.lockedHandType.isEmpty) return null;

      final lockedType = BigTwoCardPattern.fromJson(state.lockedHandType);
      List<List<PlayingCard>> candidates = [];

      switch (lockedType) {
        case BigTwoCardPattern.single:
          candidates = _delegate.findSingles(hand);
          break;
        case BigTwoCardPattern.pair:
          candidates = _delegate.findPairs(hand);
          break;
        case BigTwoCardPattern.straight:
          candidates = _delegate.findStraights(hand);
          break;
        case BigTwoCardPattern.fullHouse:
          candidates = _delegate.findFullHouses(hand);
          break;
        case BigTwoCardPattern.fourOfAKind:
          candidates = _delegate.findFourOfAKinds(hand);
          break;
        case BigTwoCardPattern.straightFlush:
          candidates = _delegate.findStraightFlushes(hand);
          break;
      }
      
      final validMoves = candidates.where((cards) {
         return _delegate.isBeating(
           cards.map(PlayingCard.cardToString).toList(), 
           state.lastPlayedHand, 
           lockedType
         );
      }).toList();

      if (validMoves.isNotEmpty) {
        return validMoves.first.map(PlayingCard.cardToString).toList();
      }
    }
    
    return null; 
  }

  void dispose() {
    _isDisposed = true;
    _gameStateSubscription.cancel();
    _roomsSubscription.cancel();
    _gameController.dispose();
  }
}
