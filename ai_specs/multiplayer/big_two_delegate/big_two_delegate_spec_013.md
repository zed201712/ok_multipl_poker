## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-DELEGATE-013` |
| **標題 (Title)** | `REFACTOR PLAYABLE PATTERNS INPUT` |
| **創建日期 (Date)** | `2025/12/25` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 全面重構 `BigTwoDelegate` 及其相關方法，將卡牌處理邏輯從 `List<String>` 遷移至 `List<PlayingCard>`。
*   **目的：**
    1.  **型別安全 (Type Safety)：** 使用強型別 `PlayingCard` 替代字串，減少解析錯誤並明確定義資料結構。
    2.  **效能優化 (Performance)：** 減少在每次邏輯判斷中重複進行 `PlayingCard.fromString` 的轉換開銷。
    3.  **一致性 (Consistency)：** 確保 Delegate 內部 API 與 `FEAT-BIG-TWO-DELEGATE-012` 中引入的變更保持一致，使所有與牌型相關的方法都接受 `List<PlayingCard>`。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **基礎設施擴充 (Infrastructure Extensions)**
    *   在 `PlayingCard` (lib/game_internals/playing_card.dart) 中新增擴充方法：
        *   `List<String>.toPlayingCards()`: 轉為 `List<PlayingCard>`。
        *   `List<PlayingCard>.toStringCards()`: 轉為 `List<String>`。
    *   在 `BigTwoState` (lib/entities/big_two_state.dart) 中新增 getter：
        *   `bool get isFirstTurn`: 判斷是否為遊戲的第一回合 (基於 `discardCards`, `lastPlayedHand`, `deckCards` 狀態)。

2.  **Delegate API 簽名變更 (Signature Changes)**
    *   **輸入參數變更：**
        *   `getCardPattern(List<String> cardsStr)` -> `getCardPattern(List<PlayingCard> cards)`
        *   `checkPlayValidity(..., List<String> cardsPlayed, ...)` -> `checkPlayValidity(..., List<PlayingCard> cardsPlayed, {BigTwoCardPattern? playedPattern})`
        *   `isBeating(List<String> current, List<String> previous)` -> `isBeating(List<PlayingCard> current, List<PlayingCard> previous)`
        *   `validateFirstPlay(..., List<String> cardsPlayed)` -> `validateFirstPlay(..., List<PlayingCard> cardsPlayed)`
    *   **回傳型別變更：**
        *   `getPlayableCombinations` 與 `getAllPlayableCombinations` 的回傳值由 `List<List<String>>` 改為 `List<List<PlayingCard>>`。

3.  **調用端適配 (Callsite Adaptation)**
    *   **AI (`BigTwoPlayCardsAI`)**：更新以使用新的 `List<PlayingCard>` API，並利用 `isFirstTurn` 簡化邏輯。
    *   **UI (`BigTwoBoardWidget`)**：在調用 `checkPlayValidity` 前確保傳入 `List<PlayingCard>`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **Entities:** `lib/entities/big_two_state.dart`
*   **Core Logic:** `lib/game_internals/big_two_delegate.dart`
*   **Model:** `lib/game_internals/playing_card.dart`
*   **AI:** `lib/multiplayer/big_two_ai/big_two_play_cards_ai.dart`
*   **UI:** `lib/play_session/big_two_board_widget.dart`
*   **Tests:**
    *   `test/game_internals/big_two_delegate_test.dart`
    *   `test/game_internals/big_two_delegate_helpers_test.dart`
    *   `test/game_internals/big_two_delegate_ai_test.dart`
    *   `test/game_internals/playing_card_test.dart`
    *   `test/multiplayer/big_two_ai/big_two_play_cards_ai_test.dart`

#### **2.2 程式碼風格 (Style)**

*   使用 Extension Method 來處理型別轉換，保持程式碼簡潔。
*   Delegate 方法應優先處理 `PlayingCard` 物件，字串轉換應在邊界層 (UI/Network) 處理。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **單元測試：** 執行所有 `big_two_delegate` 相關測試，確保型別遷移後邏輯正確性不變。
2.  **功能測試：** 檢查 `isFirstTurn` 邏輯是否正確識別遊戲開始狀態。
3.  **整合測試：** 確認 AI 與 UI 能正確調用重構後的 Delegate 方法。

---

### **Section 4: Commit 程式碼分析與審查 (Analysis & Review)**

#### **4.1 變更摘要**
*   此變更為 `FEAT-BIG-TWO-DELEGATE-012` 的延伸，將重構範圍從「可出牌型計算」擴大至「核心規則判斷 (`checkPlayValidity`, `isBeating`)」。
*   引入 `isFirstTurn` 封裝了對初始回合的判斷邏輯，減少重複代碼。
*   UI 部分 (`BigTwoBoardWidget`) 需要配合 API 變更進行微調，特別是 `playButtonEnable` 的檢查邏輯。

#### **4.2 審查結論**
*   重構後的代碼類型更強，減少了潛在的 String 解析錯誤，並提升了代碼的可讀性與維護性。
