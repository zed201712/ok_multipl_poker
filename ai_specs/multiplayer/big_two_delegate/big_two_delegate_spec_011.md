## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-DELEGATE-011` |
| **標題 (Title)** | `STRICT STRAIGHT RANGE & VALIDATION` |
| **創建日期 (Date)** | `2025/12/23` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 修正 `BigTwoDelegate` 中順子 (Straight) 與同花順 (Straight Flush) 的判定與比較邏輯，嚴格限制合法的順子範圍。
*   **目的：**
    1.  **排除無效牌型：** 根據定義 `straightRange = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1]` (A, 2, 3...K, A)，只有在此序列中**連續的 5 張牌**才視為合法順子。
    2.  **Edge Case 處理：** `J-Q-K-A-2` ([11, 12, 13, 1, 2]) 與 `Q-K-A-2-3` 等跨越 `A` (除了 `10-J-Q-K-A` 與 `A-2-3-4-5` 以外) 的組合應視為**無效**。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **嚴格合法性檢查 (Strict Validation)**
    *   在 `BigTwoDelegate` 中 (建議於 `getCardPattern` 或覆寫 `isStraight`) 實作嚴格檢查。
    *   **合法順子列表 (Valid Straights)：**
        *   `A-2-3-4-5` (1, 2, 3, 4, 5)
        *   `2-3-4-5-6` (2, 3, 4, 5, 6)
        *   `3-4-5-6-7` ... `9-10-J-Q-K`
        *   `10-J-Q-K-A` (10, 11, 12, 13, 1)
    *   **非法範例 (Invalid)：**
        *   `J-Q-K-A-2` (雖然 Big Two 規則常見，但在本專案此 Spec 中明確定義為無效)。
        *   `Q-K-A-2-3`。

2.  **比較邏輯更新 (`_beatsSamePattern` & `_getStraightLevel`)**
    *   延續 Spec 010 的分級邏輯，但需確保只針對合法順子進行處理。
    *   **Level 2 (Max):** `2-3-4-5-6`。
    *   **Level 0 (Min):** `A-2-3-4-5`。
    *   **Level 1 (Normal):** 其他合法順子 (如 `10-J-Q-K-A`, `3-4-5-6-7`)。
    *   **同級比較：**
        *   若 Level 相同，比較該順子中**Big Two Rank 最大**的一張牌。
        *   注意：`A-2-3-4-5` 中 Big Two Rank 最大的是 `2`。`2-3-4-5-6` 中 Big Two Rank 最大的是 `2`。`10-J-Q-K-A` 中 Big Two Rank 最大的是 `A`。

3.  **實作位置建議**
    *   由於 `BigTwoDeckUtilsMixin` 可能被其他地方共用，且包含較寬鬆的判定，建議在 `BigTwoDelegate` 內部實作一個私有的 `_isStrictBigTwoStraight(List<PlayingCard> cards)`，並在 `getCardPattern` 中調用它來過濾 `isStraight` 的結果。
    *   `_beatsSamePattern` 需依賴 `getCardPattern` 的正確性 (即確保非法順子不會進入比較邏輯)。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/game_internals/big_two_delegate.dart`
*   **修改：** `test/game_internals/big_two_delegate_test.dart`

#### **2.2 程式碼風格 (Style)**

*   保持 `Effective Dart` 風格。
*   使用 Helper Function 封裝順序檢查邏輯，避免 Hardcode。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **單元測試 - 合法性 (`getCardPattern`)：**
    *   輸入 `J-Q-K-A-2` (`['C11', 'C12', 'C13', 'C1', 'C2']`) -> 預期回傳 `null` (非 `straight`)。
    *   輸入 `10-J-Q-K-A` (`['C10', 'C11', 'C12', 'C13', 'C1']`) -> 預期回傳 `straight` / `straightFlush`。
    *   輸入 `A-2-3-4-5` -> 預期回傳 `straight`。
2.  **單元測試 - 比較 (`isBeating`)：**
    *   驗證 `2-3-4-5-6` (Max) > `10-J-Q-K-A` (Normal)。
    *   驗證 `10-J-Q-K-A` (Normal) > `A-2-3-4-5` (Min)。
    *   驗證 `3-4-5-6-7` (Normal, 7-high) < `10-J-Q-K-A` (Normal, A-high)。

---

### **Section 4: Commit 程式碼分析與審查 (Analysis & Review)**

#### **4.1 邏輯檢查與改善建議**

*   **邏輯漏洞檢查：**
    *   原本 `BigTwoDeckUtilsMixin.isStraight` 判定較寬鬆 (包含 Big Two Values 連續)，這會導致 `J-Q-K-A-2` 被判定為 True。
    *   **改善建議：** 必須在 `BigTwoDelegate` 層級進行攔截。在 `getCardPattern` 判斷出 `isStraight` 為 True 後，額外呼叫 `_validateStrictStraightRange` 進行過濾。
*   **範圍定義確認：**
    *   `straightRange` 序列為 `1, 2, ..., 13, 1`。這意味著 `1` (Ace) 只能出現在首 (`1-2-3-4-5`) 或尾 (`10-11-12-13-1`)。任何試圖將 `1` 放在中間的組合 (如 `K-A-2`) 均不符合此連續序列。此定義明確且無歧義。

#### **4.2 審查結論**
*   本 Spec 旨在修正 `Spec 010` 對 Edge Case 的遺漏，並嚴格定義順子規則，提升遊戲邏輯的準確性。
