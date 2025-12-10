| **任務 ID (Task ID)** | `FEAT-TURN-BASED-CONTROLLER-003` |
| **創建日期 (Date)** | `2025/12/10` |

### 1. 目的 (Objective)

本文件旨在進一步增強 `FirestoreTurnBasedGameController` 的功能，主要目標如下：

1.  **內部化遊戲狀態管理**: 將 `gameStatus` 的控制權從 `TurnBasedGameDelegate` 移交給 `FirestoreTurnBasedGameController`，使其負責管理遊戲的核心生命週期狀態。
2.  **實現自動開始遊戲**: 當遊戲房間處於 `matching` 狀態且玩家人數已滿時，由房主 (Manager) 自動觸發遊戲開始，簡化用戶操作。

### 2. 解決方案 (Solution)

#### 2.1. 遊戲狀態 (GameStatus) 管理重構

為了讓 `Controller` 管理遊戲生命週期，我們將進行以下修改：

1.  **定義 `GameStatus` Enum**:
    創建一個 `enum` 來明確定義遊戲的所有可能狀態。

    ```dart
    // lib/multiplayer/game_status.dart (new file)
    enum GameStatus {
      /// 初始狀態，尚未開始匹配
      idle,
      /// 正在等待玩家加入
      matching,
      /// 遊戲正在進行中
      playing,
      /// 遊戲已結束
      finished,
    }
    ```

2.  **修改 `TurnBasedGameDelegate`**:
    移除 `getGameStatus` 方法，因為 `Controller` 將直接管理 `gameStatus`。

    ```dart
    // lib/multiplayer/turn_based_game_delegate.dart (modification)
    abstract class TurnBasedGameDelegate<T> {
      // ... (其他方法)

      // REMOVED: String getGameStatus(T state);

      // ... (其他方法)
    }
    ```

3.  **修改 `TurnBasedGameState`**:
    `gameStatus` 字段的類型從 `String` 改為 `GameStatus`。

    ```dart
    // lib/multiplayer/turn_based_game_state.dart (modification)
    class TurnBasedGameState<T> {
      final GameStatus gameStatus; // Changed from String to GameStatus
      // ...
    }
    ```

4.  **`FirestoreTurnBasedGameController` 內部管理狀態**:
    `Controller` 將在其內部邏輯中直接更新 `gameStatus`。例如：
    -   調用 `matchAndJoinRoom` 成功後，狀態變為 `matching`。
    -   遊戲開始時（無論是手動或自動），狀態變為 `playing`。
    -   遊戲結束時（由 `Delegate` 的 `processAction` 判斷出勝負），狀態變為 `finished`。

    `Controller` 會提供一個內部方法來更新狀態並同步到 Firestore。

    ```dart
    // firestore_turn_based_game_controller.dart (pseudo-code)
    class FirestoreTurnBasedGameController<T> {
      // ...
      Future<void> _updateGameStatus(GameStatus newStatus) {
        // 1. 獲取當前 gameState
        // 2. 創建一個帶有 newStatus 的新 gameState 副本
        // 3. 調用 _updateRoomWithState 將新狀態寫入 Firestore
      }
    }
    ```

#### 2.2. 自動開始遊戲 (Automatic Game Start)

當房間人數達到 `maxPlayers` 時，遊戲將自動開始。

1.  **在 `matchAndJoinRoom` 中傳入 `maxPlayers`**:
    為了讓 `Controller` 知道何時人數已滿，`matchAndJoinRoom` 方法需要接收 `maxPlayers` 參數。

    ```dart
    // firestore_turn_based_game_controller.dart (pseudo-code)
    class FirestoreTurnBasedGameController<T> {
      int _maxPlayers = 0; // 內部保存

      Future<String> matchAndJoinRoom({required int maxPlayers, ...}) {
        _maxPlayers = maxPlayers;
        // ... 調用 _roomStateController.matchRoom() ...
      }
    }
    ```

2.  **在 `_onRoomStateChanged` 中加入自動開始邏輯**:
    房主 (Manager) 在每次房間狀態變更時，會檢查是否滿足自動開始的條件。

    ```dart
    // firestore_turn_based_game_controller.dart (pseudo-code for manager's logic)
    void _onRoomStateChanged(RoomState? roomState) {
      // ... (解析 gameState)

      if (_isCurrentUserTheManager(room)) {
        // ... (處理 requests)

        // 新增的自動開始邏輯
        if (gameState?.gameStatus == GameStatus.matching &&
            room.participants.length == _maxPlayers) {
          // 觸發開始遊戲的邏輯
          // 這會複用 `_handleStartGame` 的功能
          _handleStartGame(null); // 傳入 null 或一個虛擬的 request
        }
      }
    }
    ```
    - `_handleStartGame` 內部邏輯會創建初始遊戲狀態，並將 `gameStatus` 更新為 `GameStatus.playing`，然後同步到 Firestore。

### 3. 總結 (Summary)

這次重構將 `gameStatus` 的控制權收歸 `FirestoreTurnBasedGameController`，使其成為一個更完整的遊戲生命週期管理器。同時，自動開始功能優化了玩家體驗，減少了房主的等待和手動操作。此舉讓 `Delegate` 更純粹地聚焦於遊戲「規則」本身，而 `Controller` 則專注於遊戲「流程」控制，職責劃分更加清晰。
