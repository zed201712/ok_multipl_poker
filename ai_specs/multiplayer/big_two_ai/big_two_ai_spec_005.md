## AI 專案任務指示文件 (Feature Task)

| 區塊                        | 內容                                      |
|:--------------------------|:----------------------------------------| 
| **任務 ID (Task ID)**       | `FEAT-BIG-TWO-AI-005`                   |
| **標題 (Title)**            | `AI STRATEGY REFACTOR WITH DELEGATE HELPERS` |
| **創建日期 (Date)**           | `2025/12/23`                            |
| **目標版本 (Target Version)** | `N/A`                                   |
| **專案名稱 (Project)**        | `ok_multipl_poker`                      |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 重構 `BigTwoPlayCardsAI` 的 `_findBestMove` 方法，移除舊有的手動搜尋邏輯，全面改用 `BigTwoDelegate` (Spec 008) 提供的 AI 輔助函式 (`getAllPlayableCombinations`, `getPlayablePatterns` 等) 來進行決策。
*   **參考文件：** 
    *   `ai_specs/multiplayer/big_two_delegate/big_two_delegate_spec_008.md` (Delegate 方法定義)

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **準備工作 (Preparation)**
    *   在 `_findBestMove` 開頭，先將 AI 手牌 (`List<PlayingCard>`) 依照 Big Two 規則排序 (Rank 3..2, Suit C..S)，以便找出「手中最小的那張牌」。

2.  **情境 A：首局首手 (First Turn)**
    *   **判斷條件：** `state.lastPlayedHand` 為空 且 `state.lastPlayedById` 為空。
    *   **邏輯：**
        1.  找出 AI 手中最小的一張牌 (例如梅花 3，或若無 C3 則是手中最小的牌)。
        2.  呼叫 `_delegate.getAllPlayableCombinations(state, player)` 取得所有合法組合。
        3.  **過濾：** 只保留「包含該張最小牌」的組合。
        4.  **選擇：** 從過濾後的列表中，**隨機挑選**一個組合回傳。
        5.  若無合法組合 (理論上不應發生)，回傳 `null`。

3.  **情境 B：普通回合 (Normal Turn)** (Free Turn 或 跟牌)
    *   **步驟 1：取得合法牌型**
        *   呼叫 `_delegate.getPlayablePatterns(state, player)`。
    
    *   **步驟 2：依優先順位嘗試出牌**
        *   定義優先順序列表：
            1.  `BigTwoCardPattern.straightFlush`
            2.  `BigTwoCardPattern.fourOfAKind`
            3.  `BigTwoCardPattern.fullHouse`
            4.  `BigTwoCardPattern.straight`
            5.  `BigTwoCardPattern.pair`
            6.  `BigTwoCardPattern.single`
        *   依序遍歷上述列表，若該牌型存在於「合法牌型」中，則進行下一步。

    *   **步驟 3：取得並驗證組合**
        *   針對選定的 `pattern`，呼叫 `_delegate.getPlayableCombinations(state, player, pattern)`。
        *   若回傳的候選列表 (`candidates`) 為空，則繼續嘗試下一個優先順序的牌型。
        *   **安全檢查 (Safety Check)：**
            *   若 `pattern` 與 `state.lockedHandType` 相同 (即同牌型跟牌)，雖然 Delegate 應已過濾，但請顯式遍歷 `candidates`，確認 `_delegate.isBeating(candidate, state.lastPlayedHand, pattern)` 為真。
        *   **選擇策略：**
            *   若有多個合法候選組合，選擇 **數值最小** (Smallest Rank) 的一組，以保留大牌。

4.  **情境 C：無牌可出 (Pass)**
    *   若遍歷所有優先順序後仍無合法組合，回傳 `null` (代表 Pass)。

#### **1.3 測試需求 (Testing Requirements)** **【新增】**

*   **建立測試檔案：** `test/multiplayer/big_two_ai/big_two_play_cards_ai_test.dart`
*   **測試重點：**
    *   為了方便測試，建議將 `_findBestMove` 標註為 `@visibleForTesting` 並在測試中設法存取，或將其抽取為可獨立測試的邏輯 (例如 `BigTwoAIStrategy` class)，本次任務可先簡單將其設為 `public` 或使用 extension/reflect 方式測試 (建議直接設為 public `findBestMove` 或 `@visibleForTesting`)。
    *   **Mocking:** 需 Mock `BigTwoDelegate` 以控制 `getAllPlayableCombinations` 等方法的輸出，專注於測試 AI 的決策邏輯 (優先順序、最小牌選擇等)。
    *   **Test Cases:**
        *   **First Turn:** 確認必定打出包含最小牌的組合。
        *   **Free Turn Strategy:** 確認優先打出 StraightFlush > ... > Single。
        *   **Smallest Choice:** 確認在有多組同 Pattern 可出時，選擇最小的一組。
        *   **Pass:** 確認無牌可出時回傳 `null`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/multiplayer/big_two_ai/big_two_play_cards_ai.dart`
*   **新增：** `test/multiplayer/big_two_ai/big_two_play_cards_ai_test.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **Import:** 需確保引用了正確的 Enums (`BigTwoCardPattern`) 和 Delegate。
*   **Helper:** 利用 `_delegate` 現有的 Mixin 方法進行排序 (`sortCardsByRank`)。
*   **Testing:** 使用 `mockito` 或 `mocktail` 模擬 Delegate 行為。

#### **2.3 函式簽名範例 (Function Signatures)**

```dart
// In BigTwoPlayCardsAI
@visibleForTesting
List<String>? findBestMove(BigTwoState state, List<PlayingCard> hand) {
  // ... implementation
}
```

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **單元測試：** 執行 `flutter test test/multiplayer/big_two_ai/big_two_play_cards_ai_test.dart` 並確認所有測試案例通過。
2.  **整合模擬：**
    *   **首手測試：** 模擬 AI 為起始玩家，檢查 Log 是否打出包含最小牌的組合。
    *   **Free Turn 優先權測試：** 給予 AI 一手包含 葫蘆 (FullHouse) 和 單張 (Single) 的牌，在 Free Turn 時應優先打出 葫蘆。
    *   **跟牌測試：** 上家出 `Pair(3)`，AI 手中有 `Pair(4)` 和 `Pair(K)`，應優先打出 `Pair(4)` (最小策略)。
    *   **Pass 測試：** 上家出 `Single(2)`，AI 手中無大牌，應回傳 `null`。
