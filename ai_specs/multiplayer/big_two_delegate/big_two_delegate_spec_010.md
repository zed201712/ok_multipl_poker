## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-DELEGATE-010` |
| **標題 (Title)** | `CUSTOM STRAIGHT COMPARISON LOGIC` |
| **創建日期 (Date)** | `2025/12/23` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 修改 `BigTwoDelegate` 中針對 `Straight` 與 `StraightFlush` 的比大小邏輯 (`_beatsSamePattern`)。
*   **目的：**
    1.  實作特殊的順子大小規則：
        *   **最小順子：** `A-2-3-4-5` (Values: 1, 2, 3, 4, 5)。
        *   **最大順子：** `2-3-4-5-6` (Values: 2, 3, 4, 5, 6)。
        *   **其他順子：** 依循既有邏輯（比最大牌的 Big Two Rank）。
    2.  確保 `Straight` 與 `StraightFlush` 的比較均遵循此規則（同花順之間比較時）。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **邏輯變更 (`_beatsSamePattern`)**
    *   在處理 `BigTwoCardPattern.straight` 與 `BigTwoCardPattern.straightFlush` 時，需先判斷是否為特殊順子。
    *   **階級定義 (Hierarchy)：**
        *   **Level 2 (Max):** `2-3-4-5-6`。
        *   **Level 1 (Normal):** 其他所有順子 (e.g. `3-4-5-6-7`, `10-J-Q-K-A`)。
        *   **Level 0 (Min):** `A-2-3-4-5`。
    *   **比較流程：**
        1.  先比較雙方的階級 (Level)。
        2.  若階級不同，階級高者獲勝。
        3.  若階級相同（例如都是 `A-2-3-4-5`），則使用原本的 `_compareCards` 邏輯比較代表牌（通常是 Big Two Rank 最大的那張，即 `2`）。

2.  **輔助函式 (Helper Methods)**
    *   新增判斷函式以識別特殊牌型：
        *   `bool _isA2345(List<PlayingCard> cards)`: 檢查數值是否為 {1, 2, 3, 4, 5}。
        *   `bool _is23456(List<PlayingCard> cards)`: 檢查數值是否為 {2, 3, 4, 5, 6}。

3.  **相容性注意**
    *   `StraightFlush` 的內部比較（SF vs SF）也必須套用此順序規則。
    *   `_getStraightRankCard` 的既有邏輯（取 sorted list 的最後一張）在特殊牌型下仍然適用於同級比較（`A-2-3-4-5` 與 `2-3-4-5-6` 中，Big Two Rank 最大的牌皆為 `2`，故比較 `2` 的花色即可）。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/game_internals/big_two_delegate.dart`
*   **修改：** `test/game_internals/big_two_delegate_test.dart`

#### **2.2 程式碼風格 (Style)**

*   保持 `Effective Dart` 風格。
*   邏輯判斷應簡潔，避免過度複雜的巢狀 if-else。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **單元測試更新 (Unit Tests)：**
    *   **Case 1 (Min vs Normal):** `A-2-3-4-5` (Min) vs `3-4-5-6-7` (Normal, 7-high)。
        *   *預期：* `A-2-3-4-5` **輸給** `3-4-5-6-7` (雖然 2 > 7，但規則定義 Min < Normal)。
    *   **Case 2 (Max vs Normal):** `2-3-4-5-6` (Max) vs `J-Q-K-A-2` (Normal, 2-high)。
        *   *預期：* `2-3-4-5-6` **贏過** `J-Q-K-A-2` (雖然都是 2-high，但 Max > Normal)。
    *   **Case 3 (Max vs Min):** `2-3-4-5-6` vs `A-2-3-4-5`。
        *   *預期：* Max 贏。
    *   **Case 4 (Same Type):** `A-2-3-4-5` (Club 2) vs `A-2-3-4-5` (Diamond 2)。
        *   *預期：* Diamond 2 贏 (遵循既有花色大小)。

---

### **Section 4: Commit 程式碼分析與審查 (Analysis & Review)**

#### **4.1 邏輯檢查與改善建議**

*   **潛在問題 (Potential Issue):**
    *   既有的 `_getStraightRankCard` 會回傳 Big Two Rank 最大的牌。
        *   對於 `A-2-3-4-5`，最大牌是 `2`。
        *   對於 `3-4-5-6-7`，最大牌是 `7`。
    *   若不實作分級制度，直接比牌會導致 `A-2-3-4-5` (Rank 2) > `3-4-5-6-7` (Rank 7)，這與「`A-2-3-4-5` 最小」的規則衝突。
    *   **解決方案：** 必須如 Spec 所述，優先比較 Level，Level 相同才比 Card Rank。

*   **定義確認 (Definition Check):**
    *   Spec 中定義 `straightRange = [1..13, 1]` 僅作為順序參考。實作上以 `PlayingCard.value` (1-13) 判斷集合內容即可。
    *   `J-Q-K-A-2` (11, 12, 13, 1, 2) 視為 Normal (Level 1)。

#### **4.2 審查結論**
*   本 Spec 已釐清特殊順子的大小關係，解決了 `A-2-3-4-5` 在傳統 Big Two 排序中過強的問題，符合使用者需求。
