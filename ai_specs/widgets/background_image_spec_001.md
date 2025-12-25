## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                             |
|:---|:-------------------------------|
| **任務 ID (Task ID)** | `FEAT-BACKGROUND-IMAGE-001`    |
| **標題 (Title)** | `ADD BACKGROUND IMAGE SUPPORT` |
| **創建日期 (Date)** | `2025/12/25`                   |
| **目標版本 (Target Version)** | `N/A`                          |
| **專案名稱 (Project)** | `ok_multipl_poker`             |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 為遊戲主選單與遊戲畫面添加背景圖片支援，改善視覺體驗。
*   **目的：**
    1.  **視覺優化：** 替換單調的純色背景，使用主題相關的背景圖 (`goblin_bg_001.png`, `goblin_bg_002.png`)。
    2.  **元件封裝：** 建立通用的 `BackgroundImageWidget` 以便在不同畫面中復用。
    3.  **UI 調整：** 調整 `Scaffold` 背景顏色為透明，確保背景圖可見。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **新增通用元件 (Shared Component)**
    *   **元件名稱：** `BackgroundImageWidget`
    *   **位置：** `lib/widgets/background_image_widget.dart`
    *   **功能：**
        *   接收 `imagePath` 與 `child`。
        *   使用 `Stack` 將背景圖置於底層，並覆蓋一層半透明遮罩 (`Colors.black.withOpacity(0.3)`) 以增加文字可讀性。
        *   將 `child` 置於最上層。

2.  **主選單更新 (`MainMenuScreen`)**
    *   **修改：** `lib/main_menu/main_menu_screen.dart`
    *   **實作：** 使用 `BackgroundImageWidget` 包裹內容，背景圖設為 `assets/images/goblin_cards/goblin_bg_001.png`。
    *   **調整：** 將 `Scaffold` 的 `backgroundColor` 設為 `Colors.transparent`。
    *   **文字更新：** 將標題文字由 "Drag&Drop Cards!" 改為 "Goblin BigTwo!"。

3.  **遊戲畫面更新 (`PlaySessionScreen` & `BigTwoBoardWidget`)**
    *   **修改：** `lib/play_session/play_session_screen.dart`
    *   **實作：** 使用 `BackgroundImageWidget` 包裹內容，背景圖設為 `assets/images/goblin_cards/goblin_bg_002.png`。
    *   **調整：** `Scaffold` 背景色設為 `Colors.transparent`。
    *   **佈局微調：** 暫時註解掉 debug widgets 以保持畫面整潔 (視需求而定)。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **新增：** `lib/widgets/background_image_widget.dart`
*   **新增資源：**
    *   `assets/images/goblin_cards/goblin_bg_001.png`
    *   `assets/images/goblin_cards/goblin_bg_002.png`
*   **修改：** `lib/main_menu/main_menu_screen.dart`
*   **修改：** `lib/play_session/play_session_screen.dart`
*   **修改：** `lib/play_session/big_two_board_widget.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `Effective Dart` 風格。
*   UI 元件應保持無狀態 (Stateless) 若不涉及內部狀態變更。
*   使用 `const` 建構子優化效能。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **資源檢查：** 確認背景圖檔已正確加入專案且在 `pubspec.yaml` 中註冊 (若需)。
2.  **畫面檢查：**
    *   啟動 App，確認主選單背景顯示 `goblin_bg_001.png`，標題為 "Goblin BigTwo!"。
    *   進入遊戲，確認背景顯示 `goblin_bg_002.png`。
3.  **互動檢查：** 確認背景圖不會阻擋按鈕點擊或其他互動操作。

---

### **Section 4: Commit 程式碼分析與審查 (Analysis & Review)**

#### **4.1 變更摘要**
*   引入了統一的背景處理機制，提升了應用程式的整體質感。
*   對現有 Screen 進行了必要的適配 (透明背景)。

#### **4.2 審查結論**
*   代碼結構清晰，元件復用性高。
*   注意：Binary 檔案 (png) 已正確加入 commit。
