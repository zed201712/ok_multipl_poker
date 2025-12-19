| **任務 ID (Task ID)** | `FEAT-BIG-TWO-AI-001` |
| **創建日期 (Date)** | `2025/12/19` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

參考 `lib/demo/tic_tac_toe_game_page.dart` 中的 `TicTacToeGameAI`，設計並實作一個針對大老二 (Big Two) 遊戲的 AI 代理 (Agent)，類別名為 `BigTwoAI`。
此 AI 的初始行為設定為：在輪到它出牌時，一律選擇 "Pass" (跳過)。

### 2. 設計思路 (Design Approach)

1.  **控制器整合**: `BigTwoAI` 將依賴 `FirestoreBigTwoController` (定義於 `FEAT-FIRESTORE-BIG-TWO-CONTROLLER-001`) 來與遊戲邏輯和 Firestore 進行互動。這與 `TicTacToeGameAI` 直接使用 `FirestoreTurnBasedGameController` 不同，因為大老二有專屬的控制器封裝。
2.  **依賴注入**: 建構子接收 `FirebaseFirestore`, `FirebaseAuth` (或其 Mock) 以及 `SettingsController`。
3.  **自動化流程**:
    *   **監聽房間**: 監聽 `rooms` collection 的變化，當發現適合的房間且自己未加入時，執行 `matchRoom()`。
    *   **監聽狀態**: 監聽 `gameStateStream`。
    *   **執行動作**: 當 `currentPlayerId` 為 AI 自身時，延遲一段時間後執行 `passTurn()`。
    *   **重開局**: 當遊戲結束且 AI 未在重開請求列表中時，自動請求重開。

### 3. 核心實作 (`big_two_ai.dart`)

```dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
// 假設 FirestoreBigTwoController 已定義
import 'package:ok_multipl_poker/multiplayer/firestore_big_two_controller.dart'; 
import 'package:ok_multipl_poker/settings/settings.dart';
import 'package:ok_multipl_poker/entities/room.dart';

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
      // 這裡簡單檢查，假設 collection 裡的都是 Room 結構
      // 實際專案中可能需要 try-catch 或更嚴謹檢查
      final data = doc.data() as Map<String, dynamic>;
      // Room.fromJson 可能需要處理 id 不在 data 裡的情況，或者直接使用 matchRoom 邏輯
      // 為了跟 TicTacToeGameAI 邏輯一致：
      // 檢查是否還有空位且自己不在裡面
      
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
      final isFreeTurn = state.lastPlayedPlayerId == _aiUserId || state.lastPlayedPlayerId.isEmpty;
      
      if (isFreeTurn) {
         // 必須出牌：選擇最小的一張牌 (這是一個簡化策略，僅為了維持遊戲進行)
         final myPlayer = state.participants.firstWhere((p) => p.uid == _aiUserId);
         if (myPlayer.cards.isNotEmpty) {
           String cardToPlay = myPlayer.cards.first;
           
           // 檢查是否為全場第一手
           final isGameStart = state.lastPlayedHand.isEmpty && state.lastPlayedById.isEmpty;
           if (isGameStart) {
             // 尋找梅花3
             final c3 = myPlayer.cards.firstWhere((c) => c == 'C3', orElse: () => '');
             if (c3.isNotEmpty) {
               cardToPlay = c3;
             }
           }
           
           _log.info('AI $_aiUserId MUST play. Playing: $cardToPlay');
           // 假設 Controller 支援 String 或有 helper
           // 這裡僅示意，實際需轉換為 PlayingCard 物件
           // await _controller.playCards([PlayingCard.fromString(cardToPlay)]); 
         }
      } else {
         // 2. 輪到自己的 turn, 才會執行 passTurn()
         // 這裡已經在 _onGameStateUpdate 判斷過 gameState.currentPlayerId == _aiUserId
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
```

### 4. 邏輯檢查與改善建議 (Logic Analysis & Recommendations)

目前的設計要求 AI **只會 Pass**。經分析，此邏輯存在嚴重的**規則死鎖 (Deadlock)** 風險。

#### 4.1. 邏輯錯誤分析
在大老二規則中，以下情況玩家**不能 Pass** (必須出牌)：
1.  **持有梅花 3 (或起始牌)**: 遊戲剛開始時，持有梅花 3 的玩家必須出牌（且出的牌必須包含梅花 3）。
2.  **獲得發球權 (Free Turn)**: 當上家出牌後，其他所有玩家都 Pass，出牌權回到某玩家手上時，該玩家獲得新的發球權，此時**不能 Pass**，必須出任意合法的牌型。
    *   *後果*: 如果 AI 獲得發球權卻嘗試 Pass，後端 `BigTwoDelegate` 應該會拒絕此操作（或拋出錯誤）。如果不處理，遊戲將卡在 AI 的回合，因為它無限嘗試 Pass 但無效。

#### 4.2. 改善建議
為了讓 AI 能順利進行遊戲測試，建議實作一個**最小可行出牌策略 (Minimal Play Strategy)** 來取代「永遠 Pass」：

1.  **判斷是否可以 Pass**:
    *   檢查當前桌面狀態。如果 `lastPlayedPlayerId` 是 AI 自己 (代表其他人 pass 一輪回到自己)，或者是 `null` (新遊戲開始)，則**不可 Pass**。
    *   如果 `lastPlayedPlayerId` 是其他玩家，則可以選擇 Pass。

2.  **強制出牌邏輯**:
    *   當不可 Pass 時，AI 應尋找手牌中**最小的單張** (或包含梅花 3 的最小牌型) 打出。
    *   範例邏輯：
        ```dart
        Future<void> _performTurnAction() async {
          // ... wait ...
          
          final state = _controller.currentBigTwoState; // 假設控制器有 expose state getter
          final isFreeTurn = state.lastPlayedPlayerId == _aiUserId || state.lastPlayedPlayerId.isEmpty;
          
          if (isFreeTurn) {
             // 必須出牌：選擇最小的一張牌
             final hand = state.hands[_aiUserId]!;
             // 簡單策略：出第一張 (假設手牌已排序) 或尋找梅花3
             final cardToPlay = hand.first; 
             await _controller.playCards([cardToPlay]);
          } else {
             // 可以 Pass
             await _controller.passTurn();
          }
        }
        ```

3.  **錯誤處理**:
    *   即便保留「只會 Pass」的行為，也應監聽控制器的錯誤流。如果 `passTurn()` 拋出 `InvalidActionException` (例如因為不能 Pass)，AI 應捕捉該異常並嘗試做一個隨機合法出牌，以避免遊戲卡死。
