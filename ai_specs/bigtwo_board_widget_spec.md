## AI 專案任務指示文件：建立大老二遊戲盤面 Widget

### **文件標頭 (Metadata)**

| 區塊 | 內容 | 目的/對 AI 的意義 |
| :--- | :--- | :--- |
| **任務 ID (Task ID)** | `FEAT-WIDGET-BIGTWO-001` | 方便追蹤和版本控制。 |
| **創建日期 (Date)** | `2024/07/30` | - |
| **目標版本 (Target Version)** | `N/A` | 新增核心遊戲畫面元件。 |
| **專案名稱 (Project)** | `ok_multipl_poker` | - |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

建立一個名為 `BigTwoBoardWidget` 的 Flutter Widget，用來呈現四人制大老二（Big Two）遊戲的主要操作介面，包含四位玩家的區域和一個中央出牌區。

#### **1.2 詳細需求 (Detailed Requirements)**

*   **檔案建立:** 建立 `lib/play_session/bigtwo_board_widget.dart` 檔案。
*   **佈局 (Layout):**
    *   應使用 `Stack` Widget 作為根佈局，以便在畫面上自由定位各個 UI 元素。
    *   **本機玩家 (底部):** 在畫面底部中央，使用現有的 `PlayerHandWidget` 來顯示玩家自己的、可互動的手牌。
        *   **本機玩家 (底部) 出牌按鈕:** 在畫面底部中央右側，使用現有的 `MyButton` 設置出牌按鈕。
        *   **本機玩家 (底部) 出牌類型Row:** 在畫面底部中央上方，增設一列 出牌類型按鈕, ["單張", "一對", "葫蘆", "順子", "同花順"]的英文版。
    *   **右側玩家 (右側):** 在畫面右側垂直置中，此區域應僅顯示該玩家的手牌背面圖示和剩餘牌數。
    *   **對家玩家 (頂部):** 在畫面頂部中央，此區域應僅顯示該玩家的手牌背面圖示和剩餘牌數。
    *   **左側玩家 (左側):** 在畫面左側垂直置中，此區域應僅顯示該玩家的手牌背面圖示和剩餘牌數。
    *   **中央出牌區 (中央):** 在畫面正中央，使用現有的 `PlayingAreaWidget` 來顯示上一手（或當前）打出的牌。
*   **狀態管理:**
    *   Widget 應能透過 `context.watch<BigTwoState>()` 來獲取一個名為 `BigTwoState` 的狀態物件（此物件可先假設存在）。
    *   從 `BigTwoState` 中讀取並分別渲染四位玩家的牌組資訊（手牌、剩餘牌數）以及中央出牌區的牌組。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **新增:** `lib/play_session/bigtwo_board_widget.dart`
*   **參考:** `lib/play_session/board_widget.dart` (作為佈局和狀態管理方式的參考)。
*   **參考:** `lib/play_session/player_hand_widget.dart` (將用於底部玩家區域)。
*   **參考:** `lib/play_session/playing_area_widget.dart` (將用於中央出牌區)。

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **狀態管理:** 強制使用 `provider` 套件進行狀態管理。
*   **慣例:** 遵循 `effective_dart` 程式碼風格。為主要的 Widget 和狀態互動邏輯添加必要的 DartDoc 註解。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)**

1.  **執行計劃：** 簡要說明將建立 `bigtwo_board_widget.dart` 檔案，並在其中使用 `Stack` 來組合各個子 Widget。
2.  **程式碼輸出：** 提供新檔案 `lib/play_session/bigtwo_board_widget.dart` 的完整內容。

#### **3.2 驗證步驟 (Verification Steps)**

1.  確認新的 `lib/play_session/bigtwo_board_widget.dart` 檔案被成功建立。
2.  確認 Widget 的佈局在畫面上呈現為四個角落的玩家區和一個中央區域。
3.  確認底部的玩家區域是可互動的 `PlayerHandWidget`。
4.  確認其餘三個玩家區域僅顯示手牌背面圖示和剩餘牌數文字。
5.  確認程式碼中包含 `context.watch<BigTwoState>()` 來獲取狀態。

---

### **Section 4: 上一輪回饋 (Previous Iteration Feedback)**

*   無，此為初次建立。
