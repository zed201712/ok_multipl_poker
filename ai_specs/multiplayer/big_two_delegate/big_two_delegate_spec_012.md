## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-DELEGATE-012` |
| **標題 (Title)** | `REFACTOR PLAYABLE PATTERNS INPUT` |
| **創建日期 (Date)** | `2025/12/24` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 重構 `BigTwoDelegate` 中的可出牌型計算函式 (`getPlayablePatterns`, `getPlayableCombinations`, `getAllPlayableCombinations`)，將輸入參數由 `BigTwoPlayer` 改為更底層的 `List<PlayingCard> handCards`。
*   **目的：**
    1.  **解耦 (Decoupling)：** 這些純計算函式不需要依賴 `BigTwoPlayer` 物件，只需知道手牌即可。這使得它們更容易測試，且在 AI 模擬 (Simulation) 中更容易使用（AI 常需模擬不同手牌情境，無需建構完整的 Player 物件）。
    2.  **效能 (Performance)：** AI 進行 MCTS 或其他搜尋演算法時，直接傳遞 Card List 比重複建構 Player 物件更輕量。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **API 簽名變更 (Signature Changes)**
    *   在 `lib/game_internals/big_two_delegate.dart` 中：
        *   `getPlayablePatterns(BigTwoState state, BigTwoPlayer player)` 改為 `getPlayablePatterns(BigTwoState state, List<PlayingCard> handCards)`
        *   `getPlayableCombinations(BigTwoState state, BigTwoPlayer player, BigTwoCardPattern pattern)` 改為 `getPlayableCombinations(BigTwoState state, List<PlayingCard> handCards, BigTwoCardPattern pattern)`
        *   `getAllPlayableCombinations(BigTwoState state, BigTwoPlayer player)` 改為 `getAllPlayableCombinations(BigTwoState state, List<PlayingCard> handCards)`

2.  **調用端更新 (Callsite Updates)**
    *   **AI 邏輯 (`big_two_play_cards_ai.dart`)：**
        *   在 `findBestMove` 中，原本為了調用 delegate 而創建了 `tempPlayer`。現在可以直接傳入 `sortedHand` (List<PlayingCard>)，刪除 `tempPlayer` 的創建代碼。
    *   **測試代碼 (`big_two_delegate_helpers_test.dart`, `big_two_delegate_ai_test.dart`)：**
        *   修改測試呼叫，傳入 `player.cards.map(PlayingCard.fromString).toList()` 而非 `player`。

3.  **邏輯保持 (Logic Preservation)**
    *   內部邏輯不做變更，僅替換資料來源從 `player.cards` 變為參數 `handCards`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/game_internals/big_two_delegate.dart`
*   **修改：** `lib/multiplayer/big_two_ai/big_two_play_cards_ai.dart`
*   **修改：** `test/game_internals/big_two_delegate_helpers_test.dart`
*   **修改：** `test/game_internals/big_two_delegate_ai_test.dart`

#### **2.2 程式碼風格 (Style)**

*   保持 `Effective Dart` 風格。
*   參數 `List<PlayingCard> handCards` 應假設傳入前**已排序**或是函式內部自行排序？
    *   既有邏輯中 `findSingles` 等 helper 內部會做 `sortCardsByRank`。為了安全起見，Delegate 方法內部可視情況排序或依賴 helper 的排序。既有 helper (`BigTwoDeckUtilsMixin`) 通常會自行排序。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **單元測試執行：**
    *   執行 `flutter test test/game_internals/big_two_delegate_helpers_test.dart`，確保重構後通過所有測試。
    *   執行 `flutter test test/game_internals/big_two_delegate_ai_test.dart`，確保 AI 相關測試通過。
2.  **邏輯確認：**
    *   確認 AI 在 `findBestMove` 中不再需要 `tempPlayer`，直接傳遞 `sortedHand`。

---

### **Section 4: Commit 程式碼分析與審查 (Analysis & Review)**

#### **4.1 潛在影響分析**

*   **破壞性變更 (Breaking Change)：** 這是對 `BigTwoDelegate` 公開 API 的修改。任何其他直接調用這些方法的地方都會報錯（目前看來只有 AI 和測試）。
*   **測試資料準備：** 測試檔案中需要將 String List 轉換為 PlayingCard List，這稍微增加了一點測試代碼的長度，但語意更明確。

#### **4.2 審查結論**
*   此重構符合 Clean Code 原則，減少了不必要的物件依賴，有利於後續 AI 優化。
