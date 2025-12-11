| **任務 ID (Task ID)** | `FEAT-TURN-BASED-CONTROLLER-005` |
| **創建日期 (Date)** | `2025/12/11` |

### 1. 目的 (Objective)

擴充 `FirestoreTurnBasedGameController` 的功能，允許遊戲管理員（房主）動態調整遊戲中的玩家順序 (`turnOrder`)。這對於需要手動設置順序或在遊戲過程中重新洗牌的場景非常有用。

本文件旨在規劃新增以下兩個功能：
1.  **指定順序**: 提供一個方法，允許房主傳入一個完整的玩家 ID 列表來設定 `turnOrder`。
2.  **隨機順序**: 提供一個方法，讓房主對當前房間內的所有玩家進行隨機排序，以更新 `turnOrder`。

### 2. Public 方法 (New Public Methods)

將在 `FirestoreTurnBasedGameController<T>` 中新增以下公開方法，供 UI 層調用。**這些方法僅應由房主 (Manager) 調用和執行**。

*   **`void setTurnOrder(List<String> turnOrder)`**:
    *   **描述**: 直接將遊戲的 `turnOrder` 設置為指定的列表。此方法只有房主能成功調用。
    *   **實現**:
        1.  驗證調用者是否為房主 (`isCurrentUserManager()`)，如果不是，則記錄錯誤並返回。
        2.  獲取當前的遊戲狀態 (`_gameStateController.value`)。
        3.  如果狀態存在，使用 `currentState.copyWith(turnOrder: turnOrder)` 創建一個新的遊戲狀態。
        4.  調用 `_updateRoomWithState(newGameState)` 將更新後的狀態寫回 Firestore。

*   **`void shuffleTurnOrder()`**:
    *   **描述**: 隨機排列當前房間內所有玩家，以生成新的 `turnOrder`。此方法只有房主能成功調用。
    *   **實現**:
        1.  驗證調用者是否為房主 (`isCurrentUserManager()`)，如果不是，則記錄錯誤並返回。
        2.  獲取當前遊戲狀態 (`_gameStateController.value`) 和房間狀態 (`_currentRoom`)。
        3.  如果狀態和房間存在，從 `_currentRoom.participants` 獲取玩家列表。
        4.  創建列表的副本並隨機排序 (`shuffledList.shuffle()`)。
        5.  使用 `currentState.copyWith(turnOrder: shuffledList)` 創建新狀態。
        6.  調用 `_updateRoomWithState(newGameState)` 將更新寫回 Firestore。
