| **任務 ID (Task ID)** | `FEAT-BIG-TWO-DELEGATE-009` |
| **創建日期 (Date)** | `2025/12/24` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

改善 `BigTwoBoardWidget` 的使用者介面與 `BigTwoDelegate` 的程式碼結構。

1.  **資訊顯示**: 在 "Last Played" 區域旁顯示目前的 `lockedHandType`。
2.  **UI/UX 優化**:
    *   **按鈕高亮**: 根據玩家手牌，高亮顯示目前可組出的牌型 (Holding Patterns)。
    *   **視覺邊界**: 為 "Last Played" 和 "Table/Deck" 的 `ShowOnlyCardAreaWidget` 增加半透明背景 (`Colors.black` alpha 0.1) 以標示範圍。
3.  **重構 (Refactor)**: 將 `BigTwoBoardWidget` 中關於牌型判斷的 `switch-case` 邏輯移至 `BigTwoDelegate` 內部，封裝為 `selectNextPattern` 方法。

### 2. 設計思路 (Design Approach)

#### 2.1. `BigTwoDelegate` 修改
*   **新增 `selectNextPattern`**:
    *   為了避免與 `BigTwoDeckUtilsMixin` 的 `getNextPatternSelection` (接收 `finder` 參數) 發生名稱衝突，我們新增此方法。
    *   輸入：`hand`, `currentSelection` (List<String>), `pattern` (Enum)。
    *   邏輯：根據 `pattern` 選擇對應的 `find...` 方法，然後呼叫 mixin 的 `getNextPatternSelection`。注意 mixin 方法接收與回傳的是 `List<PlayingCard>`，但 `currentSelection` 通常是 `List<String>`，需要轉換。
*   **新增 `getHoldingPatterns`**:
    *   輸入：`List<PlayingCard> hand`。
    *   輸出：`Set<BigTwoCardPattern>`。
    *   邏輯：檢查手牌是否滿足各個 Pattern 的 `find...` 方法，若不為空則加入集合。這用於 UI 顯示「持有」的牌型。

#### 2.2. `BigTwoBoardWidget` 修改
*   **顯示 `lockedHandType`**:
    *   在 `Last Played` 文字旁顯示 `bigTwoState.lockedHandType`。需使用 `BigTwoCardPattern.fromJson` 解析並顯示 `displayName`。
*   **按鈕高亮**:
    *   在 `build` 方法中呼叫 `_bigTwoManager.getHoldingPatterns(_player.hand)`。
    *   在生成 `handTypeButtons` 時，若該 `pattern` 不在集合中，則將 `onPressed` 設為 null 或調整樣式。
*   **呼叫重構後的邏輯**:
    *   按鈕點擊時，改呼叫 `_bigTwoManager.selectNextPattern(...)`。
*   **背景裝飾**:
    *   將 `ShowOnlyCardAreaWidget` 包裹在 `Container` 中，設定背景色為 `Colors.black.withOpacity(0.1)`，並加上圓角。

### 3. 核心實作

#### `lib/game_internals/big_two_delegate.dart`

