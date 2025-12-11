## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
| :--- |:---|
| **任務 ID (Task ID)** | `FEAT-DEMO-TIC-TAC-TOE-GAME-PAGE-003` |
| **創建日期 (Date)** | `2025/12/11` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 為井字棋 (Tic-Tac-Toe) 遊戲範例新增「重新開始」功能。此功能允許房間內的所有玩家共同決定重置遊戲，回到初始狀態。**為了保持架構簡潔，所有修改將限制在 `lib/demo/tic_tac_toe_game_page.dart` 檔案內。**

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **遊戲狀態 (`TicTacToeState`)**:
    1.  新增一個 `List<String> restartRequesters` 欄位，用於記錄已請求重新開始的玩家 ID。
    2.  更新 `fromJson` 和 `toJson` 方法以支援此新欄位。

*   **遊戲規則 (`TicTacToeDelegate`)**:
    1.  修改 `processAction` 方法以處理一個名為 `'request_restart'` 的新動作。
    2.  當收到 `'request_restart'` 動作時：
        *   將發起動作的玩家 `participantId` 加入 `restartRequesters` 列表中（如果尚未存在）。
        *   檢查 `restartRequesters` 列表的長度是否等於房間內的總玩家數。
        *   如果是，則呼叫 `initializeGame(playerIds)` 來回傳一個全新的初始遊戲狀態，從而重置遊戲。
        *   如果否，則僅回傳更新了 `restartRequesters` 列表的遊戲狀態。

*   **UI (`TicTacToeGamePage`)**:
    1.  新增一個「重新開始」按鈕，此按鈕應在遊戲進行中 (`gameStatus == GameStatus.playing`) 時可見。
    2.  點擊按鈕後，呼叫 `_gameController.sendGameAction('request_restart')`。
    3.  在 UI 上顯示當前已請求重新開始的玩家列表（例如，從 `gameState.customState.restartRequesters` 讀取）。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **唯一修改檔案：**
    *   `lib/demo/tic_tac_toe_game_page.dart`: 將在此檔案中實作所有相關的 UI、狀態和邏輯變更。

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **狀態管理:** 沿用現有的 `FirestoreTurnBasedGameController`，但將重置邏輯放在 `TicTacToeDelegate` 內處理。
*   **遊戲邏輯:** 透過在 `TurnBasedGameDelegate` 中新增動作 (`request_restart`) 的方式來擴充功能，而非修改 `Controller`。
*   **資料模型:** 遊戲狀態的變更將體現在 `TicTacToeState` 中，並透過現有 `Controller` 自動同步至 Firestore。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`TicTacToeState`:**
    *   **新增欄位**: `final List<String> restartRequesters;`

*   **`TicTacToeDelegate.processAction`:**
    *   **新增處理邏輯**: `if (actionName == 'request_restart') { ... }`

*   **`TicTacToeGamePage`:**
    *   **新增呼叫**: `_gameController.sendGameAction('request_restart')`

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  修改 `lib/demo/tic_tac_toe_game_page.dart` 中的 `TicTacToeState`，加入 `restartRequesters` 欄位並更新序列化方法。
    2.  在 `TicTacToeDelegate` 的 `processAction` 方法中，增加處理 `'request_restart'` 動作的邏輯。
    3.  在 `TicTacToeGamePage` 中，新增「重新開始」按鈕，並在其 `onPressed` 事件中呼叫 `_gameController.sendGameAction('request_restart')`。
    4.  更新 UI，顯示已請求重新開始的玩家。
2.  **程式碼輸出：** 提交對 `lib/demo/tic_tac_toe_game_page.dart` 的修改。

#### **3.2 驗證步驟 (Verification Steps)**

*   **按鈕可見性**: 確認「重新開始」按鈕在遊戲開始後正確顯示。
*   **單人請求**: 一位玩家點擊按鈕後，遊戲狀態不應重置，但 UI 應顯示該玩家已請求。
*   **全員請求**: 房間內所有玩家都點擊「重新開始」按鈕後，遊戲盤面應重置為初始狀態。
*   **狀態清除**: 遊戲重置後，`restartRequesters` 列表應為空，以便可以再次觸發重新開始流程。