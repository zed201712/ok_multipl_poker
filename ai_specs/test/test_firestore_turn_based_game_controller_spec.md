| **任務 ID (Task ID)** | `TEST-MOCK-ROOM-STATE-CONTROLLER-002` |
| **創建日期 (Date)** | `2025/12/12` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 建立一個針對 `FirestoreTurnBasedGameController` 的單元測試套件。此測試將使用 `MockFirestoreRoomStateController` 作為其底層的房間狀態控制器，模擬真實情境下的房間狀態變化與玩家互動。

    測試的主要目的並非直接測試 `MockFirestoreRoomStateController` 的內部邏輯（這應由 `mock_firestore_room_state_controller_test.dart` 負責），而是驗證 `FirestoreTurnBasedGameController` 在收到來自（模擬的）房間狀態控制器事件時，能否正確地管理遊戲生命週期（配對、開始、玩家行動、離開）並透過 `gameStateStream` 發出正確的遊戲狀態。此方法參考了 `tic_tac_toe_game_page.dart` 中的實現方式，達到間接驗證 `MockFirestoreRoomStateController` 在整合使用情境下的行為是否符合預期。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **建立測試檔案：**
    *   在 `test/multiplayer/` 目錄下建立新檔案 `firestore_turn_based_game_controller_test.dart`。

*   **撰寫測試案例：**
    *   **遊戲流程整合測試 (Integration Flow):**
        1.  **玩家一配對房間：** 模擬玩家一呼叫 `matchAndJoinRoom`。驗證 `MockFirestoreRoomStateController` 的 `matchRoom` 被呼叫，並最終建立一個新房間。`gameStateStream` 應發出一個 `gameStatus` 為 `GameStatus.waiting` 的狀態。
        2.  **玩家二配對房間：** 模擬玩家二呼叫 `matchAndJoinRoom`。驗證玩家二成功加入同一房間。
        3.  **開始遊戲：** 模擬房間管理員（玩家一）呼叫 `startGame`。驗證 `MockFirestoreRoomStateController` 的 `sendRequest` 被呼叫以啟動遊戲。`gameStateStream` 應發出 `gameStatus` 為 `GameStatus.playing` 的狀態，且遊戲的 `customState` (井字棋棋盤) 已被初始化。
        4.  **玩家輪流行動：** 模擬玩家一和玩家二輪流呼叫 `sendGameAction` 下棋。驗證每次行動後 `gameStateStream` 都會發出更新後的棋盤狀態。
        5.  **玩家離開：** 模擬其中一位玩家呼叫 `leaveRoom`。驗證 `MockFirestoreRoomStateController` 的 `leaveRoom` 被呼叫，且 `gameStateStream` 會發出 `null` 或對應的結束狀態。
    *   **`sendGameAction` (sendRequest) 測試:**
        *   獨立測試呼叫 `sendGameAction` 時，`FirestoreTurnBasedGameController` 是否能正確地將遊戲動作打包並透過 `MockFirestoreRoomStateController` 的 `sendRequest` 方法發送出去。
    *   **遊戲重置流程測試:**
        *   模擬遊戲結束後 (例如井字棋產生贏家)，玩家呼叫 `sendGameAction` 發送 `request_restart` 動作。
        *   驗證當所有玩家都請求重置後，遊戲狀態 `customState` 會被重置為初始狀態。

---

### **Section 2: 改善建議與技術細節 (Improvements & Technical Scope)**

#### **2.1 程式碼邏輯分析與改善建議 (Analysis and Suggestions)**

在分析 `lib/demo/tic_tac_toe_game_page.dart` 中的 `TicTacToeDelegate` 時，發現一個潛在的邏輯問題：

*   **問題 (Problem):**
    `TicTacToeDelegate` 將 `_playerIds` 儲存為一個實例成員變數。這個變數僅在 `initializeGame` 方法被呼叫時才會被賦值。然而，如果應用程式重啟，`FirestoreTurnBasedGameController` 會從 Firestore（在此測試中為 Mock）恢復當前的遊戲狀態，但並不會重新呼叫 `initializeGame`。這將導致 `_playerIds` 成為一個空列表 `[]`。後續任何依賴 `_playerIds` 的操作（如 `processAction` 中判斷 'X'/'O' 或 `getCurrentPlayer`）都將會失敗或產生非預期行為。

*   **建議 (Suggestion):**
    為了讓 `TicTacToeDelegate` 變得更健壯且無狀態（Stateless），建議將 `playerIds` 直接整合到遊戲狀態 `TicTacToeState` 中。
    1.  在 `TicTacToeState` 類別中新增 `final List<String> playerIds;`。
    2.  同步更新 `TicTacToeState` 的建構子、`fromJson` 和 `toJson` 方法，使其能處理 `playerIds` 的序列化與反序列化。
    3.  修改 `TicTacToeDelegate.initializeGame`，在回傳的初始 `TicTacToeState` 中包含 `playerIds`。
    4.  修改 `TicTacToeDelegate` 中的 `processAction` 和 `getCurrentPlayer` 方法，讓它們從傳入的 `currentState.playerIds` 中讀取玩家列表，而不是從 `_playerIds` 成員變數中讀取。
    5.  移除 `TicTacToeDelegate` 中的 `_playerIds` 成員變數。

#### **2.2 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **新增：** `test/multiplayer/firestore_turn_based_game_controller_test.dart`
*   **修改 (建議):** `lib/demo/tic_tac_toe_game_page.dart` (應用上述改善建議)

#### **2.3 程式碼風格與技術棧 (Style & Stack)**

*   **測試框架：** 使用 `flutter_test` 與 `test` 套件。
*   **非同步測試：** 大量使用 `expectLater` 搭配 `emitsInOrder` 來驗證 `Stream` 在不同操作下的事件發射順序與內容是否正確。
*   **測試結構：** 使用 `group` 將相關測試案例分組，並在 `setUp` 中初始化 `MockFirestoreRoomStateController` 和 `FirestoreTurnBasedGameController`。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  建立 `ai_specs/test/test_firestore_turn_based_game_controller_spec.md` 檔案。
    2.  (下一步) 根據此規格文件中「改善建議」修改 `lib/demo/tic_tac_toe_game_page.dart`。
    3.  (下一步) 建立 `test/multiplayer/firestore_turn_based_game_controller_test.dart` 並撰寫完整的測試程式碼。

2.  **程式碼輸出：**
    *   輸出 `test_firestore_turn_based_game_controller_spec.md` 的完整內容。
    *   (後續步驟) 輸出修改後的 `tic_tac_toe_game_page.dart` 程式碼。
    *   (後續步驟) 輸出 `firestore_turn_based_game_controller_test.dart` 的完整程式碼。

#### **3.2 驗證步驟 (Verification Steps)**

*   執行 `flutter test test/multiplayer/firestore_turn_based_game_controller_test.dart`，並確保所有測試案例均能成功通過。
*   手動執行 Demo App，確認井字棋遊戲在採納改善建議後，功能依然正常。
