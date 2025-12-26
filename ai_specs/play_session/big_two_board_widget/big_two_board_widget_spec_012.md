## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-UI-012` |
| **標題 (Title)** | `IMPLEMENT FLEX GRID LAYOUT FOR BOARD WIDGET` |
| **創建日期 (Date)** | `2025/12/26` |
| **更新日期 (Update)** | `2025/12/26` (Reflected Implementation) |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：**
    將 `BigTwoBoardWidget` 的佈局結構由 `Stack` 重構為 **Flex Grid (Column + Row)** 佈局。這是一種「絕對防禦型」的佈局策略，旨在徹底消除 UI 元件重疊的可能性，並統一全場景的卡牌尺寸。
*   **目的：**
    1.  **消除重疊 (Zero Overlap)：**透過強制性的區塊劃分（井水不犯河水），確保手牌、桌面牌與對手頭像絕對不會互相遮擋。
    2.  **尺寸統一 (Size Consistency)：** 引入全域的第二套卡牌尺寸常數 (`defaultWidth2`)，確保桌面、手牌、對手區的卡牌大小一致且適合 Grid 佈局。
    3.  **結構化佈局 (Structured Layout)：**使版面邏輯更類似網頁排版 (Grid-like)，易於預測與維護。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **佈局結構重構 (Layout Restructuring)**
    *   在 `FittedBox` 的 `SizedBox` 內部，移除原本的 `Stack`，改用垂直 `Column` 作為主要容器。
    *   **垂直劃分 (Vertical Split Ratio)：**
        *   **Top Area (Flex: 5)：** 放置上方對手 (Top Opponent)。
        *   **Middle Area (Flex: 10)：** 放置左右對手與桌面區域。
        *   **Bottom Area (Flex: 14)：** 放置玩家手牌 (Hand) 與操作按鈕 (Buttons)。

2.  **中間區域水平劃分 (Middle Row Split)**
    *   在 Middle Area 內部使用 `Row`：
        *   **Left (Width 10%)：** 左側對手 (`BigTwoBoardWidget.designSize.width * 0.1`)。
        *   **Center (Expanded)：** 桌面牌區 (`BigTwoBoardCardArea`)。
        *   **Right (Width 10%)：** 右側對手 (`BigTwoBoardWidget.designSize.width * 0.1`)。

3.  **卡牌尺寸統一 (Global Card Size)**
    *   在 `PlayingCardImageWidget` 定義新的靜態常數：
        *   `static final defaultWidth2 = 40.0;`
        *   `static final defaultHeight2 = ...` (依比例計算)。
    *   **應用範圍：** `BigTwoBoardCardArea` (桌面), `ShowOnlyCardAreaWidget` (展示), `SelectablePlayerHandWidget` (手牌), `DiscardPile` 等所有卡牌顯示元件，皆需統一使用此尺寸。

4.  **元件與間距微調 (Spacing & Refinement)**
    *   **BigTwoBoardCardArea:** 移除多餘的 `Padding`，使佈局更緊湊。
    *   **SelectablePlayerHandWidget:** 縮減按鈕與手牌間的距 (height: 2) 及 Padding (all: 2)。
    *   **CardContainer:** 調整 `RoundedLabel` 與 `child` 的排列順序。
    *   **YOUR TURN:** 字體大小縮小至 10 以適應 Grid 空間。

5.  **對手顯示邏輯更新**
    *   使用 `_buildTopOpponent`, `_buildLeftOpponent`, `_buildRightOpponent` 方法分配對手。
    *   依據玩家座位順序 (相對位置) 將對手映射至對應區塊。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/play_session/big_two_board_widget.dart` (Flex Grid Layout)
*   **修改：** `lib/play_session/playing_card_image_widget.dart` (New Size Constants)
*   **修改：** `lib/play_session/big_two_board_card_area.dart` (Layout & Size Update)
*   **修改：** `lib/play_session/selectable_player_hand_widget.dart` (Padding & Size Update)
*   **修改：** `lib/play_session/show_only_card_area_widget.dart` (Size Update)
*   **修改：** `lib/widgets/card_container.dart` (Layout Order)

#### **2.2 程式碼風格 (Style)**

*   遵循 `Effective Dart`。
*   使用 `Expanded(flex: N)` 進行垂直空間分配。
*   使用 `PlayingCardImageWidget.defaultWidth2` 作為卡牌尺寸的 Single Source of Truth。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **佈局確認：**
    *   確認畫面被垂直切分為 5:10:14 的比例。
    *   確認左右對手區域佔據寬度的 10%。
2.  **尺寸一致性：**
    *   檢查桌面牌、棄牌堆、手牌是否大小一致 (`40.0` 寬)。
3.  **重疊測試：**
    *   確認在不同螢幕尺寸下，各區塊邊界清楚，無重疊現象。

---

### **Section 4: 改善建議與邏輯檢查 (Review & Suggestions)**

#### **4.1 邏輯檢查與建議**

*   **Flex 比例微調：** 目前設定的 5:10:14 是基於 `896x414` 解析度的經驗值。若未來新增更多 UI 元素 (如聊天室)，可能需要重新調整 Flex 權重。
*   **左右對手空間：** 10% 的寬度對於顯示 13 張手牌 (即使是數字) 可能較為擁擠，`RotatedBox` 的使用在此處非常關鍵。需確保對手名字與牌數文字不溢出。

#### **4.2 提交訊息 (Commit Message)**

```text
feat: refactor board layout to flex grid with unified card size

Task: FEAT-BIG-TWO-UI-012

- Replaced Stack with Column/Row flex grid (Flex: 5/10/14).
- Introduced `PlayingCardImageWidget.defaultWidth2` for consistent 40.0 width across board.
- Updated TableCardArea, PlayerHand, and Opponent areas to use the new grid and card sizes.
- Refined spacing and padding for a tighter, non-overlapping layout.
```
