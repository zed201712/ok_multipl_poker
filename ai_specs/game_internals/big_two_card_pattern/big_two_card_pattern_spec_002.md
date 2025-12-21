| **任務 ID (Task ID)** | `FEAT-BIG-TWO-CARD-PATTERN-002` |
| **創建日期 (Date)** | `2025/12/21` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

在 `BigTwoCardPattern` 及相關工具中新增「鐵支」 (Four of a Kind) 牌型。
在常見的大老二規則中，鐵支通常為 5 張牌 (4 張同點數 + 1 張任意牌)。

### 2. 需求規格 (Requirements)

#### 2.1. 修改 Enum `BigTwoCardPattern`
檔案：`lib/game_internals/big_two_card_pattern.dart`

1.  新增成員 `fourOfAKind` (對應 'Four of a Kind')。
    *   建議順序位於 `fullHouse` 與 `straightFlush` 之間。

#### 2.2. 修改 Mixin `BigTwoDeckUtilsMixin`
檔案：`lib/game_internals/big_two_deck_utils_mixin.dart`

1.  新增 `bool isFourOfAKind(List<PlayingCard> cards)`：
    *   檢查牌數是否為 5 張。
    *   檢查是否有 4 張牌點數相同。
2.  新增 `List<List<PlayingCard>> findFourOfAKinds(List<PlayingCard> cards)`：
    *   找出所有符合鐵支規則的組合。
    *   回傳排序後的牌型列表。

### 3. 實作建議 (Implementation Details)

**BigTwoCardPattern**:
```dart
enum BigTwoCardPattern {
  // ...
  fullHouse('Full House'),

  /// 鐵支 (Four of a Kind)
  fourOfAKind('Four of a Kind'),

  straightFlush('Straight Flush');
  // ...
}
```

**BigTwoDeckUtilsMixin**:
```dart
bool isFourOfAKind(List<PlayingCard> cards) {
  if (cards.length != 5) return false;
  final valueCounts = <int, int>{};
  for (final c in cards) {
    valueCounts[c.value] = (valueCounts[c.value] ?? 0) + 1;
  }
  return valueCounts.containsValue(4);
}

List<List<PlayingCard>> findFourOfAKinds(List<PlayingCard> cards) {
  if (cards.length < 5) return [];
  final List<List<PlayingCard>> result = [];
  final combinations = _combinations(cards, 5);
  for (final combo in combinations) {
    if (isFourOfAKind(combo)) {
      result.add(sortCardsByRank(combo));
    }
  }
  return result;
}
```

### 4. 驗證 (Verification)
檔案：`test/game_internals/big_two_deck_utils_test.dart`

*   測試 `isFourOfAKind` 能正確識別 4 張同點數 + 1 張雜牌。
*   測試 `findFourOfAKinds` 能從手牌中找出鐵支。
