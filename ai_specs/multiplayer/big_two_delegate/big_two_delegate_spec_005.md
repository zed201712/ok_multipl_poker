| **任務 ID (Task ID)** | `FEAT-BIG-TWO-DELEGATE-005` |
| **創建日期 (Date)** | `2025/12/21` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

擴充 `BigTwoDeckUtilsMixin` 以支援 `BigTwoCardPattern` 中定義的所有牌型 (Single, Pair, Straight, Full House, Straight Flush) 的搜尋 (`find`) 與檢查 (`check`) 功能。
同時，重構 `BigTwoBoardWidget` 中的選牌邏輯，將其通用化並移動至 `BigTwoDelegate` (或其 Mixin) 中，以便重複使用於不同牌型。

### 2. 需求規格 (Requirements)

#### 2.1. 擴充 `BigTwoDeckUtilsMixin` 牌型邏輯
在 `lib/game_internals/big_two_deck_utils_mixin.dart` 中新增以下方法：

1.  **Single (單張)**
    *   `bool isSingle(List<PlayingCard> cards)`: 檢查是否為單張。
    *   `List<List<PlayingCard>> findSingles(List<PlayingCard> cards)`: 回傳所有單張組合 (其實就是每一張牌)。

2.  **Pair (對子)**
    *   `bool isPair(List<PlayingCard> cards)`: 檢查是否為對子。
    *   `List<List<PlayingCard>> findPairs(List<PlayingCard> cards)`: (已存在，需確認功能完整)。

3.  **Straight (順子)**
    *   `bool isStraight(List<PlayingCard> cards)`: 檢查是否為 5 張數字連續的牌。
        *   *規則註記*: 需考慮 A 與 2 的特殊情況 (例如 3-4-5-6-7, ..., 10-J-Q-K-A, A-2-3-4-5, 2-3-4-5-6)。若規則暫未詳細定義，先以標準 Rank (A=1, ..., K=13) 連續性為準，或支援 Big Two 常見順子。
    *   `List<List<PlayingCard>> findStraights(List<PlayingCard> cards)`: 找出所有可能的順子組合。

4.  **Full House (葫蘆)**
    *   `bool isFullHouse(List<PlayingCard> cards)`: 檢查是否為 3 張同數字 + 1 對子。
    *   `List<List<PlayingCard>> findFullHouses(List<PlayingCard> cards)`: 找出所有葫蘆組合。

5.  **Straight Flush (同花順)**
    *   `bool isStraightFlush(List<PlayingCard> cards)`: 檢查是否為同花色的順子。
    *   `List<List<PlayingCard>> findStraightFlushes(List<PlayingCard> cards)`: 找出所有同花順組合。

#### 2.2. 新增通用選牌輔助方法
在 `BigTwoDeckUtilsMixin` (或 `BigTwoDelegate`) 中新增方法，用於計算「下一個建議的選牌組合」。

*   **方法簽章建議**:
    ```dart
    List<PlayingCard> getNextPatternSelection({
      required List<PlayingCard> hand,
      required List<PlayingCard> currentSelection,
      required List<List<PlayingCard>> Function(List<PlayingCard>) finder,
    })
    ```
*   **邏輯**:
    1.  呼叫 `finder(hand)` 取得所有合法組合 (`candidates`)。
    2.  若 `candidates` 為空，回傳空列表。
    3.  若 `currentSelection` 在 `candidates` 中：
        *   回傳 `candidates` 中的下一個組合 (Index + 1)。
        *   若已是最後一個，則回到第一個 (循環)。
    4.  若 `currentSelection` 不在 `candidates` 中 (或為空)，回傳 `candidates` 的第一個組合。

#### 2.3. 更新 `BigTwoBoardWidget`
*   修改 `lib/play_session/big_two_board_widget.dart`。
*   移除原有的硬編碼 `BigTwoCardPattern.pair` 處理邏輯。
*   改用 `BigTwoDelegate` 提供的 `getNextPatternSelection` 方法，並根據按鈕對應的 `BigTwoCardPattern` 動態傳入對應的 `finder` (如 `findPairs`, `findFullHouses` 等)。

### 3. 實作建議 (Implementation Details)

#### 3.1. `BigTwoDeckUtilsMixin` 擴充

```dart
mixin BigTwoDeckUtilsMixin {
  // ... existing code ...

  bool isSingle(List<PlayingCard> cards) => cards.length == 1;

  List<List<PlayingCard>> findSingles(List<PlayingCard> cards) {
     return sortCardsByRank(cards).map((c) => [c]).toList();
  }

  bool isPair(List<PlayingCard> cards) => cards.length == 2 && cards[0].value == cards[1].value;

  // findPairs already exists

  bool isStraight(List<PlayingCard> cards) {
    if (cards.length != 5) return false;
    // 簡易實作：先排序，檢查數值連續
    // 進階實作需處理 A, 2 的特殊順序
    // 這裡建議先將 cards 依 "邏輯數值" (Logically 3..2) 或 "實際數值" (3..15) 排序後檢查
    // 但 Straight 判斷通常依賴 1..13 序列，除了 2 可接在 A 後面等變體
    return false; // TODO: Implement
  }

  List<List<PlayingCard>> findStraights(List<PlayingCard> cards) {
    // TODO: Implement search algorithm
    return [];
  }
  
  // ... check/find for FullHouse, StraightFlush ...

  /// 通用選牌邏輯
  List<PlayingCard> getNextPatternSelection({
      required List<PlayingCard> hand,
      required List<PlayingCard> currentSelection,
      required List<List<PlayingCard>> Function(List<PlayingCard>) finder,
  }) {
      final candidates = finder(hand);
      if (candidates.isEmpty) return [];

      final eq = const DeepCollectionEquality.unordered();
      
      // 尋找目前選擇是否在候選名單中
      int currentIndex = -1;
      if (currentSelection.isNotEmpty) {
        currentIndex = candidates.indexWhere((c) => eq.equals(c, currentSelection));
      }

      if (currentIndex == -1) {
        return candidates.first;
      } else {
        return candidates[(currentIndex + 1) % candidates.length];
      }
  }
}
```

#### 3.2. `BigTwoBoardWidget` 使用方式

```dart
// 在按鈕 callback 中
onPressed: () {
  List<List<PlayingCard>> Function(List<PlayingCard>)? finder;
  switch (pattern) {
    case BigTwoCardPattern.single:
      finder = _bigTwoManager.findSingles;
      break;
    case BigTwoCardPattern.pair:
      finder = _bigTwoManager.findPairs;
      break;
    case BigTwoCardPattern.straight:
      finder = _bigTwoManager.findStraights;
      break;
    // ... cases for fullHouse, straightFlush
  }

  if (finder != null) {
    final nextSelection = _bigTwoManager.getNextPatternSelection(
      hand: _player.hand,
      currentSelection: _player.selectedCards,
      finder: finder,
    );
    if (nextSelection.isNotEmpty) {
      _player.setCardSelection(nextSelection);
    }
  }
}
```

### 4. 驗證 (Verification)
*   執行 `test/game_internals/big_two_deck_utils_test.dart`，確保新增的 `find/check` 方法正確運作。
*   手動測試 UI：點擊 "Pair" 按鈕，應在手牌中的對子間循環切換。
*   手動測試 UI：點擊 "Straight" 等按鈕，若有對應牌型應選取。
