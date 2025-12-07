| **任務 ID (Task ID)** | `FEAT-TURN-BASED-CONTROLLER-002` |
| **創建日期 (Date)** | `2025/12/09` |

### 1. 目的 (Objective)

本文件旨在解決 `FirestoreTurnBasedGameController` 中的一個關鍵錯誤，並提升其穩健性。主要目標如下：

1.  **修復初始化流程**: 解決新房間建立後，因 `room.body` 為空而導致遊戲無法開始 (`start_game`) 的問題。
2.  **增強狀態解析**: 增加對 `room.body` 解析過程的錯誤處理，防止因數據格式錯誤導致的邏輯中斷。

### 2. 問題分析 (Problem Analysis)

#### 2.1. 遊戲初始化流程卡死 (Game Initialization Stuck)

在當前的 `_onRoomStateChanged` 方法中，如果 `roomState!.room!.body.isEmpty` 條件成立，方法會直接 `return`。

```dart
// firestore_turn_based_game_controller.dart
void _onRoomStateChanged(RoomState? roomState) {
    if (roomState?.room == null || roomState!.room!.body.isEmpty) {
      _gameStateController.add(null);
      return; // <--- 問題點 (The Problem)
    }
    // ...
    if (_roomStateController.currentUserId == room.managerUid) {
      _processRequests(gameState, roomState.requests); // <--- 這段代碼無法被執行 (This code is unreachable)
    }
}
```

這導致即使房主 (Manager) 收到 `start_game` 請求，也因為 `_processRequests` 方法沒有被調用而無法處理該請求。結果是，`room.body` 永遠不會被賦予初始值，整個遊戲流程被卡死在初始狀態。

#### 2.2. 遊戲狀態解析脆弱 (Fragile Game State Parsing)

`_parseGameState` 方法直接使用 `jsonDecode` 和 `TurnBasedGameState.fromJson`。如果 `room.body` 中的字符串不是一個合法的 JSON，或者 JSON 缺少必要的欄位，這兩個方法都可能拋出異常。

目前 `_onRoomStateChanged` 中沒有對 `_parseGameState` 的調用進行 `try-catch` 保護，一旦解析失敗，將導致整個 `roomStateStream` 的監聽器崩潰，後續所有狀態更新都將丟失。

### 3. 解決方案 (Solution)

我們將修改 `_onRoomStateChanged` 和 `_processRequests` 方法來解決上述問題。

#### 3.1. 修改 `_onRoomStateChanged` 核心邏輯

`_onRoomStateChanged` 的邏輯將被重構，以確保即使 `room.body` 為空，房主也能處理請求。

1.  **分離狀態解析與請求處理**: 即使 `room.body` 為空或解析失敗，也要繼續執行後續的請求處理邏輯。
2.  **引入可空狀態**: 在方法內部使用一個可為空的 `TurnBasedGameState<T>? gameState` 變量。
3.  **增加錯誤處理**: 使用 `try-catch` 包圍 `_parseGameState` 的調用。如果解析失敗，記錄錯誤並將 `gameState` 保持為 `null`，然後繼續執行。

```dart
// 擬代碼 (Pseudo-code)
void _onRoomStateChanged(RoomState? roomState) {
  if (roomState?.room == null) { /* ... */ return; }

  final room = roomState.room!;
  TurnBasedGameState<T>? gameState; // 1. 引入可空狀態

  if (room.body.isNotEmpty) {
    try { // 3. 增加錯誤處理
      gameState = _parseGameState(room.body);
      _gameStateController.add(gameState);
    } catch (e) {
      _errorMessageService.showError("Failed to parse game state: $e");
      _gameStateController.add(null);
    }
  } else {
    _gameStateController.add(null);
  }

  // 2. 確保請求處理總能執行
  if (_roomStateController.currentUserId == room.managerUid) {
    _processRequests(gameState, roomState.requests); // 傳遞可能為 null 的 gameState
  }
}
```

#### 3.2. 修改 `_processRequests` 以處理可空狀態

為了配合 `_onRoomStateChanged` 的改動，`_processRequests` 的參數 `currentState` 必須改為可空類型，並在處理需要遊戲狀態的 `action` 之前進行檢查。

1.  **修改簽名**: `void _processRequests(TurnBasedGameState<T> currentState, ...)` -> `void _processRequests(TurnBasedGameState<T>? currentState, ...)`
2.  **增加空值檢查**: 在處理 `game_action` 等需要當前狀態的請求前，檢查 `currentState` 是否為 `null`。`start_game` 請求則不受影響，因為它旨在創建第一個狀態。

```dart
// 擬代碼 (Pseudo-code)
void _processRequests(TurnBasedGameState<T>? currentState, List<RoomRequest> requests) { // 1. 修改簽名
  for (final request in requests) {
    final action = request.body['action'];
    if (action == 'start_game') {
      _handleStartGame(request); // 不需要 currentState
    } else if (action == 'game_action') {
      if (currentState != null) { // 2. 增加空值檢查
        _handleGameAction(currentState, request);
      }
    }
    // ...
  }
}
```

### 4. JSON 編碼/解碼問題檢查 (JSON Handling Review)

-   **解碼 (Decode)**: 透過在 `_onRoomStateChanged` 中為 `_parseGameState` 增加 `try-catch` 塊，我們解決了因非法 `body` 內容導致程序崩潰的問題。這是最主要的潛在風險。
-   **編碼 (Encode)**: `_updateRoomWithState` 中的編碼邏輯 (`jsonEncode(gameState.toJson(_delegate))`) 是安全的。它總是在一個結構完整的 `TurnBasedGameState<T>` 物件上操作，這個物件是在 `_handleStartGame` 或 `_handleGameAction` 內部被驗證和創建的，因此 `toJson` 和 `jsonEncode` 失敗的風險極低。

此修改確保了控制器在處理來自 Firestore 的數據時更加穩健。
