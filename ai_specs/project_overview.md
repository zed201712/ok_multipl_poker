## AI 專案任務指示文件：專案概觀

### **文件標頭 (Metadata)**

| 區塊 | 內容 | 目的/對 AI 的意義 |
| :--- | :--- | :--- |
| **文件 ID (Doc ID)** | `DOCS-PROJ-OVERVIEW-001` | 這是專案的總體說明文件。 |
| **創建日期 (Date)** | `2025/11/29` | - |
| **目標版本 (Target Version)** | `N/A` | 這份文件描述的是專案的總體架構，而非特定版本任務。 |
| **專案名稱 (Project)** | `ok_multipl_poker` | 線上多人撲克牌遊戲。 |

---

### **Section 1: 專案核心定義 (Core Project Definition)**

這是說明這個專案 **「是什麼」**。

#### **1.1 專案目標 (Goal)**

* **說明：** 這是一個使用 Flutter 框架開發，並由 AI 協助編寫的線上多人Big Two撲克牌遊戲專案。

#### **1.2 核心功能與畫面 (Core Features & Screens)**

* **說明：** 專案包含以下主要畫面和功能。
* **畫面結構：**
    *   **主畫面 (`main_menu_screen.dart`):** App 的進入點。
        *   **配對選單:** 提供不同人數的遊戲選項（2人、3人、4人）。
        *   **登入按鈕:** 導向至登入畫面。
        *   **設定按鈕:** 導向至設定畫面。
    *   **登入畫面 (`login_screen.dart`):** 處理使用者身份驗證。
    *   **設定畫面 (`settings_screen.dart`):** 允許使用者調整遊戲或 App 設定（例如：音效、暱稱等）。
    *   **遊戲區域 (`BoardWidget.dart`):** 實際進行撲克牌遊戲的互動介面。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

這是說明這個專案 **「如何實作」**。

#### **2.1 主要技術棧 (Tech Stack)**

*   **語言：** Dart
*   **框架：** Flutter
*   **網路與後端：** Firebase / Cloud Firestore (`firestore_controller.dart`) 用於處理多人連線狀態同步。
*   **本地儲存：**
    *   `shared_preferences` 用於儲存簡單鍵值對，如設定 (`local_storage_settings_persistence.dart`)。
    *   `shared_preferences` 也用於持久化玩家進度，如最高關卡 (`local_storage_player_progress_persistence.dart`)。

#### **2.2 程式碼風格與架構 (Style & Architecture)**

*   **架構：** 遵循 Flutter 標準實踐，將 UI (Widgets), 業務邏輯 (Controllers/Services), 和資料持久化 (Persistence) 分層。
*   **UI 元件:** 專案自定義了可重複使用的 Widget，例如 `MyButton` (`/lib/style/my_button.dart`)，以確保風格統一。
*   **慣例：** 遵循 `effective_dart` 程式碼風格。

---

### **Section 3: 總結 (Summary)**

這份文件旨在為開發者（或 AI）提供一個關於 `ok_multipl_poker` 專案的快速概覽，使其了解專案的目標、主要功能和技術基礎。
