import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:ok_multipl_poker/settings/settings.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/entities/big_two_player.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';

// 自定義簡易 Delegate
class BigTwoAIDelegate implements TurnBasedGameDelegate<BigTwoState> {
  @override
  BigTwoState initializeGame(Room room) {
    return BigTwoState(
      participants: [], 
      seats: room.seats, 
      currentPlayerId: '',
      lastPlayedHand: [],
      lastPlayedById: '',
    );
  }

  @override
  BigTwoState processAction(BigTwoState currentState, String actionName, String participantId, Map<String, dynamic> payload) {
    return currentState; 
  }

  @override
  String? getCurrentPlayer(BigTwoState state) => state.currentPlayerId;

  @override
  String? getWinner(BigTwoState state) => state.winner;

  @override
  BigTwoState stateFromJson(Map<String, dynamic> json) => BigTwoState.fromJson(json);

  @override
  Map<String, dynamic> stateToJson(BigTwoState state) => state.toJson();
}

class BigTwoAI {
  static final _log = Logger('BigTwoAI');
  
  late final FirestoreTurnBasedGameController<BigTwoState> _gameController;
  late final StreamSubscription _gameStateSubscription;
  late final StreamSubscription _roomsSubscription;
  final String _aiUserId;
  final FirebaseFirestore _firestore;
  
  bool _isDisposed = false;
  bool _isRoomJoined = false;
  
  // 新增狀態變數
  bool _isProcessingTurn = false;

  BigTwoAI({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required SettingsController settingsController,
  }) : _aiUserId = auth.currentUser?.uid ?? '',
       _firestore = firestore {
       
    _gameController = FirestoreTurnBasedGameController<BigTwoState>(
      auth: auth,
      store: firestore,
      delegate: BigTwoAIDelegate(), // 使用自定義 Delegate
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
        // 檢查條件: 有空位且自己不在裡面
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
      // 直接使用 _gameController
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

    // 1. 處理出牌
    if (gameState.gameStatus == GameStatus.playing &&
        gameState.currentPlayerId == _aiUserId) {
      
      // 如果正在處理回合，則跳過，避免重複發送
      if (_isProcessingTurn) return;

      _performTurnAction(gameState.customState);
    }

    // 2. 處理遊戲結束 -> 請求重開
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
      // 模擬思考時間
      await Future.delayed(const Duration(milliseconds: 1000));
      if (_isDisposed) return;
      
      // 再次檢查是否仍輪到自己 (防止在 delay 期間狀態改變，例如被踢出或遊戲強制結束)
      final currentGameState = _gameController.gameStateStream.valueOrNull;
      if (currentGameState?.currentPlayerId != _aiUserId) {
         _log.info('AI $_aiUserId turn cancelled (state changed during think time)');
         return;
      }
      
      // 使用最新的 state 進行判斷
      final currentState = currentGameState!.customState;
      final isFreeTurn = currentState.lastPlayedById == _aiUserId;

      if (isFreeTurn) {
         // 必須出牌
         final myPlayer = currentState.participants.firstWhere((p) => p.uid == _aiUserId, orElse: () => BigTwoPlayer(uid: _aiUserId, name: '', cards: []));
         if (myPlayer.cards.isNotEmpty) {
           String cardToPlayStr = myPlayer.cards.first;
           
           final isGameStart = currentState.lastPlayedHand.isEmpty && currentState.lastPlayedById.isEmpty;
           if (isGameStart) {
             final c3 = myPlayer.cards.firstWhere((c) => c == 'C3', orElse: () => '');
             if (c3.isNotEmpty) cardToPlayStr = c3;
           }
           
           _log.info('AI $_aiUserId MUST play. Playing: $cardToPlayStr');
           
           // 直接傳送 cards string list，不需轉換為 PlayingCard 物件 (依賴後端解析 payload)
           // 根據之前的 Controller 邏輯: payload: {'cards': cardStrings}
           await _gameController.sendGameAction('play_cards', payload: {'cards': [cardToPlayStr]});
         }
      } else {
         // Pass
         _log.info('AI $_aiUserId choosing to PASS');
         await _gameController.sendGameAction('pass_turn');
      }
    } catch (e) {
      _log.warning('AI failed to perform action', e);
    } finally {
      // 無論成功與否，都要釋放鎖
      _isProcessingTurn = false;
    }
  }

  void dispose() {
    _isDisposed = true;
    _gameStateSubscription.cancel();
    _roomsSubscription.cancel();
    _gameController.dispose();
  }
}
