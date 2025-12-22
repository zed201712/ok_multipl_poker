## AI 專案任務指示文件 (Feature Task)

| 區塊                        | 內容                              |
|:--------------------------|:--------------------------------| 
| **任務 ID (Task ID)**       | `FEAT-BIG-TWO-DELEGATE-007`     |
| **標題 (Title)**            | `BIG-TWO-SEATS-AND-ERRORS` |
| **創建日期 (Date)**           | `2025/12/22`                    |
| **目標版本 (Target Version)** | `N/A`                           |
| **專案名稱 (Project)**        | `ok_multipl_poker`              |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 優化 Big Two 遊戲中的座位邏輯與錯誤訊息處理機制。主要包含：修正玩家座位排序邏輯以支援相對視角、引入 `ErrorMessageService` 將遊戲邏輯層的錯誤傳遞至 UI 顯示，以及重構 `BigTwoDelegate` 的依賴注入方式以確保實例一致性。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **座位邏輯重構 (Seating Logic)：**
    1.  **`BigTwoState` 修改：**
        *   將 `seatsParticipantList` 重新命名為 `seatedPlayersList` 以更準確描述用途。
        *   新增 `indexOfPlayerInSeats` 方法，用於計算特定玩家在座位表中的索引。
        *   更新 `nextPlayerId` 使用新的 `seatedPlayersList` 方法。
    2.  **相對視角排序 (Relative View)：**
        *   在 `BigTwoDelegate` 中更新 `otherPlayers` 方法。回傳的對手列表應根據當前玩家的視角進行相對排序（例如：下家、對家、上家）。

*   **錯誤訊息處理 (Error Handling)：**
    1.  **Service 整合：** 在 `BigTwoDelegate` 中引入 `ErrorMessageService`。
    2.  **錯誤回報：** 在 `processAction` 中發生邏輯錯誤或驗證失敗時，透過 `ErrorMessageService` 發送錯誤訊息。
    3.  **UI 顯示：** 在 `BigTwoBoardWidget` (測試模式下) 監聽錯誤訊息串流，並顯示於除錯文字框中。

*   **依賴注入與架構 (Dependency Injection)：**
    1.  **Delegate 單例化：** `BigTwoDelegate` 應由 `BigTwoBoardWidget` 創建一次，並注入至 `FirestoreBigTwoController` 及 `BigTwoPlayCardsAI` 中，確保各組件共用同一個 Delegate 實例 (及其內部的 `ErrorMessageService`)。

*   **狀態更新 (State Update)：**
    1.  **`processAction`：** 成功出牌後，需更新 `BigTwoState` 中的 `lastPlayedById` 欄位。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/entities/big_two_state.dart` (座位列表方法、索引查找)
*   **修改：** `lib/game_internals/big_two_delegate.dart` (注入 Service、相對座位運算、狀態更新)
*   **修改：** `lib/multiplayer/big_two_ai/big_two_play_cards_ai.dart` (接收 Delegate)
*   **修改：** `lib/multiplayer/firestore_big_two_controller.dart` (接收並傳遞 Delegate)
*   **修改：** `lib/play_session/big_two_board_widget.dart` (UI 顯示、Service 監聽、Delegate 創建)

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **慣例：** 
    *   保持 `BigTwoState` 的 Immutable 特性。
    *   使用 Dependency Injection (透過建構式) 傳遞 `BigTwoDelegate`。
    *   UI Widget 應根據 `testModeOn` 設定決定是否顯示除錯資訊。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`lib/entities/big_two_state.dart`:**
    ```dart
    List<BigTwoPlayer> seatedPlayersList();
    int? indexOfPlayerInSeats(String playerID, {List<BigTwoPlayer>? seatedPlayers});
    ```

*   **`lib/game_internals/big_two_delegate.dart`:**
    ```dart
    void setErrorMessageService(ErrorMessageService? service);
    // 更新 otherPlayers 邏輯，回傳相對排序後的列表
    List<BigTwoPlayer> otherPlayers(String myUserId, BigTwoState bigTwoState); 
    ```

*   **`lib/play_session/big_two_board_widget.dart`:**
    *   在 `_otherPlayerWidgets` 中根據視覺佈局 (Top, Left, Right) 重新排列 `otherPlayers`。
    ```dart
    List<Widget> _debugWidgets(BigTwoState bigTwoState);
    ```

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行結果：** 確認所有檔案已根據上述需求進行修改。
2.  **功能確認：** 
    *   座位排序正確，玩家看到的對手順序符合逆時針/順時針邏輯。
    *   測試模式下，錯誤操作會觸發 UI 上的錯誤訊息顯示。
    *   AI 運作正常，且使用正確的 Delegate 實例。

#### **3.2 驗證步驟 (Verification Steps)**

*   **座位驗證：** 進入 4 人遊戲，確認自己的畫面中，其他三位玩家的位置 (右、上、左) 對應實際的遊戲輪次順序。
*   **錯誤訊息驗證：** 開啟測試模式，嘗試進行非法出牌 (如：在只能出單張時出對子)，確認畫面上方是否顯示錯誤訊息。
*   **狀態更新驗證：** 出牌後，檢查 Firestore 或 Local State 中的 `lastPlayedById` 是否正確更新為出牌者 ID。
