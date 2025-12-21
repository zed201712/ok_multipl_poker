| **任務 ID (Task ID)** | `FEAT-BIG-TWO-DELEGATE-006` |
| **創建日期 (Date)** | `2025/12/21` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

修改 `lib/game_internals/big_two_delegate.dart`，實作完整的出牌規則驗證與狀態更新邏輯。
主要包含：更新 `lockedHandType`、實作 `_checkPlayValidity` 檢查函式、以及在回合結束 (`_nextTurn`) 時重置 `lastPlayedHand`。

### 2. 需求規格 (Requirements)

#### 2.1. 修改 `_playCards` 更新 `lockedHandType`
*   當玩家成功出牌後，需確保 `BigTwoState.lockedHandType` 被更新。
*   **更新規則**：`lockedHandType` 應更新為當前出牌 (`cardsPlayed`) 所對應的 `BigTwoCardPattern` 的 JSON 字串值。
    *   這確保了下家必須根據最新的強勢牌型進行跟牌或壓制 (例如：上家出鐵支壓制了順子，下家必須針對鐵支進行反應，此時 `lockedHandType` 應為 `FourOfAKind`)。

#### 2.2. 實作 `check` (驗證) 函式
在 `BigTwoDelegate` 中實作一個檢查方法 (例如命名為 `_validatePlayLogic` 或 `_checkPlayValidity`)，邏輯如下：

1.  **前置準備**: 解析 `cardsPlayed` 取得其 `BigTwoCardPattern` (設為 `playedPattern`)。若無法識別牌型則視為無效。
2.  **檢查流程**:
    *   取得當前 `state.lockedHandType`。
    *   **Case A: 自由出牌 (Free Turn)**
        *   若 `lockedHandType` 為空字串 (`''`)，則允許出任意合法的 `BigTwoCardPattern`。
    *   **Case B: 跟牌/壓牌 (Restricted Turn)**
        *   若 `lockedHandType` 不為空，將其解析為 `lockedPattern` (`BigTwoCardPattern.fromJson`)。
        *   **特殊壓制規則 (Bomb/Beat Logic)**:
            *   若 `playedPattern` 為 **Straight Flush (同花順)**，且 `lockedPattern` 不是 Straight Flush：**允許出牌** (同花順無條件壓制非同花順)。
            *   若 `playedPattern` 為 **Four of a Kind (鐵支)**，且 `lockedPattern` 不是 Straight Flush 且不是 Four of a Kind：**允許出牌** (鐵支壓制除了同花順與鐵支以外的牌型)。
        *   **一般規則 (Same Pattern)**:
            *   若不符合上述特殊規則，則 `playedPattern` 必須等於 `lockedPattern`。
            *   若牌型相同，則必須比較 `cardsPlayed` 與 `state.lastPlayedHand` 的大小。
            *   若 `cardsPlayed` 不大於 `lastPlayedHand`，則**不允許出牌**。

#### 2.3. 修改 `_nextTurn` 重置 `lastPlayedHand`
*   在 `_nextTurn` 方法中，當判斷回合結束 (Round Over，即 `passCount >= state.seats.length - 1`) 時：
    *   除了原有的重置邏輯 (`hasPassed`, `lockedHandType`) 外。
    *   **新增**: 將 `lastPlayedHand` 重置為空列表 `[]`。
        *   *註*: 需求描述為「空字串」，但因 `lastPlayedHand` 型別為 `List<String>`，故實作為清空列表。

### 3. 測試計畫 (Testing Plan)
*   建立或更新 `test/game_internals/big_two_delegate_test.dart`。
*   **測試案例建議**:
    1.  **Free Turn**: `lockedHandType=''` 時，出 Single, Pair, Straight 均應成功，且 `lockedHandType` 更新為對應牌型。
    2.  **Follow Pair**: `lockedHandType='Pair'`, `lastPlayedHand=['3C','3D']`.
        *   出 `['4C','4D']` (Pair, Bigger) -> Success.
        *   出 `['3H','3S']` (Pair, Bigger) -> Success.
        *   出 `['3C','3D']` (Same) -> Fail.
        *   出 `['4C']` (Single) -> Fail.
    3.  **Bomb (FourOfAKind)**:
        *   Locked=`Straight`. Play `FourOfAKind` -> Success. Locked becomes `FourOfAKind`.
        *   Locked=`FullHouse`. Play `FourOfAKind` -> Success.
        *   Locked=`FourOfAKind` (small). Play `FourOfAKind` (big) -> Success.
        *   Locked=`FourOfAKind`. Play `Straight` -> Fail.
    4.  **Bomb (StraightFlush)**:
        *   Locked=`FourOfAKind`. Play `StraightFlush` -> Success.
        *   Locked=`StraightFlush` (small). Play `StraightFlush` (big) -> Success.
        *   Locked=`StraightFlush`. Play `FourOfAKind` -> Fail.
    5.  **Strict 5-Card Rule**:
        *   Locked=`Straight`. Play `FullHouse` -> Fail (依據需求規則，非 Bomb 必須同牌型).

### 4. 邏輯檢查與改善建議 (Logic Review)
*   **規則確認**: 本規格採用的規則為「嚴格五張牌型 (Strict 5-card)」，即葫蘆不能壓順子，除非是鐵支或同花順。這與部分寬鬆規則 (葫蘆 > 順子) 不同，但符合需求描述。
*   **狀態一致性**: 確保 `_playCards` 在呼叫 `_nextTurn` 之前，傳入的 `state` 已經包含了正確的 `lockedHandType` 和 `lastPlayedHand`。然而 `_nextTurn` 若觸發 Round Over，會再次清空這些值，這是預期行為 (下家獲得自由出牌權)。
