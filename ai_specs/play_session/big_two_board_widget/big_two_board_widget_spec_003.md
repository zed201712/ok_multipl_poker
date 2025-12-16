### **文件標頭 (Metadata)**

| 區塊 | 內容 | 目的/對 AI 的意義 |
| :--- |:---|:---|
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-BOARD-WIDGET-BIGTWO-003` | 方便追蹤和版本控制。 |
| **創建日期 (Date)** | `2025/12/16` | - |
| **目標版本 (Target Version)** | `N/A` | 重構大老二遊戲邏輯與狀態管理。 |
| **專案名稱 (Project)** | `ok_multipl_poker` | - |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

參照 `tic_tac_toe_game_page.dart` 中 `TicTacToeState` 與 `TicTacToeDelegate` 的設計模式，重構大老二的遊戲核心。此任務旨在將遊戲狀態（State）與遊戲邏輯（Delegate）明確分離，以提升程式碼的模組化、可測試性，並為將來的多人連線功能奠定穩固的基礎。

#### **1.2 詳細需求 (Detailed Requirements)**

*   **建立遊戲狀態實體 (`BigTwoState`):**
    *   在 `lib/entities/` 目錄下新增 `big_two_state.dart` 檔案。
    *   建立 `BigTwoState` 類別，並使用 `json_serializable` 來自動生成 `fromJson`/`toJson` 方法。
    *   **狀態屬性應包含：**
        *   `final List<BigTwoPlayer> participants;`: 遊戲中的所有參與者資訊
        *   `final List<String> seats;`: 玩家 `uid` 的列表，代表從莊家開始的輪流順序。
        *   `final String currentPlayerId;`: 當前輪到出牌的玩家 `uid`。
        *   `final List<String> lastPlayedHand;`: 最後一組被打出的有效手牌。
        *   `final String lastPlayedById;`: 最後出牌的玩家 `uid`。
        *   `final String? winner;`: 贏家 `uid`，遊戲結束時設置。
        *   `final int passCount;`: 連續 pass 的玩家數量。

*   **建立遊戲邏輯代理 (`BigTwoDelegate`):**
    *   參考 `TicTacToeDelegate`，將原 `BigTwoBoardState` 的邏輯職責遷移。在 `lib/game_internals/` 目錄下新增 `big_two_delegate.dart` 檔案。
    *   建立 `BigTwoDelegate` 類別，並繼承 `TurnBasedGameDelegate<BigTwoState>`。
    *   **實現 `TurnBasedGameDelegate` 的核心方法：**
        *   `stateFromJson(Map<String, dynamic> json)`: 從 JSON 還原 `BigTwoState`。
        *   `stateToJson(BigTwoState state)`: 將 `BigTwoState` 轉換為 JSON。
        *   `initializeGame(List<String> playerIds)`:
            *   建立初始 `BigTwoState`。
            *   決定 `seats` (玩家順序，擁有梅花3的玩家優先)。
            *   洗牌並將 52 張牌平均發給 4 位玩家，更新 `playerDecks`。
            *   設置 `currentPlayerId` 為擁有梅花3的玩家。
        *   `processAction(BigTwoState currentState, String actionName, String participantId, Map<String, dynamic> payload)`:
            *   處理 `play_hand` 動作：驗證玩家 `participantId` 是否為 `currentPlayerId`，驗證 `payload` 中的手牌是否合法、是否大於 `lastPlayedHand`。如果合法，則更新狀態。
            *   處理 `pass` 動作：驗證玩家，更新 `passCount`。如果所有其他玩家都 pass，則重置 `passCount` 和 `lastPlayedHand`，讓最後出牌者開始新的一輪。
        *   `getCurrentPlayer(BigTwoState state)`: 回傳 `state.currentPlayerId`。
        *   `getWinner(BigTwoState state)`: 檢查是否有玩家的手牌為空，若有則回傳其 `uid`。

*   **更新 UI 與控制器:**
    *   修改 `BigTwoBoardWidget` (及相關 widgets)，使其透過 `FirestoreTurnBasedGameController<BigTwoState>` 來監聽遊戲狀態變化及發送玩家動作。
    *   移除或重構舊的 `BigTwoBoardState` 類別，將其職責轉移至 `BigTwoState` 和 `BigTwoDelegate`。

#### **1.3 邏輯檢查與改善建議 (Logic Check & Improvement Suggestions)**

*   **卡牌表示法:** 建議統一卡牌的字串表示法，例如：花色 (C, D, H, S) + 點數 (1-13)。A 和 2 在大老二中是最大的牌，需要特別處理其排序值。可以在 Delegate 中定義一個排序函數。
*   **出牌邏輯 (`processAction`):**
    *   需要一個全面的 `HandValidator` 輔助類別來判斷出牌的組合（單張、對子、順子、同花、葫蘆、鐵支、同花順）是否合法。
    *   需要一個 `HandComparator` 輔助類別來比較兩組手牌的大小。
*   **遊戲流程:** `getCurrentPlayer` 的邏輯需要更詳細：當一輪結束後（所有其他玩家都 pass），下一個出牌者應是 `lastPlayedById`。當遊戲剛開始時，則是擁有梅花3的玩家。
*   **狀態簡化:** `participants` 和 `seats` 存在資訊重疊。可以考慮只保留 `seats` (List<String> of uids)，然後另外有一個 `Map<String, UserProfile>` 來查詢玩家的詳細資訊（如名稱），這樣可以讓核心遊戲狀態更輕量。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **新增:**
    *   `lib/entities/big_two_state.dart`
    *   `lib/game_internals/big_two_delegate.dart`
    *   `test/game_internals/big_two_delegate_test.dart` (建議為新邏輯新增單元測試)
*   **修改:**
    *   `lib/play_session/big_two_board_widget.dart` (更新以使用新的 Controller 和 State)
    *   `lib/multiplayer/firestore_turn_based_game_controller.dart` (可能需要泛型調整以適應)
    *   (其他使用到舊 `BigTwoBoardState` 的相關檔案)
*   **刪除:**
    *   `test/game_internals/big_two_board_state_test.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **狀態管理:** 繼續使用 `provider` 結合 `StreamBuilder` 來驅動 UI 更新。
