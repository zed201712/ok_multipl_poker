## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                       |
|:---|:-----------------------------------------|
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-UI-015`                    |
| **標題 (Title)** | `LAYOUT & COMPONENT ENHANCEMENTS` |
| **創建日期 (Date)** | `2026/01/06`                             |
| **目標版本 (Target Version)** | `N/A`                                    |
| **專案名稱 (Project)** | `ok_multipl_poker`                       |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 進一步優化 `BigTwoBoardWidget` 佈局比例，改善 `CardContainer` 的靈活性，並微調手牌區域 (`SelectablePlayerHandWidget`) 的顯示。
*   **目的：**
    1.  **佈局微調 (Layout Fine-tuning)：** 調整 Board 上各區域 (Top, Middle, Bottom) 的 Flex 比例，給予底部玩家操作區更多空間 (`flex: 20`)，頂部區域縮小 (`flex: 2`)，中間區域適中 (`flex: 7`)。
    2.  **組件增強 (Component Enhancement)：** 增強 `CardContainer`，使其支援標題 (Title) 顯示在內容的左、上、右、下四個方位，而不僅限於頂部。
    3.  **手牌顯示優化 (Hand Display)：**
        *   `SelectablePlayerHandWidget`: 按鈕列增加 `FittedBox` 避免溢出。
        *   手牌列表改用 `Wrap` 替代 `Row`，避免手牌過多時溢出，並增加 `runSpacing`。
        *   卡牌圖片尺寸改為預設大小 (`defaultWidth`/`defaultHeight`)。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **CardContainer 增強 (`lib/widgets/card_container.dart`)**
    *   新增 `enum TitlePosition { left, top, right, bottom }`。
    *   新增 `position` 參數，型別為 `TitlePosition`，預設為 `.top`。
    *   根據 `position` 調整內部佈局：
        *   `.top` / `.bottom`: 使用 `Column`。
        *   `.left` / `.right`: 使用 `Row`。
    *   更新相關呼叫處 (如 `BigTwoBoardCardArea`) 使用新的 `position` 屬性。

2.  **Board Widget 佈局調整 (`BigTwoBoardWidget`)**
    *   **Flex 比例調整：**
        *   Top (Opponents): `flex: 2` (原 5)
        *   Middle (Card Area): `flex: 7` (原 10)
        *   Bottom (Player Hand): `flex: 20` (原 14)
    *   **對手區域 (`_OpponentHand`)：**
        *   移除垂直排列，將名字與卡牌數量改為水平排列 (`Row` 或直接放在外層 `Row` 中)。
        *   `SizedBox` 間距調整。

3.  **牌桌區域微調 (`BigTwoBoardCardArea`)**
    *   **Last Played:** 標題位置改為 `TitlePosition.right`。
    *   **Discard Pile:** 標題位置改為 `TitlePosition.left`。

4.  **玩家手牌區域微調 (`SelectablePlayerHandWidget`)**
    *   **操作按鈕：** 外層包裹 `FittedBox`。
    *   **手牌顯示：** 使用 `Wrap` 替換 `Row`，`spacing: 3`, `runSpacing: 10`。
    *   **卡牌尺寸：** 改為 `PlayingCardImageWidget.defaultWidth` / `defaultHeight`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **Core Widget:** `lib/widgets/card_container.dart`
*   **Board Layout:** `lib/play_session/big_two_board_widget.dart`
*   **Card Area:** `lib/play_session/big_two_board_card_area.dart`
*   **Player Hand:** `lib/play_session/selectable_player_hand_widget.dart`

#### **2.2 程式碼風格 (Style)**

*   **Flex 佈局：** 確保總 Flex 值合理分配螢幕高度。
*   **Wrap 使用：** `Wrap` 雖然能解決溢出，但在高度受限的區域 (如 Bottom Sheet 或固定高度容器) 需注意是否會造成垂直方向的 Overflow，此次調整因底部 `flex: 20` 空間較大，應無問題。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **CardContainer 測試：** 檢查 "Last Played" 標題是否在卡牌右側，"Discard Pile" 標題是否在卡牌左側。
2.  **佈局比例：** 確認底部玩家區域顯著變大，頂部對手區域變窄但不遮擋內容。
3.  **手牌溢出測試：** 發給自己 13 張牌或更多，確認 `Wrap` 正常運作且不超出底部邊界。

---

### **Section 4: Commit 程式碼分析與審查 (Analysis & Review)**

#### **4.1 Commit: 569cc927beaff3ef5e3d4489ea61c814535e10a1**
*   **Author:** okawa <a@a.a>
*   **Date:** Mon Jan 5 23:01:38 2026 +0900
*   **Message:** `feat: big_two_delegate_spec_015`

#### **4.2 變更摘要**
*   **`CardContainer`**: 增加了 `TitlePosition` enum，支援標題在上下左右四個方向，極大地增加了此組件的通用性。
*   **`BigTwoBoardWidget`**: 重新分配了垂直空間 (`flex`)，將重心下移至玩家操作區。這符合撲克遊戲 "以玩家視角為主" 的設計理念。
*   **`_OpponentHand`**: 簡化了資訊顯示，從垂直排列改為水平流式排列，節省了垂直空間，適配新的 Flex 比例。
*   **`SelectablePlayerHandWidget`**: `Row` -> `Wrap` 的改變是關鍵修復，防止手牌過多時的 Overflow 錯誤。

#### **4.3 審查結論**
*   **邏輯正確性：** 無明顯邏輯錯誤。`CardContainer` 的 switch-case 處理涵蓋了所有 enum 值。
*   **改善建議：**
    *   **Flex 安全性：** 雖然 `flex: 20` 很大，但如果 `Wrap` 折行過多 (例如 20 張牌)，仍可能超出邊界。建議在 `SelectablePlayerHandWidget` 外層再加一層 `SingleChildScrollView` 或確保手牌數量上限。
    *   **UI 一致性：** `_OpponentHand` 變得非常緊湊，需確認在小螢幕手機上文字是否清晰。

---

### **Section 5: 產出 Commit Message**

```text
feat(ui): enhance layout flexibility and hand display

- Component: Updated `CardContainer` to support `TitlePosition` (left, top, right, bottom) for versatile labeling.
- Layout: Adjusted `BigTwoBoardWidget` flex ratios (Top:2, Mid:7, Bot:20) to prioritize player interaction area.
- UI: Refactored `_OpponentHand` to a more compact horizontal layout.
- Fix: Replaced `Row` with `Wrap` in `SelectablePlayerHandWidget` to prevent overflow with many cards.
```
