| **任務 ID (Task ID)** | `FEAT-BIG-TWO-DELEGATE-004` |
| **創建日期 (Date)** | `2025/12/21` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

在 `lib/game_internals/big_two_delegate.dart` 中擴充 `BigTwoDelegate` 的功能，新增手牌排序與牌型分析的輔助函式。這將有助於前端顯示排序後的手牌，以及 AI 或提示系統分析可用牌型。

### 2. 需求規格 (Requirements)

#### 2.1. 新增 `sortCardsByRank` 函式
在 `BigTwoDelegate` 中新增一個函式 (可以是靜態或實例方法)，功能如下：
*   **輸入**: `List<PlayingCard> cards`
*   **輸出**: `List<PlayingCard>` (排序後的新列表或原地排序)
*   **排序邏輯**:
    1.  優先依照 **數字 (Rank)** 大小排序。
        *   採用大老二規則：3 < 4 < ... < 10 < J < Q < K < A < 2。
    2.  若數字相同，則比較 **花色 (Suit)**。
        *   花色大小：黑桃 (Spades) > 愛心 (Hearts) > 方塊 (Diamonds) > 梅花 (Clubs)。

#### 2.2. 新增 `sortCardsBySuit` 函式
在 `BigTwoDelegate` 中新增一個函式，功能如下：
*   **輸入**: `List<PlayingCard> cards`
*   **輸出**: `List<PlayingCard>`
*   **排序邏輯**:
    1.  優先依照 **花色 (Suit)** 大小排序。
        *   花色大小：黑桃 (Spades) > 愛心 (Hearts) > 方塊 (Diamonds) > 梅花 (Clubs)。
    2.  若花色相同，則比較 **數字 (Rank)**。
        *   採用大老二規則：3 < 4 < ... < 2。

#### 2.3. 新增 `findPairs` 函式
在 `BigTwoDelegate` 中新增一個函式，功能如下：
*   **輸入**: `List<PlayingCard> cards`
*   **輸出**: `List<List<PlayingCard>>`
*   **邏輯**:
    *   找出輸入牌組中所有可能的 **對子 (Pairs)** 組合。
    *   對子定義：兩張牌的 **數字 (Value/Rank)** 相同。
    *   **不重複**: 例如 `[A, B]` 和 `[B, A]` 視為相同組合，僅列出一次。
    *   **範例**: 若手牌有 `[♠3, ♥3, ♦3]`，應回傳 `[[♠3, ♥3], [♠3, ♦3], [♥3, ♦3]]` (順序可調整)。

### 3. 實作建議 (Implementation Details)

建議將這些功能實作為 `BigTwoDelegate` 的靜態工具方法或 `mixin`，以便測試與重複使用。

#### 3.1. 比較邏輯參考
需重用或提取 `BigTwoDelegate` 中現有的比較邏輯 (`_compareRank`, `_suitValue`)。

```dart
int getBigTwoValue(int value) {
  // 1 (Ace) -> 14, 2 -> 15, others keep value
  if (value == 1) return 14;
  if (value == 2) return 15;
  return value;
}

int getSuitValue(CardSuit suit) {
  switch (suit) {
    case CardSuit.spades: return 4;
    case CardSuit.hearts: return 3;
    case CardSuit.diamonds: return 2;
    case CardSuit.clubs: return 1;
  }
}
```

#### 3.2. 排序函式實作示意
```dart
List<PlayingCard> sortCardsByRank(List<PlayingCard> cards) {
  return List<PlayingCard>.from(cards)..sort((a, b) {
    int rankComp = getBigTwoValue(a.value).compareTo(getBigTwoValue(b.value));
    if (rankComp != 0) return rankComp;
    return getSuitValue(a.suit).compareTo(getSuitValue(b.suit));
  });
}

List<PlayingCard> sortCardsBySuit(List<PlayingCard> cards) {
  return List<PlayingCard>.from(cards)..sort((a, b) {
    int suitComp = getSuitValue(a.suit).compareTo(getSuitValue(b.suit));
    if (suitComp != 0) return suitComp;
    return getBigTwoValue(a.value).compareTo(getBigTwoValue(b.value));
  });
}
```

