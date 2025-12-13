## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                    |
| :--- |:--------------------------------------|
| **任務 ID (Task ID)** | `FEAT-DEMO-TIC-TAC-TOE-AI-PLAYER-003` |
| **創建日期 (Date)** | `2025/12/13`                          |
| **目標版本 (Target Version)** | `N/A`                                 |
| **專案名稱 (Project)** | `ok_multipl_poker`                    |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 重構 `TicTacToeGameAI` 的行為模式，使其從被動呼叫轉變為主動監聽。AI 將自主觀察 Firestore 狀態以決定何時加入遊戲，從而與 `TicTacToeGamePage` 完全解耦，更真實地模擬獨立玩家。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **重構 `TicTacToeGameAI` 類別：**
    *   AI 類別內部需持有自己專屬的 `FirestoreTurnBasedGameController` 和 `MockFirebaseAuth` 實例。
    *   **核心變更**：`TicTacToeGameAI` 的建構子需要接收 `FirebaseFirestore` 的實例，並立即開始監聽 `rooms` 集合的快照 (`snapshots()`)。
    *   **自主加入房間**：在監聽 `rooms` 集合的過程中，當 AI 偵測到符合以下條件的房間時，應自動使用自己的 `_gameController` 執行 `setRoomId` 以加入遊戲：
        *   房間狀態為 `matching`。
        *   房間參與者數量小於最大玩家數 (`maxPlayers`)。
        *   AI 自己尚未在該房間的參與者列表中。
    *   **保留原有行為**：AI 依然需要監聽自己內部的 `gameStateStream`。一旦成功加入房間並開始遊戲，此監聽器將負責觸發下棋 (`place_mark`) 和請求重置 (`request_restart`) 的邏輯。
    *   移除 `matchAndJoinRoom` 方法，因為 AI 現在的加入行為是自主的。

2.  **修改 `TicTacToeGamePage` 以移除對 AI 的主動控制：**
    *   在 `_TicTacToeGamePageState` 中，移除對 `_aiPlayer` 實例的直接方法呼叫。例如，在 `_matchRoom` 方法中，不再需要 `_aiPlayer?.matchAndJoinRoom()` 這行程式碼。
    *   `_TicTacToeGamePageState` 仍然負責在 AI 模式下創建 `TicTacToeGameAI` 的實例，並將共享的 `FakeFirebaseFirestore` 實例傳遞給它，但之後便不再與其互動。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/demo/tic_tac_toe_game_page.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **後端模擬**: 強制使用 `fake_cloud_firestore` 和 `firebase_auth_mocks` 套件。
*   **AI 邏輯**: AI 的決策應由 `FirebaseFirestore` 的 `snapshots()` 和 `gameStateStream` 的事件共同驅動。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`lib/demo/tic_tac_toe_game_page.dart` -> `TicTacToeGameAI` (示意):**
    ```dart
    class TicTacToeGameAI {
      late final FirestoreTurnBasedGameController<TicTacToeState> _gameController;
      late final StreamSubscription _gameStateSubscription;
      late final StreamSubscription _roomsSubscription;
      final FirebaseFirestore _firestore; // 共享的 Firestore 實例

      TicTacToeGameAI(this._firestore) {
        // 1. 初始化自己的 Auth 和 Controller
        // 2. 監聽 _firestore.collection('rooms').snapshots() 以尋找並加入房間
        // 3. 監聽 _gameController.gameStateStream 以在遊戲中行動
      }

      void _onRoomsSnapshot(QuerySnapshot snapshot) {
        // ... 尋找可加入的房間並呼叫 _gameController.setRoomId(roomId)
      }

      void _onGameStateUpdate(TurnBasedGameState<TicTacToeState>? gameState) {
        // ... 實作下棋和請求重置的邏輯 (與之前相同)
      }

      void dispose() { 
        _gameStateSubscription.cancel();
        _roomsSubscription.cancel();
        _gameController.dispose();
       }
    }
    ```

*   **`lib/demo/tic_tac_toe_game_page.dart` -> `_TicTacToeGamePageState`:**
    *   在 `_matchRoom` 方法中，移除對 `_aiPlayer` 的任何方法呼叫。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  重構 `lib/demo/tic_tac_toe_game_page.dart` 中的 `TicTacToeGameAI` 類別，使其能夠自主監聽並加入房間。
    2.  修改 `_TicTacToeGamePageState`，移除對 AI 的直接控制邏輯。
2.  **程式碼輸出：** 輸出 `lib/demo/tic_tac_toe_game_page.dart` 的 **完整程式碼內容**。

#### **3.2 驗證步驟 (Verification Steps)**

1.  **啟動頁面**：確認 UI 中出現了「與 AI 對戰」的開關。
2.  **啟用 AI 模式並配對**：打開開關，玩家點擊「配對」按鈕。由於 AI 會自動偵測到玩家創建的房間並加入，遊戲應能立即開始。
3.  **玩家下棋**：玩家在棋盤上任一位置下棋。
4.  **驗證 AI 反應**：確認在玩家下棋後，AI 能迅速在另一個空位自動下棋。
5.  **完成一局遊戲**：持續進行遊戲直到分出勝負或平手。
6.  **驗證遊戲結束與重置**：
    *   確認遊戲結束時，UI 顯示正確的勝負訊息。
    *   確認 AI 會自動請求重置。
    *   玩家點擊「重新開始」按鈕後，遊戲應立即重置並開始新的一局。
