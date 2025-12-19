| **任務 ID (Task ID)** | `FEAT-BIG-TWO-AI-002` |
| **創建日期 (Date)** | `2025/12/19` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

本任務旨在重構 `BigTwoAI` 的實作方式，目標如下：
1.  **自定義 Delegate**: 實作一個簡易的 `BigTwoAIDelegate`，專供 AI 使用，使其能獨立處理遊戲狀態的解析與操作，不依賴於主要的 `BigTwoDelegate`。
2.  **直接控制**: 不再依賴 `FirestoreBigTwoController`，而是直接使用 `FirestoreTurnBasedGameController<BigTwoState>`。這能讓 AI 更靈活地處理底層邏輯，或在測試環境中更容易抽換 Delegate。
3.  **邏輯維持**: 保持 `FEAT-BIG-TWO-AI-001` 中定義的 AI 行為（優先 Pass，必要時出最小牌）。

### 2. 設計思路 (Design Approach)

#### 2.1. 移除 `FirestoreBigTwoController` 依賴
原有的 `BigTwoAI` 透過 `FirestoreBigTwoController` 間接操作遊戲。新設計將讓 `BigTwoAI` 直接持有一個 `FirestoreTurnBasedGameController<BigTwoState>`。
這意味著 `BigTwoAI` 需要自行提供一個 `TurnBasedGameDelegate<BigTwoState>` 給 Controller。

#### 2.2. 實作 `BigTwoAIDelegate`
由於 AI 端通常只需要「解析狀態」和「計算下一步」，而不需要處理完整的「遊戲規則驗證」（那是 Host/Manager 的責任），我們可以實作一個簡化的 Delegate。
但在 `FirestoreTurnBasedGameController` 的架構下，所有客戶端都使用相同的泛型 `T` (即 `BigTwoState`)。因此，`BigTwoAIDelegate` 仍需負責序列化/反序列化 `BigTwoState`。
*   **關鍵點**: `processAction` 在 AI 端通常不會被呼叫（除非 AI 是房主且 Controller 架構要求所有端都執行邏輯）。假設 Controller 架構是「Manager 運算狀態，Client 接收狀態」，則 Client 端的 Delegate 主要功能是 `stateFromJson`。若 AI 需自行模擬狀態，則需完整實作。在此我們假設 AI 僅需解析狀態以做出決策。

#### 2.3. AI 邏輯整合
AI 的決策邏輯 (`_performTurnAction`) 將維持不變，但與 Controller 的互動方式會改變：
*   原本: `_controller.passTurn()`
*   現在: `_gameController.sendGameAction('pass_turn')`
*   原本: `_controller.playCards(...)`
*   現在: `_gameController.sendGameAction('play_cards', payload: {'cards': [...]})`

### 3. 核心實作 (`big_two_ai.dart`)

```dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:ok_multipl_poker/settings/settings.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';

// 自定義簡易 Delegate
class BigTwoAIDelegate implements TurnBasedGameDelegate<BigTwoState> {
  @override
  BigTwoState initializeGame(Room room) {
    // AI 客戶端通常不負責初始化遊戲（除非它是房主），但接口需要實現。
    // 可以拋出錯誤或返回一個空狀態，視 Controller 實作而定。
    // 若 AI 意外成為房主，這裡應有基本實作或依賴服務端邏輯。
    // 簡單起見，返回一個空殼或拋出 UnimplementedError (若確定不會是房主)
    // 但為了安全，建議回傳基本空狀態。
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
    // AI 客戶端主要接收狀態更新，較少在本地模擬 processAction。
    // 但如果它是房主，它需要這個邏輯。
    // 為了簡化 "簡易 AI Delegate"，我們可以假設 AI **不是** 房主，
    // 或者即使是房主，我們也複用既有的邏輯 (這裡若要自己實現，程式碼會很長)。
    // **修正**: 題目要求 "自己實現簡易的AI用的BigtwoAIDelegate"。
    // 這通常意味著只需處理序列化，或者如果 AI 需要預測狀態。
    // 若 AI 必須能當 Host，則這裡必須包含完整的 BigTwo 規則。
    // 假設: AI 主要作為 Client 參與。若作為 Host，應使用完整的 BigTwoDelegate。
    // 但為了滿足 "不依賴 FirestoreBigTwoController" 且 "使用 BigTwoAIDelegate"，
    // 我們在此僅實作必要的序列化方法，processAction 可留空或僅回傳 currentState。
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
    await Future.delayed(const Duration(milliseconds: 1000));
    if (_isDisposed) return;

    try {
      final isFreeTurn = state.lastPlayedPlayerId == _aiUserId || state.lastPlayedPlayerId.isEmpty;
      
      if (isFreeTurn) {
         // 必須出牌
         final myPlayer = state.participants.firstWhere((p) => p.uid == _aiUserId, orElse: () => BigTwoPlayer(uid: _aiUserId, name: '', cards: []));
         if (myPlayer.cards.isNotEmpty) {
           String cardToPlayStr = myPlayer.cards.first;
           
           final isGameStart = state.lastPlayedHand.isEmpty && state.lastPlayedById.isEmpty;
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
    }
  }

  void dispose() {
    _isDisposed = true;
    _gameStateSubscription.cancel();
    _roomsSubscription.cancel();
    _gameController.dispose();
  }
}
```

### 4. 邏輯檢查與改善建議

#### 4.1. 潛在風險：AI 作為 Manager (Host)
*   **問題**: `FirestoreTurnBasedGameController` 的設計通常將第一個進入房間的人設為 Manager，負責執行 `processAction` 並更新 Room 的 `body`。
*   **風險**: 如果 AI 剛好成為 Manager（例如它是房間裡唯一的玩家，或者 Manager 斷線 AI 接手 - 視 Controller 實作而定），它會使用 `BigTwoAIDelegate.processAction` 來計算遊戲狀態。
*   **後果**: 由於 `BigTwoAIDelegate` 的 `processAction` 僅回傳 `currentState` (不做任何狀態推進)，遊戲將會卡住。其他玩家出牌後，狀態不會更新。
*   **改善建議**:
    1.  **AI 永不當 Manager**: 確保 AI 加入房間的機制不會讓它成為 Manager（例如只加入已存在的房間，且該房間已有 Manager）。目前的 `_onRoomsSnapshot` 邏輯是尋找現有房間，這降低了風險，但若 Manager 離開，權限轉移邏輯可能會選中 AI。
    2.  **Delegate 完整性**: 若無法保證 AI 不當 Manager，則 `BigTwoAIDelegate` 必須實作完整的規則，或者直接複用 `BigTwoDelegate`（違反 "自己實現簡易" 的初衷，但最安全）。
    3.  **簡易實作的定義**: 如果 "簡易" 指的是 AI 不會驗證複雜規則，只負責轉發，那它只能當 Client。若必須當 Manager，建議在 `BigTwoAIDelegate` 中直接以此方式委派給 `BigTwoDelegate` (Composition) 或者繼承它。
    *   **本 Spec 策略**: 為了符合 "自己實現" 且 "簡易" 的要求，我們假設 AI **只作為 Client** 運作。若 AI 成為 Manager，它將無法推進遊戲。這是一個已知的限制。

#### 4.2. 序列化一致性
*   `BigTwoAIDelegate` 必須使用與 Host 端完全一致的 `fromJson`/`toJson` 邏輯，否則會導致狀態解析錯誤。在本實作中直接呼叫 `BigTwoState.fromJson/toJson` 是正確的做法。

#### 4.3. 依賴 PlayingCard 字串
*   在 `_performTurnAction` 中，我們直接傳送 `List<String>` 給 payload。底層 `FirestoreTurnBasedGameController` 只負責傳輸 JSON，這比透過 `FirestoreBigTwoController` 轉成 `PlayingCard` 物件再轉回 String 更直接且高效。
