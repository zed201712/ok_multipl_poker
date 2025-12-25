## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-Board-Card_Area-001` |
| **標題 (Title)** | `IMPLEMENT BIG TWO BOARD CARD AREA` |
| **創建日期 (Date)** | `2025/12/25` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 建立一個新的 UI 元件 `BigTwoBoardCardArea`，用於取代原本的 `TableCardWrapWidget`。該元件負責顯示桌面上已打出的牌、棄牌堆 (Discard Pile) 與 牌堆 (Deck Cards)。
*   **目的：**
    1.  **狀態管理優化：** 改用 `Provider` 模式獲取 `BigTwoState`，減少參數傳遞層級。
    2.  **功能擴充：** 新增棄牌堆 (Discard Pile) 的顯示與互動功能 (點擊查看詳細棄牌)。
    3.  **排版改善：** 重新規劃桌面佈局，使資訊呈現更清晰。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **元件建立 (`BigTwoBoardCardArea`)**
    *   **位置：** `lib/play_session/big_two_board_card_area.dart` (新檔案)。
    *   **資料來源：** 透過 `context.watch<BigTwoState>()` 或 `Provider.of<BigTwoState>(context)` 取得當前遊戲狀態。
    *   **外部參數：**
        *   `VoidCallback? onDiscardPileTap`: 當點擊棄牌堆時的回調函式。
        *   *注意：不應直接傳入 `lastPlayedCards` 等資料，應由 Provider 獲取。*

2.  **佈局設計 (Layout)**
    *   **結構：** 使用 `Column` 垂直排列。
        *   **上層 (Row)：**
            *   **左側：** Last Played Cards (顯示邏輯參照原 `TableCardWrapWidget`，可封裝為子 Widget)。
            *   **右側：** Discard Pile (使用 `CardContainer` 包裹)。
        *   **下層：** Deck Cards (顯示剩餘牌堆，使用 `Wrap` 或 `Row`)。
    *   **間距：** 各區塊間應有適當的 Padding 或 SizedBox。

3.  **棄牌堆 (Discard Pile) 實作**
    *   **外觀：** 使用 `CardContainer`，標題設為 "Discard"。
    *   **內容：** 顯示一張代表棄牌堆的圖片 (Asset Image)，例如卡背圖案。
    *   **互動：** 綁定 `onTap` 事件，觸發 `onDiscardPileTap` 回調。

4.  **整合 (`BigTwoBoardWidget`)**
    *   **Provider 注入：** 在 `BigTwoBoardWidget` 的 `StreamBuilder` 內部，使用 `Provider.value` (或適當的 Provider 建構子) 將 `gameState.customState` (即 `BigTwoState`) 提供給子樹。
    *   **替換元件：** 將原本使用的 `TableCardWrapWidget` 替換為 `BigTwoBoardCardArea`。
    *   **彈窗實作：** 實作 `onDiscardPileTap`，呼叫 `AlertOverlay` 並顯示 `ShowOnlyCardAreaWidget`，內容為 `state.discardCards`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **新增：** `lib/play_session/big_two_board_card_area.dart`
*   **修改：** `lib/play_session/big_two_board_widget.dart`
*   **刪除 (或棄用)：** `lib/play_session/table_card_wrap_widget.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `Effective Dart` 風格指南。
*   使用 `const` 建構子優化效能。
*   保持 Widget 的 `build` 方法簡潔，複雜部分應拆分為小 Widget 或 Helper method。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **UI 檢查：**
    *   確認 `BigTwoBoardCardArea` 能正確顯示 Last Played Cards 和 Deck Cards。
    *   確認 Discard Pile 顯示在 Last Played Cards 的右側 (或依設計排列)。
2.  **互動檢查：**
    *   點擊 Discard Pile 圖片，確認彈出 `AlertOverlay`。
    *   彈窗內容應正確顯示所有已棄掉的牌 (`discardCards`)。
3.  **狀態更新：**
    *   當遊戲進行 (出牌/Pass) 時，確認 UI (Last Played, Discard Pile) 能即時更新。

---

### **Section 4: 改善建議與邏輯檢查 (Review & Suggestions)**

#### **4.1 邏輯檢查**
*   **Provider 依賴：** 原本的 `BigTwoBoardWidget` 透過 `StreamBuilder` 更新 UI，並未直接提供 `BigTwoState` 的 Provider。**必須在 `StreamBuilder` 的 `builder` 中加入 `Provider<BigTwoState>.value`**，否則 `BigTwoBoardCardArea` 無法獲取資料。
*   **Discard Pile 顯示：** Spec 中指定使用 Asset Image。需確認專案中是否有合適的卡背圖片資源 (例如 `assets/images/card_back.png`)。若無，暫時使用 `Icon` 或 `Placeholder` 替代。

#### **4.2 改善建議**
*   **解耦：** `BigTwoBoardCardArea` 只負責顯示與基本互動，彈窗邏輯保留在 Page/Board 層級 (`BigTwoBoardWidget`) 是好的設計，保持了元件的純粹性。
*   **Last Played Title：** 原本 `TableCardWrapWidget` 接收 `lastPlayedTitle` (例如顯示是誰打出的)。在重構時，這部分資訊需從 `BigTwoState` 中的 `lastPlayedById` 與 `participants` 對應取得，這可能需要在 Widget 內部做簡單的查表邏輯，或由 ViewModel 處理。建議在 `BigTwoState` 或 `BigTwoDelegate` 提供 helper method 來獲取玩家名稱，簡化 UI 邏輯。
