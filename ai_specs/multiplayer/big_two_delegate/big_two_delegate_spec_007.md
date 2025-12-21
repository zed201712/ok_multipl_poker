| **任務 ID (Task ID)** | `FEAT-BIG-TWO-DELEGATE-007` |
| **創建日期 (Date)** | `2025/12/21` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

公開 `BigTwoDelegate` 中的核心邏輯函式 (`getCardPattern`, `checkPlayValidity`, `isBeating`) 以便於單元測試驗證，並修正測試檔案中的潛在錯誤。

### 2. 需求規格 (Requirements)

#### 2.1. Refactor `BigTwoDelegate`
修改 `lib/game_internals/big_two_delegate.dart`，將以下私有方法改為公開方法 (移除底線):
*   `_getCardPattern` -> `getCardPattern`
*   `_checkPlayValidity` -> `checkPlayValidity`
*   `_isBeating` -> `isBeating`
*   注意：需同步更新該檔案內部的呼叫點。

#### 2.2. Update `BigTwoDelegateTest`
修改 `test/game_internals/big_two_delegate_test.dart`：

1.  **新增單元測試 (Unit Tests)**:
    *   針對 `getCardPattern`：測試各種牌型 (Single, Pair, Straight, FullHouse, FourOfAKind, StraightFlush, Invalid)。
    *   針對 `isBeating`：測試同牌型大小比較 (Single vs Single, Pair vs Pair, Straight vs Straight 等)。
    *   針對 `checkPlayValidity`：測試規則邏輯 (Locked type matching, Bombing conditions)。

2.  **修正現有測試 (Fix Integration Tests)**:
    *   檢視並修正 `bomb logic` 相關測試案例。
    *   確保測試資料 (Participants' hands) 與操作一致，避免因手牌不足導致 `processAction` 默默失敗。
    *   驗證 "Straight Flush beats Four of a Kind" 與 "Four of a Kind beats Straight" 的測試邏輯正確性。

### 3. 實作建議 (Implementation Details)

*   `BigTwoDelegate`: Replace `_getCardPattern` with `getCardPattern`, etc.
*   `BigTwoDelegateTest`:
    *   Add `test('getCardPattern identifies patterns correctly')`.
    *   Add `test('isBeating compares values correctly')`.
    *   Refine `test('bomb logic: ...')` to ensure `processAction` succeeds (check state changes).
