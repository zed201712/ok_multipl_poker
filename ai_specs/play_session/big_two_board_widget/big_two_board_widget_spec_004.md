### **文件標頭 (Metadata)**

| 區塊 | 內容                                     | 目的/對 AI 的意義 |
| :--- |:---------------------------------------|:---|
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-BOARD-WIDGET-BIGTWO-004` | 方便追蹤和版本控制。 |
| **創建日期 (Date)** | `2025/12/16`                           | - |
| **目標版本 (Target Version)** | `N/A`                                  | 優化卡牌資料結構與相關 UI 元件。 |
| **專案名稱 (Project)** | `ok_multipl_poker`                     | - |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

延續 `big_two_board_widget_spec_003.md` 的重構工作，此任務的目標是進一步優化程式碼架構，將卡牌的字串表示法與 `PlayingCard` 物件之間的轉換邏輯，統一集中到 `PlayingCard` 類別中。同時，重構依賴此邏輯的相關 UI 元件，使其直接使用 `PlayingCard` 物件，從而提高程式碼的內聚性、可讀性和可維護性。

#### **1.2 詳細需求 (Detailed Requirements)**

*   **擴充 `PlayingCard` 類別:**
    *   在 `lib/game_internals/playing_card.dart` 中，為 `PlayingCard` 類別新增兩個靜態輔助方法：
        *   `PlayingCard fromString(String cardStr)`: 此工廠建構函式接收一個如 'S13' 或 'C3' 的字串，並回傳一個對應的 `PlayingCard` 物件。
        *   `String cardToString(PlayingCard card)`: 此方法接收一個 `PlayingCard` 物件，並回傳其對應的字串表示法 (例如 'S13')。
    *   `BigTwoDelegate` 中現有的 `_stringToCard` 和 `_cardToString` 邏輯應遷移至此。

*   **重構 `BigTwoDelegate`:**
    *   移除 `lib/game_internals/big_two_delegate.dart` 中私有的 `_stringToCard` 和 `_cardToString` 方法。
    *   改為呼叫 `PlayingCard.fromString()` 和 `PlayingCard.cardToString()` 來處理卡牌與字串之間的轉換。

*   **重構 `ShowOnlyCardAreaWidget`:**
    *   修改 `lib/play_session/show_only_card_area_widget.dart`。
    *   將其建構函式的參數從 `List<String> cards` 改為 `List<PlayingCard> cards`。
    *   移除 Widget 內部臨時的 `_stringToCard` 轉換邏輯。
    *   `BigTwoBoardWidget` 在使用此 Widget 時，需要先將 `BigTwoState` 中的卡牌字串列表轉換為 `PlayingCard` 物件列表。

*   **重構 `SelectablePlayerHandWidget`:**
    *   修改 `lib/play_session/selectable_player_hand_widget.dart`。
    *   將其建構函式的參數從 `List<String> cards` 改為 `List<PlayingCard> cards`。
    *   修改其 `onSelectionChanged` 回呼函式，使其回傳 `Set<PlayingCard>` 而不是 `Set<String>`。
    *   移除 Widget 內部臨時的 `_stringToCard` 轉換邏輯。
    *   對應地，`BigTwoBoardWidget` 也需要調整對此 Widget 的使用方式，處理 `Set<PlayingCard>` 的回傳值。


#### **1.3 邏輯檢查與改善建議 (Logic Check & Improvement Suggestions)**

*   **效能考量:** 在 `BigTwoBoardWidget` 的 `build` 方法中，每次重繪都會進行 `List<String>` 到 `List<PlayingCard>` 的轉換。雖然對於手牌這種小列表來說影響不大，但可以考慮使用 `compute` 或在 `StreamBuilder` 的 `builder` 外進行一次性轉換，以避免不必要的重複計算。
*   **一致性:** 確保所有與卡牌相關的邏輯都統一使用 `PlayingCard` 物件，只在需要序列化或與 `BigTwoState` 互動時才轉換為字串。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **修改:**
    *   `lib/game_internals/playing_card.dart`
    *   `lib/game_internals/big_two_delegate.dart`
    *   `lib/play_session/show_only_card_area_widget.dart`
    *   `lib/play_session/selectable_player_hand_widget.dart`
    *   `lib/play_session/big_two_board_widget.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **軟體架構:** 延續 `big_two_board_widget_spec_003.md` 的架構，強化關注點分離原則，將資料轉換邏輯內聚到資料模型本身。
*   **風格:** 遵循 `effective_dart` 程式碼風格。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)**

1.  **執行計劃：** 簡要說明將如何依序修改 `PlayingCard`，然後是 `Delegate`，最後是各個 UI 元件。
2.  **程式碼輸出：** 提供所有修改後檔案的完整內容。

#### **3.2 驗證步驟 (Verification Steps)**

1.  確認 `PlayingCard` 類別已新增 `fromString` 和 `cardToString` 方法。
2.  確認 `BigTwoDelegate`、`ShowOnlyCardAreaWidget` 和 `SelectablePlayerHandWidget` 中已移除私有的轉換邏輯，並改為使用 `PlayingCard` 的新方法。
3.  確認 `ShowOnlyCardAreaWidget` 和 `SelectablePlayerHandWidget` 的 props 已更新為接收 `PlayingCard` 物件。
4.  確認 `BigTwoBoardWidget` 已正確處理 `List<String>` 到 `List<PlayingCard>` 的轉換，並能將 `Set<PlayingCard>` 正確地用於遊戲動作。
5.  啟動 App 並進行一局遊戲，驗證手牌顯示、選牌、出牌等所有功能皆正常運作。