```dart
class BigTwoDelegate extends TurnBasedGameDelegate<BigTwoState> with BigTwoDeckUtilsMixin {
  // ... existing code

  /// 根據手牌回傳所有「持有」的牌型 (用於 UI 高亮)
  Set<BigTwoCardPattern> getHoldingPatterns(List<PlayingCard> hand) {
    final holding = <BigTwoCardPattern>{};
    if (findSingles(hand).isNotEmpty) holding.add(BigTwoCardPattern.single);
    if (findPairs(hand).isNotEmpty) holding.add(BigTwoCardPattern.pair);
    if (findStraights(hand).isNotEmpty) holding.add(BigTwoCardPattern.straight);
    if (findFullHouses(hand).isNotEmpty) holding.add(BigTwoCardPattern.fullHouse);
    if (findFourOfAKinds(hand).isNotEmpty) holding.add(BigTwoCardPattern.fourOfAKind);
    if (findStraightFlushes(hand).isNotEmpty) holding.add(BigTwoCardPattern.straightFlush);
    return holding;
  }

  /// 封裝後的選牌邏輯，接收 Enum
  List<String> selectNextPattern({
    required List<PlayingCard> hand,
    required List<String> currentSelection,
    required BigTwoCardPattern pattern,
  }) {
    List<List<PlayingCard>> Function(List<PlayingCard>)? finder;
    switch (pattern) {
      case BigTwoCardPattern.single:
        finder = findSingles;
        break;
      case BigTwoCardPattern.pair:
        finder = findPairs;
        break;
      case BigTwoCardPattern.straight:
        finder = findStraights;
        break;
      case BigTwoCardPattern.fullHouse:
        finder = findFullHouses;
        break;
      case BigTwoCardPattern.fourOfAKind:
        finder = findFourOfAKinds;
        break;
      case BigTwoCardPattern.straightFlush:
        finder = findStraightFlushes;
        break;
    }
    
    // 轉換 currentSelection 為 List<PlayingCard>
    final currentCards = currentSelection.map((s) => PlayingCard.fromString(s)).toList();

    // 呼叫 Mixin 的方法
    final nextSelectionCards = getNextPatternSelection(
      hand: hand,
      currentSelection: currentCards,
      finder: finder,
    );

    // 轉回 List<String>
    return nextSelectionCards.map((c) => PlayingCard.cardToString(c)).toList();
  }
}
```

#### `lib/play_session/big_two_board_widget.dart`

```dart
// ... inside build method

// 1. 取得所有持有的牌型
final holdingPatterns = _bigTwoManager.getHoldingPatterns(_player.hand);

// 2. 解析 lockedHandType
String lockedTypeDisplay = "";
if (bigTwoState.lockedHandType.isNotEmpty) {
    try {
        final pattern = BigTwoCardPattern.fromJson(bigTwoState.lockedHandType);
        lockedTypeDisplay = "(${pattern.displayName})";
    } catch (_) {}
}

// 3. 按鈕生成
final handTypeButtons = BigTwoCardPattern.values.map((pattern) {
  final isHolding = holdingPatterns.contains(pattern);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4.0),
    child: OutlinedButton(
      // 若不持有該牌型，禁用按鈕
      onPressed: isHolding ? () {
         final nextSelection = _bigTwoManager.selectNextPattern(
           hand: _player.hand,
           currentSelection: _player.selectedCards,
           pattern: pattern, 
         );
         if (nextSelection.isNotEmpty) {
           _player.setCardSelection(nextSelection);
         }
      } : null, 
      style: OutlinedButton.styleFrom(
        foregroundColor: isHolding ? null : Colors.grey,
        side: isHolding ? null : const BorderSide(color: Colors.grey),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(pattern.displayName),
    ),
  );
}).toList();

// ...

// 4. Last Played 區域背景與標題
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    if (bigTwoState.lastPlayedHand.isNotEmpty) ...[
      Text('Last Played $lockedTypeDisplay:'),
      Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ShowOnlyCardAreaWidget(
          cards: bigTwoState.lastPlayedHand.map((c) => PlayingCard.fromString(c)).toList(),
        ),
      ),
    ],
    // ... Deck area similarly wrapped
     const Text('Table/Deck:'),
     Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ShowOnlyCardAreaWidget(
           cards: bigTwoState.deckCards.map((c) => PlayingCard.fromString(c)).toList(),
        ),
     ),
  ],
)
```

### 4. 邏輯檢查與改善建議

1.  **JSON 解析**: `lockedHandType` 為 JSON 字串。使用 `BigTwoCardPattern.fromJson(str)` 是正確的做法。
2.  **Mixin 方法衝突與型別轉換**: 原本 `getNextPatternSelection` 接收的是 `List<PlayingCard> currentSelection`，但 UI 層 (`CardPlayer`) 常用 `List<String>`。在 `BigTwoDelegate.selectNextPattern` 中負責此轉換是合理的，保持了 UI 層的簡潔。
3.  **Holding vs Playable**: 使用 `getHoldingPatterns` 來高亮按鈕，這代表「我有這個牌型」，提供良好的 UX，避免了在選牌階段就進行過於複雜的規則驗證 (那是 `Play` 按鈕的職責)。

