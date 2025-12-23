## AI 專案任務指示文件 (Feature Task)

| 區塊                        | 內容                                      |
|:--------------------------|:----------------------------------------| 
| **任務 ID (Task ID)**       | `FEAT-BIG-TWO-DELEGATE-009`             |
| **標題 (Title)**            | `REFACTOR IS_BEATING & PATTERN INFERENCE` |
| **創建日期 (Date)**           | `2025/12/23`                            |
| **目標版本 (Target Version)** | `N/A`                                   |
| **專案名稱 (Project)**        | `ok_multipl_poker`                      |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 重構 `BigTwoDelegate` 中的 `isBeating` 方法，移除外部傳入的 `pattern` 參數，改由內部推斷牌型。
*   **目的：**
    1.  **提升安全性：** 避免外部傳入錯誤的 `pattern` 導致比牌邏輯異常。
    2.  **簡化調用：** 調用者（如 AI 或 UI）只需提供兩手牌，無需先自行判斷牌型。
    3.  **集中邏輯：** 將「不同牌型之間的比大小」（如炸彈 vs 普通牌型）邏輯集中在 `isBeating` 內部處理。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **方法簽章變更 (Method Signature Change)**
    *   將 `bool isBeating(List<String> currentStr, List<String> previousStr, BigTwoCardPattern pattern)`
    *   修改為 `bool isBeating(List<String> currentStr, List<String> previousStr)`

2.  **內部邏輯實作 (Implementation Logic)**
    *   **長度檢查：** 若兩手牌張數不同，直接回傳 `false`（Big Two 規則通常要求張數相同，除非是 Reset）。
    *   **牌型推斷：** 內部調用 `getCardPattern` 取得 `currentPattern` 與 `previousPattern`。
    *   **比牌規則：**
        *   **相同牌型 (`current == previous`)：** 調用 `_beatsSamePattern` 進行同牌型比大小。
        *   **同花順 (`StraightFlush`)：** 若 `previous` 不是同花順，則回傳 `true`（同花順是最大炸彈）。
        *   **鐵支 (`FourOfAKind`)：** 若 `previous` 不是同花順且不是鐵支，則回傳 `true`（鐵支可壓過除同花順外的所有牌型）。
        *   **其他情況：** 回傳 `false`（不同牌型且非炸彈互壓，視為無法出牌）。

3.  **呼叫點更新 (Callsite Updates)**
    *   更新 `BigTwoDelegate.checkPlayValidity` 中的呼叫。
    *   更新 `BigTwoPlayCardsAI` 中的 AI 判斷邏輯。
    *   更新單元測試 `big_two_delegate_test.dart`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/game_internals/big_two_delegate.dart`
*   **修改：** `lib/multiplayer/big_two_ai/big_two_play_cards_ai.dart`
*   **修改：** `test/game_internals/big_two_delegate_test.dart`

#### **2.2 程式碼風格 (Style)**

*   保持 `Effective Dart` 風格。
*   `isBeating` 作為核心判斷函式，應保持 Pure Function 特性（不依賴外部 State，只依賴輸入參數）。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **單元測試更新：**
    *   移除原本測試案例中多餘的 `pattern` 參數。
    *   新增測試案例：傳入不同牌型但長度相同的情況（例如 5張 SF vs 5張 4K），驗證 `isBeating` 是否正確處理炸彈壓制。
2.  **AI 測試：**
    *   確認 AI 在計算 `verifiedCandidates` 時，能正確過濾出能打贏 `lastPlayedHand` 的牌組。

---

### **Section 4: Commit 程式碼分析與審查 (Analysis & Review)**

#### **4.1 Commit 6c54d8 分析**

*   **邏輯正確性 (Logic Correctness)：**
    *   **炸彈邏輯：** `StraightFlush` 的判斷優先級正確，能壓制所有非 SF 牌型。`FourOfAKind` 的判斷排在 SF 之後，且明確檢查 `previous != SF` 且 `previous != 4K`，邏輯正確。
    *   **同牌型比較：** 委派給 `_beatsSamePattern`，保留了原有的比大小邏輯（如花色、數字大小）。
    *   **安全性：** 加入了 `currentPattern == null || previousPattern == null` 的檢查，防止無效牌型導致崩潰。

*   **潛在風險與改善建議 (Improvements & Suggestions)：**
    1.  **效能考量 (Performance)：**
        *   目前 `isBeating` 內部會呼叫兩次 `getCardPattern`，而 `_beatsSamePattern` 內部又會重新 parse `PlayingCard.fromString`。
        *   **建議：** 若在 AI (MCTS) 大量模擬中成為瓶頸，可考慮優化 `_beatsSamePattern` 讓其接收已解析的 `List<PlayingCard>` 或已計算的 `Pattern` 物件，減少重複解析字串與判斷牌型的開銷。但在 UI 層級的互動頻率下，目前實作無效能問題。
    2.  **規則擴充性 (Rule Extensibility)：**
        *   目前的邏輯隱含了「非炸彈情況下，必須同牌型才能互打（如 FullHouse 不能打 Flush）」。這符合某些嚴格規則或目前的 `checkPlayValidity` 實作。
        *   **建議：** 若未來要支援「五張牌比大小（如 FullHouse 打贏 Flush）」的規則，需在 `currentPattern != previousPattern` 的 `else` 區塊中加入相應的階級比較邏輯。

#### **4.2 審查結論**
*   該 Commit 成功達成了重構目標，程式碼更為簡潔且不易誤用。邏輯無顯著錯誤。

