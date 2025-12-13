## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                    |
| :--- |:--------------------------------------|
| **任務 ID (Task ID)** | `FEAT-DEMO-TIC-TAC-TOE-AI-PLAYER-002` |
| **創建日期 (Date)** | `2025/12/13`                          |
| **目標版本 (Target Version)** | `N/A`                                 |
| **專案名稱 (Project)** | `ok_multipl_poker`                    |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 在 `tic_tac_toe_game_page.dart` 中引入一個 AI 對手 (`TicTacToeGameAI`)。讓使用者可以選擇與 AI 對戰，並透過共享的 `FakeFirebaseFirestore` 實例來模擬一個完整、真實的線上多人遊戲體驗。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **新增 `TicTacToeGameAI` 類別：**
    *   在 `tic_tac_toe_game_page.dart` 文件中，建立一個名為 `TicTacToeGameAI` 的新類別。
    *   AI 類別內部需持有自己專屬的 `FirestoreTurnBasedGameController` 和 `MockFirebaseAuth` 實例，以模擬一個獨立的玩家。
    *   提供一個 `dispose` 方法來關閉其內部的 Controller 和 StreamSubscription。
    *   AI 必須監聽其 `gameStateStream`，以根據遊戲狀態的變化做出反應。

2.  **修改 `TicTacToeGamePage` 以整合 AI：**
    *   在 UI 中新增一個 `Switch` 或類似的控制項，讓使用者可以切換「與 AI 對戰」模式。
    *   當「與 AI 對戰」模式被啟動時：
        *   `TicTacToeGamePage` 在 `initState` 中應使用 `FakeFirebaseFirestore` 和 `MockFirebaseAuth`。
        *   同時，需要創建一個 `TicTacToeGameAI` 的實例。
        *   **關鍵要求**：`TicTacToeGamePage` 的 Controller 和 AI 的 Controller **必須共享同一個 `FakeFirebaseFirestore` 實例**，但使用各自獨立的 `MockFirebaseAuth` 實例。

3.  **實現 AI 的遊戲行為：**
    *   **自動配對**：當玩家點擊「配對」按鈕時，如果 AI 模式已啟用，`TicTacToeGameAI` 也應自動呼叫其 Controller 的 `matchAndJoinRoom` 方法以加入遊戲。
    *   **自動下棋**：AI 透過監聽 `gameStateStream`，判斷 `currentPlayerId` 是否為自己的 ID。如果是，則執行下棋邏輯：
        *   **下棋邏輯**：尋找棋盤 (`board`) 上第一個為空 (`''`) 的位置，並呼叫自己 Controller 的 `sendGameAction('place_mark', ...)` 在該位置下棋。
    *   **自動請求重置**：當遊戲結束 (`GameStatus.finished`) 時，AI 應自動呼叫 `sendGameAction('request_restart')` 來請求開始新的一局。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/demo/tic_tac_toe_game_page.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **後端模擬**: 強制使用 `fake_cloud_firestore` 和 `firebase_auth_mocks` 套件。
*   **AI 邏輯**: AI 的決策應由 `gameStateStream` 的事件驅動。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`lib/demo/tic_tac_toe_game_page.dart` -> `TicTacToeGameAI` (示意):**
    ```dart
    class TicTacToeGameAI {
      late final FirestoreTurnBasedGameController<TicTacToeState> _gameController;
      late final StreamSubscription _subscription;
      final FirebaseFirestore _firestore; // 共享的 Firestore 實例

      TicTacToeGameAI(this._firestore) {
        // 1. 初始化自己的 Auth 和 Controller
        // 2. 監聽 gameStateStream
      }

      void onGameStateUpdate(TurnBasedGameState<TicTacToeState>? gameState) {
        // 3. 實作下棋和請求重置的邏輯
      }

      Future<void> matchAndJoinRoom() { ... }

      void dispose() { ... }
    }
    ```

*   **`lib/demo/tic_tac_toe_game_page.dart` -> `_TicTacToeGamePageState`:**
    *   新增 `_isAiMode` 狀態變數和對應的 `Switch`。
    *   在 `initState` 中，根據 `_isAiMode` 決定是使用真實 Firebase 還是 `FakeFirebaseFirestore`。
    *   在 `_matchRoom` 方法中，如果 `_isAiMode` 為 true，則同時觸發 `_aiPlayer.matchAndJoinRoom()`。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  修改 `lib/demo/tic_tac_toe_game_page.dart`，加入 `TicTacToeGameAI` 類別的完整實作。
    2.  修改 `_TicTacToeGamePageState` 以整合 AI 模式的 UI 和邏輯。
2.  **程式碼輸出：** 輸出 `lib/demo/tic_tac_toe_game_page.dart` 的 **完整程式碼內容**。

#### **3.2 驗證步驟 (Verification Steps)**

1.  **啟動頁面**：確認 UI 中出現了「與 AI 對戰」的開關。
2.  **啟用 AI 模式並配對**：打開開關，點擊「配對」按鈕。遊戲應能立即開始。
3.  **玩家下棋**：玩家在棋盤上任一位置下棋。
4.  **驗證 AI 反應**：確認在玩家下棋後，AI 能迅速在另一個空位自動下棋。
5.  **完成一局遊戲**：持續進行遊戲直到分出勝負或平手。
6.  **驗證遊戲結束與重置**：
    *   確認遊戲結束時，UI 顯示正確的勝負訊息。
    *   確認 AI 會自動請求重置。
    *   玩家點擊「重新開始」按鈕後，遊戲應立即重置並開始新的一局。