#### 3.3. 尋找對子實作示意
```dart
List<List<PlayingCard>> findPairs(List<PlayingCard> cards) {
  final List<List<PlayingCard>> pairs = [];
  // 先排序方便處理，或直接雙重迴圈
  for (int i = 0; i < cards.length; i++) {
    for (int j = i + 1; j < cards.length; j++) {
      if (cards[i].value == cards[j].value) {
        pairs.add([cards[i], cards[j]]);
      }
    }
  }
  return pairs;
}
```

### 4. 改善建議與邏輯檢查 (Improvements & Logic Check)

1.  **數字權重統一**: 目前 `BigTwoDelegate` 內部有 `_compareRank`，建議將其提取為公開的靜態方法 (如 `BigTwoRules.rankToBigTwoValue`)，避免邏輯散落在多處。
2.  **花色大小統一**: 確保 `_suitValue` 與 Spec 描述一致 (Spades > Hearts > Diamonds > Clubs)。注意 `playing_card.dart` 的 `CardSuit` enum 順序可能不同，必須依賴自定義的權重函式。
3.  **效能**: `findPairs` 使用雙重迴圈的時間複雜度為 O(N^2)。考慮到手牌數量通常較少 (最多 13 張)，這在效能上是可以接受的。若牌數很多，可先分組 (`groupBy`) 再組合。
4.  **回傳型別**: `findPairs` 回傳 `List<List<PlayingCard>>`，內層 List 建議固定長度為 2 或使用自定義 `Pair` 類別以增加型別安全性，但在本 Spec 中維持 `List<PlayingCard>` 即可。

### 5. 驗證 (Verification)
*   **Unit Test**: 針對上述三個函式撰寫單元測試。
    *   測試 `sortCardsByRank`: 輸入 `[♦2, ♠3, ♥3]`，預期輸出 `[♠3, ♥3, ♦2]` (♠3 < ♥3 < ... < ♦2)。
    *   測試 `sortCardsBySuit`: 輸入 `[♣3, ♠3]`，預期輸出 `[♠3, ♣3]` (Spades > Clubs)。
    *   測試 `findPairs`: 輸入 `[♠3, ♥3, ♦3]`，驗證輸出包含 3 組對子。

### 6. 實際實作變更 (Actual Implementation Changes)

根據 `commit 782ea052deee62c880db15e288dbcc5ce3e14938` 的實作結果，補充以下實作細節：

1.  **Mixin 抽離與實作 (`BigTwoDeckUtilsMixin`)**:
    *   建立 `lib/game_internals/big_two_deck_utils_mixin.dart`。
    *   將 `getBigTwoValue`, `getSuitValue`, `sortCardsByRank`, `sortCardsBySuit`, `findPairs` 實作為 Mixin 方法。
    *   `findPairs` 實作中增加了先排序 (`sortCardsByRank`) 的步驟，以確保輸出的對子順序固定。

2.  **`BigTwoDelegate` 重構**:
    *   `BigTwoDelegate` 現在混入 (`with`) `BigTwoDeckUtilsMixin`。
    *   移除 `BigTwoDelegate` 內部原有的 `_compareRank` 與 `_suitValue` 方法，改用 Mixin 提供的 `getBigTwoValue` 與 `getSuitValue`。
    *   更新 `_isBeating` 與 `_compareCards` 邏輯以使用 Mixin 方法。

3.  **測試新增**:
    *   建立 `test/game_internals/big_two_deck_utils_test.dart`。
    *   針對 Mixin 中的所有功能進行單元測試，包含數值轉換、花色權重、兩種排序方式與對子搜尋。
