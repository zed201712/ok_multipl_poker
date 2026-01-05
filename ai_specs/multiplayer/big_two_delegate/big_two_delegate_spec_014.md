## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-UI-LAYOUT-014` |
| **標題 (Title)** | `BOARD LAYOUT REFACTOR & CARD AREA LIST` |
| **創建日期 (Date)** | `2026/01/05` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 重構 `BigTwoBoardWidget` 的佈局，將所有對手玩家移至畫面頂部區域顯示，並改進 `DiscardDialog` 的卡牌顯示方式。
*   **目的：**
    1.  **佈局優化 (Layout Optimization)：** 將原本分佈於左、上、右的對手玩家統一移至頂部，釋放桌面兩側空間，可能為了適應不同螢幕尺寸或未來的佈局需求。
    2.  **UI 視覺提升 (Visual Improvement)：** 更新對手玩家手牌 (`_OpponentHand`) 的樣式，增加 Passing 狀態的視覺區別 (顏色淡化)，並優化頭像與資訊的排列。
    3.  **棄牌堆顯示優化 (Discard Pile Display)：** 使用新的 `ShowOnlyCardAreaList` 替換原有的 `ShowOnlyCardAreaWidget`，支援 Grid 佈局顯示棄牌堆，解決大量卡牌顯示問題。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **Board Widget 佈局變更 (`BigTwoBoardWidget`)**
    *   **對手區域調整：**
        *   移除左右兩側欄位中的對手顯示 (保留佔位 `SizedBox`)。
        *   在頂部區域 (`_buildTopOpponent` 位置) 使用 `Row` 統一顯示所有對手 (Left, Top, Right)，並設定 `spacing: 30`。
    *   **對手組件重構 (`_OpponentHand`)：**
        *   **佈局：** 改為 `FittedBox` 包裹的 `CardContainer`，內容為 `Row` (頭像 + 資訊欄)。
        *   **資訊欄：** 包含玩家名稱與剩餘張數 (Icon + Text)。
        *   **狀態樣式：** 根據 `hasPassed` 狀態調整背景色、文字顏色與 Icon 顏色 (Pass 狀態為灰色調，當前回合為高亮)。
        *   **移除旋轉：** 由於統一在頂部顯示，移除原有的 `RotatedBox` 邏輯。

2.  **棄牌堆 Dialog 優化 (`BigTwoBoardCardArea`)**
    *   **Dialog 樣式：** 使用 `Palette().backgroundSettings` 作為背景色。
    *   **內容容器：** 設定固定高度 `200`，並使用 `Expanded` 包裹內容。
    *   **列表組件：** 替換 `ShowOnlyCardAreaWidget` 為 `ShowOnlyCardAreaList`。

3.  **新增卡牌列表組件 (`ShowOnlyCardAreaList`)**
    *   建立 `lib/play_session/show_only_card_area_list.dart`。
    *   使用 `GridView.builder` 實作，支援大量卡牌的滾動或自適應顯示。
    *   設定 `gridDelegate` 為 `SliverGridDelegateWithMaxCrossAxisExtent`，限制最大寬度為 `PlayingCardImageWidget.smallWidth`，並保持卡牌比例。
    *   支援 `SettingsController` 取得卡牌圖片路徑。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **UI Layout:** `lib/play_session/big_two_board_widget.dart`
*   **UI Components:** `lib/play_session/big_two_board_card_area.dart`
*   **New Component:** `lib/play_session/show_only_card_area_list.dart` (New)
*   **Styles:** `lib/widgets/card_container.dart` (Padding adjustment)

#### **2.2 程式碼風格 (Style)**

*   **GridView 應用：** 使用 `shrinkWrap: true` 配合外層約束，避免無限高度錯誤。
*   **顏色管理：** 使用 `Colors.black.withValues(alpha: ...)` 替代舊的 `withOpacity` (如果 Flutter 版本支援)，或保持一致性。
*   **FittedBox：** 確保玩家資訊在窄螢幕下自動縮放不溢出。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **佈局檢查：** 進入 4 人遊戲，確認 3 位對手均顯示在畫面頂部，且順序正確 (左對手 -> 頂對手 -> 右對手)。
2.  **Pass 狀態檢查：** 模擬對手 Pass，確認其頭像區域變灰，文字變暗。
3.  **Discard Dialog 檢查：** 點擊棄牌堆，確認彈出的 Dialog 背景正確，且卡牌以 Grid 方式排列，無 Overflow。

---

### **Section 4: Commit 程式碼分析與審查 (Analysis & Review)**

#### **4.1 Commit: 11770a3f01e4da33d59a5c629efba6b174150a5b**
*   **Author:** okawa <a@a.a>
*   **Date:** Mon Jan 5 15:23:38 2026 +0900
*   **Message:** `change layout, show_only_card_area_list`

#### **4.2 變更摘要**
*   **`BigTwoBoardWidget`**: 徹底改變了對手顯示佈局。原本是傳統的撲克桌佈局 (左、上、右圍繞中心)，現在改為類似 "觀戰模式" 或 "統一頂部視角" 的佈局。這可能為了讓卡牌區域最大化。
*   **`ShowOnlyCardAreaList`**: 新增的 GridView 組件解決了棄牌堆卡牌過多時 `Row` 顯示不下的問題。
*   **`_OpponentHand`**: 視覺重構，增加了 Pass 狀態的明顯提示，提升了遊戲體驗。

#### **4.3 審查結論**
*   此次變更集中於 UI/UX 優化。
*   將對手集中於頂部是一個大膽的佈局變更，需確認在不同寬高比裝置上的顯示效果 (特別是手機直向 vs 橫向)。
*   代碼結構清晰，`ShowOnlyCardAreaList` 的拆分符合單一職責原則。

---

### **Section 5: 產出 Commit Message**

```text
refactor(board): move all opponents to top layout & optimize discard dialog

- Layout: Refactored `BigTwoBoardWidget` to display all opponent hands in a single `Row` at the top, removing side widgets for a cleaner table view.
- UI: Updated `_OpponentHand` visuals with `FittedBox`, enhanced "Pass" state styling (dimmed colors), and optimized player info display.
- Feature: Replaced `ShowOnlyCardAreaWidget` with new `ShowOnlyCardAreaList` using `GridView` in `BigTwoBoardCardArea` to better handle large discard piles in the dialog.
- Style: Adjusted `CardContainer` padding and updated Discard Dialog background color.
```
