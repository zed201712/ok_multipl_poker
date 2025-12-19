### **文件標頭 (Metadata)**

| 區塊 | 內容 | 目的/對 AI 的意義 |
| :--- |:---|:---|
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-BOARD-WIDGET-BIGTWO-005` | 方便追蹤和版本控制。 |
| **創建日期 (Date)** | `2025/12/17` | - |
| **目標版本 (Target Version)** | `N/A` | 完成 `BigTwoDelegate` 的建立與相關 UI 的重構。 |
| **專案名稱 (Project)** | `ok_multipl_poker` | - |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

此任務旨在完成 `spec_003` 和 `spec_004` 中尚未完成的部分。首先，建立並實作 `BigTwoDelegate`，這是遊戲核心邏輯的關鍵。其次，重構 `BigTwoBoardWidget`，使其不再依賴於舊的 `BigTwoBoardState`，而是透過 `FirestoreTurnBasedGameController` 和 `BigTwoState` 來驅動，並為 `SelectablePlayerHandWidget` 提供必要的 `CardPlayer` 物件。

#### **1.2 詳細需求 (Detailed Requirements)**

*   **建立 `BigTwoDelegate`:**
    *   在 `lib/game_internals/` 目錄下新增 `big_two_delegate.dart` 檔案。
    *   建立 `BigTwoDelegate` 類別，並繼承 `TurnBasedGameDelegate<BigTwoState>`。
    *   **實現 `TurnBasedGameDelegate` 的核心方法：**
        *   `stateFromJson(Map<String, dynamic> json)`
        *   `stateToJson(BigTwoState state)`
        *   `initializeGame(List<String> playerIds)`
        *   `processAction(BigTwoState currentState, String actionName, String participantId, Map<String, dynamic> payload)`
        *   `getCurrentPlayer(BigTwoState state)`
        *   `getWinner(BigTwoState state)`
    *   在 `processAction` 中，暫時不需實現完整的出牌邏輯，但需要能夠處理 `play_hand` 和 `pass` 的基本動作。

*   **重構 `BigTwoBoardWidget`:**
    *   修改 `lib/play_session/big_two_board_widget.dart`。
    *   移除對 `BigTwoBoardState` 的依賴。
    *   使用 `FirestoreTurnBasedGameController<BigTwoState>` 來取得遊戲狀態。
    *   建立並管理一個 `CardPlayer` ChangeNotifier，並根據從 `BigTwoState` 獲得的本地玩家手牌資料來更新它。
    *   實現 `Play` 按鈕的邏輯，從 `CardPlayer` 實例中讀取選中的牌，並呼叫 `gameController.performAction` 來執行出牌動作。

#### **1.3 邏輯檢查與改善建議 (Logic Check & Improvement Suggestions)**

*   **`BigTwoDelegate` 的出牌邏輯:** 在 `processAction` 中，雖然暫時不需實現完整的出牌邏輯，但應該要能夠驗證出牌的玩家是否為當前玩家。
*   **狀態管理:** `BigTwoBoardWidget` 將會是一個 `StatefulWidget`，它需要建立並維護一個 `CardPlayer` ChangeNotifier 作為本地 UI 狀態，並透過 `ChangeNotifierProvider` 提供給子元件。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **新增:**
    *   `lib/game_internals/big_two_delegate.dart`
*   **修改:**
    *   `lib/play_session/big_two_board_widget.dart`
    *   `lib/game_internals/card_player.dart` (可能需要調整以適應新的重構)

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **狀態管理:** 使用 `StreamBuilder` 來監聽 `FirestoreTurnBasedGameController` 的狀態變化，並結合 `ChangeNotifierProvider` 來管理本地 UI 狀態 (`CardPlayer`)。
*   **風格:** 遵循 `effective_dart` 程式碼風格，並為所有新的公開類別和方法添加 DartDoc 註解。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)**

1.  **執行計劃：** 簡要說明將如何依序建立 `BigTwoDelegate`，然後重構 `SelectablePlayerHandWidget` 和 `BigTwoBoardWidget`。
2.  **程式碼輸出：** 提供所有新增及修改後檔案的完整內容。

#### **3.2 驗證步驟 (Verification Steps)**

1.  確認 `lib/game_internals/big_two_delegate.dart` 已建立，並正確實現了 `TurnBasedGameDelegate` 的介面。
2.  確認 `SelectablePlayerHandWidget` 已被重構，改為直接依賴 `CardPlayer`。
3.  確認 `BigTwoBoardWidget` 已被重構，使用 `FirestoreTurnBasedGameController` 來管理狀態，並正確地提供了 `CardPlayer`。
4.  啟動 App 進入遊戲，驗證手牌的顯示、選牌功能正常。
5.  點擊 `Play` 按鈕，驗證遊戲狀態有被更新 (即使只是印出 log)。