*   **非同步序列化:** 使用 `json_serializable` 和 `build_runner`。
*   **介面化:** 透過繼承 `TurnBasedGameDelegate` 實現標準化的遊戲邏輯介面。
*   **風格:** 遵循 `effective_dart` 程式碼風格，並為所有新的公開類別和方法添加 DartDoc 註解。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)**

1.  **執行計劃：** 簡要說明將如何依序建立 `BigTwoState`、`BigTwoDelegate`，並重構相關 UI 元件。
2.  **程式碼輸出：** 提供所有新增及修改後檔案的完整內容。

#### **3.2 驗證步驟 (Verification Steps)**

1.  確認 `lib/entities/big_two_state.dart` 和 `lib/game_internals/big_two_delegate.dart` 已建立。
2.  確認 `BigTwoState` 包含所有指定的屬性，並已整合 `json_serializable`。
3.  確認 `BigTwoDelegate` 正確實現了 `TurnBasedGameDelegate` 的所有方法。
4.  確認 `initializeGame` 能夠正確洗牌、發牌，並找到擁有梅花3的玩家作為先手。
5.  確認 `processAction` 能夠正確處理合法的出牌和 pass 動作，並拒絕不合法的動作。
6.  確認 `BigTwoBoardWidget` 等 UI 元件已遷移至新的狀態管理模式，並能正確反應遊戲狀態（如手牌、當前玩家、出牌區）。
7.  啟動 App 進入遊戲，完整玩一局大老二，驗證發牌、出牌、pass、判斷勝利等環節功能正常。

---

### **Section 4: 執行總結 (Implementation Summary)**

#### **4.1 已完成任務 (Completed Tasks)**
*   **核心狀態與邏輯建立:**
    *   已建立 `BigTwoState` (`lib/entities/big_two_state.dart`) 作為遊戲的核心狀態容器，並整合 `json_serializable`。
    *   已建立 `BigTwoPlayer` (`lib/entities/big_two_player.dart`) 來儲存每個玩家的資訊。
    *   已建立 `BigTwoDelegate` (`lib/game_internals/big_two_delegate.dart`) 並實作了 `TurnBasedGameDelegate` 介面，將遊戲的核心邏輯 (如初始化、出牌、pass) 集中管理。
*   **UI 層重構:**
    *   已重構 `BigTwoBoardWidget` (`lib/play_session/big_two_board_widget.dart`)，使其透過 `FirestoreTurnBasedGameController` 和 `StreamBuilder` 來監聽 `BigTwoState` 的變化，實現了 UI 和業務邏輯的解耦。
    *   已重構 `ShowOnlyCardAreaWidget` 和 `SelectablePlayerHandWidget`，使其不再直接依賴舊的 `BoardState` 或 `Provider`，而是透過 props 接收數據。
*   **舊程式碼清理:**
    *   已重構 `PlaySessionScreen` (`lib/play_session/play_session_screen.dart`)，移除了對舊 `BigTwoBoardState` 的依賴。
    *   已安全刪除不再使用的 `BigTwoBoardState` (`lib/game_internals/big_two_board_state.dart`)。

#### **4.2 待辦事項 (Follow-up Tasks)**
*   部分元件 (如 `ShowOnlyCardAreaWidget`, `SelectablePlayerHandWidget`, `BigTwoDelegate`) 中包含了臨時的卡牌字串轉換邏輯。
*   需要將這些轉換邏輯統一移至 `PlayingCard` 類別中，並重構相關元件。
*   這些待辦事項已移至新的規格文件 `big_two_board_widget_spec_004.md` 中進行追蹤。
