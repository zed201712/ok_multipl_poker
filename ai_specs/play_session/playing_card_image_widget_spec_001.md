| **任務 ID (Task ID)** | `FEAT-PLAYING-CARD-IMAGE-WIDGET-001` |
| **創建日期 (Date)** | `2025/12/21` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

建立一個新的 Widget `PlayingCardImageWidget`，其功能與 `PlayingCardWidget` 相似，但支援自定義背景圖片，並將卡牌文字資訊（花色與數字）移動至左上角顯示。

### 2. 需求規格 (Requirements)

#### 2.1. 新增 `PlayingCardImageWidget` 類別
*   **檔案路徑**: `lib/play_session/playing_card_image_widget.dart`
*   **參數**:
    *   `PlayingCard card` (必填): 卡牌資料。
    *   `ImageProvider image` (必填): 用於顯示卡牌背景的圖片來源。
    *   `Player? player` (選填): 持有者，若不為空則啟用拖曳功能 (同 `PlayingCardWidget`)。
    *   `double? width`, `double? height` (選填): 允許自定義尺寸，預設值維持 `PlayingCardWidget` 的 `57.1` x `88.9`。

#### 2.2. 視覺樣式 (UI Design)
*   **背景**:
    *   使用 `Container` 的 `decoration` 屬性。
    *   將傳入的 `image` 設定為 `DecorationImage`，並設定 `fit: BoxFit.cover` 以填滿卡牌區域。
    *   保留圓角設計 (`borderRadius: BorderRadius.circular(5)`).
    *   保留邊框 (`border: Border.all(color: palette.ink)`).
*   **前景文字**:
    *   內容：顯示 `${card.suit.asCharacter}\n${card.value}`。
    *   位置：**左上角** (`Alignment.topLeft`)。
    *   Padding：加入適當的 Padding (建議 `4.0`) 避免文字緊貼邊框。
    *   樣式：維持原有的 `Theme` 與顏色邏輯 (紅/黑花色對應顏色)。

#### 2.3. 互動行為 (Interaction)
*   **拖曳功能**:
    *   若 `player` 參數不為 null，則包裹 `Draggable` widget。
    *   `feedback`, `childWhenDragging`, `onDragStarted`, `onDragEnd` 的邏輯與 `PlayingCardWidget` 保持一致。
    *   音效播放邏輯 (`AudioController`) 需保留。

### 3. 實作建議 (Implementation Details)

```dart
class PlayingCardImageWidget extends StatelessWidget {
  // ... constants

  final PlayingCard card;
  final ImageProvider image; // New parameter
  final Player? player;

  const PlayingCardImageWidget({
    required this.card,
    required this.image,
    this.player,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // ... palette and text color logic

    final cardWidget = DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium!.apply(color: textColor),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: palette.trueWhite,
          image: DecorationImage( // Use image here
            image: image,
            fit: BoxFit.cover,
          ),
          border: Border.all(color: palette.ink),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Align( // Change Center to Align
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              '${card.suit.asCharacter}\n${card.value}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    // ... Draggable logic
  }
}
```

### 4. 邏輯檢查與改善建議 (Review & Suggestions)
1.  **文字可讀性**: 當背景圖片較深或較花俏時，原本的黑色或紅色文字可能會看不清楚。
    *   *建議*: 可考慮在文字下方加入半透明的背景 (例如 `Container` with `color: Colors.white.withOpacity(0.8)`)，或是為文字加上陰影 (`Shadow`)。
2.  **圖片載入**: `ImageProvider` 載入過程中可能會有短暫空白。
    *   *建議*: 若有需要，可考慮設定 `Container` 的 `color` 作為預設背景色。

