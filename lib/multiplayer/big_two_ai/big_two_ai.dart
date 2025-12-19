import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_big_two_controller.dart';
import 'package:ok_multipl_poker/settings/settings.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';

class BigTwoAI {
  static final _log = Logger('BigTwoAI');
  
  late final FirestoreBigTwoController _controller;
  late final StreamSubscription _gameStateSubscription;
  late final StreamSubscription _roomsSubscription;
  final String _aiUserId;
  final FirebaseFirestore _firestore;
  
  bool _isDisposed = false;
  bool _isRoomJoined = false;

  BigTwoAI({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required SettingsController settingsController,
  }) : _aiUserId = auth.currentUser?.uid ?? '',
       _firestore = firestore {
    _controller = FirestoreBigTwoController(
      firestore: firestore,
      auth: auth,
      settingsController: settingsController,
    );
    
    _init();
  }

  void _init() {
    _gameStateSubscription = _controller.gameStateStream.listen(_onGameStateUpdate);
    // 1. 監聽 rooms 變化，當有新房間建立時才執行 matchRoom
    _roomsSubscription = _firestore.collection('big_two_rooms').snapshots().listen(_onRoomsSnapshot);
  }

  void _onRoomsSnapshot(QuerySnapshot snapshot) {
    if (_isRoomJoined || _isDisposed) return; // Already in a room or disposed

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      try {
        final room = Room.fromJson(data);
        if (room.participants.length < room.maxPlayers &&
            !room.participants.any((p) => p.id == _aiUserId)) {
          
           _matchRoom();
           break; // 嘗試加入第一個符合的
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
      final roomId = await _controller.matchRoom();
      if (roomId != null) {
        _isRoomJoined = true;
      }
    } catch (e) {
      _log.severe('AI failed to match room', e);
    }
  }

  void _onGameStateUpdate(TurnBasedGameState<BigTwoState>? gameState) {
    if (_isDisposed || gameState == null) return;

    // 1. 處理出牌 (Playing)
    if (gameState.gameStatus == GameStatus.playing &&
        gameState.currentPlayerId == _aiUserId) {
      
      _performTurnAction(gameState.customState);
    }

    // 2. 處理遊戲結束 (Finished) -> 請求重開 (Restart)
    if (gameState.gameStatus == GameStatus.finished) {
      final alreadyRequested = gameState.customState.restartRequesters.contains(_aiUserId);
      if (!alreadyRequested) {
        // 延遲後請求重開
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!_isDisposed) {
            _controller.restart();
          }
        });
      }
    }
  }

  Future<void> _performTurnAction(BigTwoState state) async {
    // 模擬思考時間
    await Future.delayed(const Duration(milliseconds: 1000));
    if (_isDisposed) return;

    try {
      final isMyTurn = state.lastPlayedById == _aiUserId;
      
      if (isMyTurn) {
         // 必須出牌：選擇最小的一張牌 (這是一個簡化策略，僅為了維持遊戲進行)
         final myPlayer = state.participants.firstWhere((p) => p.uid == _aiUserId);
         if (myPlayer.cards.isNotEmpty) {
           String cardToPlayStr = myPlayer.cards.first;
           
           // 檢查是否為全場第一手
           final isGameStart = state.lastPlayedHand.isEmpty && state.lastPlayedById.isEmpty;
           if (isGameStart) {
             // 尋找梅花3
             final c3 = myPlayer.cards.firstWhere((c) => c == 'C3', orElse: () => '');
             if (c3.isNotEmpty) {
               cardToPlayStr = c3;
             }
           }
           
           _log.info('AI $_aiUserId MUST play. Playing: $cardToPlayStr');
           
           // 需要將 String 轉換為 PlayingCard
           // 假設 PlayingCard.fromString 存在
           // 注意：如果 PlayingCard 沒有 public static fromString 方法，這會出錯。
           // 基於之前的讀取，_isBeating 中有 PlayingCard.fromString(current[0])
           
           final cardToPlay = PlayingCard.fromString(cardToPlayStr);
           await _controller.playCards([cardToPlay]);
         }
      } else {
         // 2. 輪到自己的 turn, 才會執行 passTurn()
         _log.info('AI $_aiUserId choosing to PASS');
         await _controller.passTurn();
      }
    } catch (e) {
      _log.warning('AI failed to perform action', e);
    }
  }

  void dispose() {
    _isDisposed = true;
    _gameStateSubscription.cancel();
    _roomsSubscription.cancel();
    _controller.dispose();
  }
}
