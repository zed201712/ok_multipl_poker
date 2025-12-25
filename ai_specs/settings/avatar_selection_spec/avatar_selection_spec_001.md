## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-SETTINGS-AVATAR-001` |
| **標題 (Title)** | `IMPLEMENT PLAYER AVATAR SELECTION AND ONBOARDING` |
| **創建日期 (Date)** | `2025/12/26` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 實作玩家頭像 (Avatar) 選擇功能，並建立初次使用者的引導流程 (Onboarding)。
*   **目的：**
    1.  **個人化 (Personalization)：** 允許玩家從 `assets/images/goblin_cards/` 中選擇圖片作為個人頭像。
    2.  **狀態管理 (State Management)：** 透過 `SettingsController` 與 `Provider` 管理並持久化頭像設定。
    3.  **使用者引導 (Onboarding)：** 針對首次進入 App 的使用者，強制彈出設定頁面以完成暱稱與頭像的初始化。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **SettingsController 擴充**
    *   **位置：** `lib/settings/settings.dart`
    *   **新增狀態：** `ValueNotifier<String> playerAvatarPath`。
    *   **預設值：** `assets/images/goblin_cards/goblin_1_001.png` (或目錄下的第一張圖)。
    *   **功能：** 需包含 `setPlayerAvatarPath(String path)` 方法，並處理持久化儲存 (`Persistence`)。

2.  **頭像選擇畫面 (`AvatarSelectionScreen`)**
    *   **位置：** `lib/settings/avatar_selection_screen.dart` (新檔案)。
    *   **UI 佈局：** 使用 `GridView` 顯示 `assets/images/goblin_cards/` 目錄下的所有可用圖片。
        *   *實作註記：* 需透過 `AssetManifest` 或固定清單讀取資源列表。
    *   **互動：** 點擊圖片後，更新 `SettingsController` 的 `playerAvatarPath` 並關閉畫面 (Pop)。

3.  **設定頁面更新 (`SettingsScreen`)**
    *   **位置：** `lib/settings/settings_screen.dart`
    *   **修改：** 在頂部或適當位置新增一個 1x1 的圓形或方形頭像區域。
    *   **顯示：** 透過 `ValueListenableBuilder` 監聽 `playerAvatarPath` 顯示當前頭像。
    *   **互動：** 點擊頭像區域開啟 `AvatarSelectionScreen`。

4.  **初次使用引導 (`OnboardingSheet`)**
    *   **位置：** `lib/settings/onboarding_sheet.dart` (新檔案)。
    *   **觸發時機：** 當 App 啟動且偵測到是「初次使用」(或 Name/Avatar 為預設值) 時。建議在 `MainMenuScreen` 檢查。
    *   **UI 風格：** 類似 `SettingsScreen` 的風格 (Permanent Marker 字體)。
    *   **內容：**
        *   標題 (e.g., "Welcome, Goblin!")。
        *   頭像選擇按鈕 (複用上述邏輯)。
        *   暱稱輸入欄位 (TextField)。
        *   確認按鈕 ("Let's Play")，點擊後儲存設定並關閉 Sheet。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/settings/settings.dart` (Controller & Persistence logic)
*   **修改：** `lib/settings/settings_screen.dart` (UI Update)
*   **修改：** `lib/main_menu/main_menu_screen.dart` (Trigger Onboarding)
*   **新增：** `lib/settings/avatar_selection_screen.dart`
*   **新增：** `lib/settings/onboarding_sheet.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `Effective Dart`。
*   使用 `Provider` (`context.read`, `context.watch`) 進行狀態存取。
*   UI 元件應模組化，避免單一 build 方法過大。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **功能驗證：**
    *   進入設定頁，點擊頭像，確認能開啟選擇列表。
    *   選擇新頭像，確認設定頁即時更新。
    *   重啟 App，確認頭像設定被保留 (Persistence)。
2.  **Onboarding 驗證：**
    *   清除 App 資料或重置設定。
    *   啟動 App，確認 `OnboardingSheet` 自動彈出。
    *   完成設定後，確認數值正確寫入 `SettingsController`。

---

### **Section 4: 改善建議與邏輯檢查 (Review & Suggestions)**

#### **4.1 邏輯檢查與建議**

*   **資源讀取問題：** Flutter 在 Runtime 無法直接列舉 asset 目錄。
    *   **建議：** 使用 `AssetManifest` (Flutter 服務) 讀取所有 assets 並過濾出 `assets/images/goblin_cards/` 路徑下的檔案。這樣就不需要手動維護圖片清單。
*   **Onboarding 判斷條件：** 僅依賴「預設值」來判斷是否為初次使用者可能不夠精確 (使用者可能真的想用預設名字)。
    *   **建議：** 在 `SettingsController` 新增一個 `ValueNotifier<bool> hasCompletedOnboarding` 旗標。預設為 `false`，當使用者在 `OnboardingSheet` 點擊確認後設為 `true`。這樣邏輯更穩健。
*   **UI 體驗：** `OnboardingSheet` 建議設為 `isDismissible: false`，強制使用者完成設定才能進入遊戲。

#### **4.2 潛在風險**
*   `SettingsPersistence` 介面 (Interface) 需要同步更新以支援儲存圖片路徑和 Onboarding 狀態，請確保 `LocalStorageSettingsPersistence` 也一併實作。
