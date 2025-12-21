| **任務 ID (Task ID)** | `FEAT-BIG-TWO-CARD-PATTERN-001` |
| **創建日期 (Date)** | `2025/12/21` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

參考 `lib/game_internals/playing_card.dart`，建立一個 Enum `BigTwoCardPattern`，將大老二遊戲中的牌型整理為列舉型別。
並提供屬性 (Property) 以支援 UI 顯示 (例如 `displayName` 或 `toJson`)，以便 `BigTwoBoardWidget` 等元件可以直接使用，替代原有的硬編碼字串列表。

### 2. 需求規格 (Requirements)

#### 2.1. 新增 Enum `BigTwoCardPattern`
在 `lib/game_internals/` 目錄下建立新的檔案 `big_two_card_pattern.dart`，並定義 `BigTwoCardPattern` Enum。

需包含以下牌型成員：
1.  `single` (對應 'Single')
2.  `pair` (對應 'Pair')
3.  `straight` (對應 'Straight')
4.  `fullHouse` (對應 'Full House')
5.  `straightFlush` (對應 'Straight Flush')

#### 2.2. 功能擴充 (Enhancements)
Enum 需包含以下功能：
1.  **`displayName` 屬性**: 回傳易讀的字串名稱，用於 UI 按鈕顯示。
    *   例如：`BigTwoCardPattern.single.displayName` 回傳 "Single"
2.  **JSON 序列化支援**: 
    *   提供 `toJson()` 方法：回傳 Enum 成員的名稱 (例如 'Single', 'Pair' 或 'single', 'pair'，需統一約定)。
    *   提供 `fromJson()` 靜態方法 (或 `fromString` factory)：根據字串解析回 Enum。
    *   建議 `toJson` 回傳與 `displayName` 相同的值，以相容既有的 `BigTwoBoardWidget` 硬編碼邏輯，或者如果後端已使用特定字串，則需匹配後端格式。
    *   *在此任務中，為相容 `BigTwoBoardWidget` 的 `['Single', 'Pair', ...]`，建議 `toJson()` 回傳與 `displayName` 一致的值。*

**風格要求**:
*   遵循 `effective_dart` 命名慣例。
*   為類別與公共成員添加詳細的 DartDoc 註解。

### 3. 實作建議 (Implementation Details)

```dart
/// 大老二 (Big Two) 遊戲中的合法牌型。
///
/// 用於識別玩家出的牌型是否合法，以及比牌邏輯。
enum BigTwoCardPattern {
  /// 單張 (Single)
  single('Single'),

  /// 對子 (Pair)
  pair('Pair'),

  /// 順子 (Straight)
  straight('Straight'),

  /// 葫蘆 (Full House)
  fullHouse('Full House'),

  /// 同花順 (Straight Flush)
  straightFlush('Straight Flush');

  /// 牌型的顯示名稱 (也是序列化用的字串值)。
  final String displayName;

  const BigTwoCardPattern(this.displayName);

  /// 將字串轉換為 [BigTwoCardPattern]。
  ///
  /// 如果字串無法匹配，則拋出 [ArgumentError]。
  static BigTwoCardPattern fromJson(String json) {
    return BigTwoCardPattern.values.firstWhere(
      (e) => e.displayName == json,
      orElse: () => throw ArgumentError('無效的牌型字串: $json'),
    );
  }
  
  /// 序列化為 JSON 字串。
  String toJson() => displayName;

  @override
  String toString() => displayName;
}
```

### 4. 驗證 (Verification)
*   確認 `BigTwoCardPattern` 具有 `displayName` 屬性且回傳正確字串 (e.g. 'Single', 'Full House')。
*   確認 `BigTwoCardPattern.fromJson('Single')` 正確回傳 `BigTwoCardPattern.single`。
*   確認 `BigTwoCardPattern.single.toJson()` 回傳 'Single'。
*   確認 `BigTwoBoardWidget` 可以使用 `BigTwoCardPattern.values.map((e) => e.displayName)` 來產生按鈕列表。
