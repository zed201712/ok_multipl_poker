## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-SETTINGS-I18N-001` |
| **標題 (Title)** | `IMPLEMENT MULTI-LANGUAGE SUPPORT WITH EASY_LOCALIZATION` |
| **創建日期 (Date)** | `2025/12/31` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 為專案導入 `easy_localization` 套件，實作多語言切換功能（英文、繁體中文、日文）。
*   **目的：**
    1.  **國際化 (I18N)：** 支援 `en`, `zh-TW`, `ja` 三種語言環境。
    2.  **狀態管理 (State Management)：** 整合 `SettingsController` 與 `Provider`，確保語言設定能即時反映於 UI 並持久化。
    3.  **UI 優化 (UI UX)：** 在設定頁面新增「箭頭切換式」語言選擇器。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **基礎建設 (Infrastructure)**
    *   **Dependencies:** 在 `pubspec.yaml` 新增 `easy_localization`。
    *   **Assets:** 建立 `assets/translations` 目錄，並新增以下 JSON 檔案：
        *   `en.json`: `{ "play": "Play", "settings": "Settings", "music": "Music", "sound": "Sound", "matching": "Matching...", "ready": "Ready to start" }`
        *   `zh-TW.json`: `{ "play": "開始遊戲", "settings": "設定", "music": "音樂", "sound": "音效", "matching": "配對中...", "ready": "準備開始" }`
        *   `ja.json`: `{ "play": "プレイ", "settings": "設定", "music": "音楽", "sound": "効果音", "matching": "マッチング中...", "ready": "準備完了" }`
    *   **Initialization:** 修改 `main.dart`，在 `runApp` 前初始化 `EasyLocalization`，並包裹 Root Widget。

2.  **狀態管理 (SettingsController)**
    *   在 `SettingsController` 中新增 `ValueNotifier<Locale> currentLocale`。
    *   **Persistence:** 更新 `SettingsPersistence` 介面與實作，支援讀寫 Locale String (如 'en', 'zh-TW', 'ja')。
    *   **Logic:** 新增 `cycleLanguage(BuildContext context)` 方法，用於計算下一個語言索引並更新 Context 與 Persistence。

3.  **UI 實作 (User Interface)**
    *   **設定頁面 (SettingsScreen / Settings Logic):**
        *   在 `lib/settings/settings_screen.dart` (或對應 UI 檔案) 新增語言選擇區塊。
        *   **樣式：** `Row` 包含 `[IconButton(Left Arrow)]` - `[Text(Display Name)]` - `[IconButton(Right Arrow)]`。
        *   **行為：** 點擊箭頭呼叫 `controller.cycleLanguage`，循環切換順序：English -> 繁體中文 -> 日本語 -> English。
    
    *   **套用翻譯 (Apply Translations):**
        *   `lib/main_menu/main_menu_screen.dart`: 按鈕文字 (Play, Settings)。
        *   `lib/settings/settings.dart` (UI 層): 音效/音樂標籤。
        *   `lib/play_session/big_two_board_widget.dart`: 狀態文字 (Matching, Ready, Start)。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **設定與資源：** `pubspec.yaml`, `assets/translations/*.json`
*   **入口與狀態：** `lib/main.dart`, `lib/settings/settings.dart`, `lib/settings/persistence/*`
*   **UI 替換：**
    *   `lib/main_menu/main_menu_screen.dart`
    *   `lib/play_session/big_two_board_widget.dart`
    *   `lib/settings/settings_screen.dart` (若存在，或需新建 Widget)

#### **2.2 程式碼風格 (Style)**

*   遵循 `Effective Dart`。
*   使用 `tr()` 擴充函式進行翻譯字串替換。
*   JSON Key 命名採用 `camelCase` 或 `snake_case` 統一風格 (建議 `section.key` 格式，如 `main_menu.play`)。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **切換測試：** 進入設定頁面，點擊左右箭頭，確認中間文字變更 (English / 繁體中文 / 日本語)，且 App 介面語言即時更新。
2.  **持久化測試：** 選定一種語言 (如日文) 後重啟 App，確認 App 啟動時仍為日文。
3.  **Web 兼容性：** 確保 `flutter build web` 後翻譯檔案能正確載入 (需檢查 `pubspec.yaml` assets 定義)。

---

### **Section 4: 改善建議與邏輯檢查 (Review & Suggestions)**

#### **4.1 邏輯檢查**

*   **狀態同步問題：** `EasyLocalization` 自帶 `context.setLocale` 與持久化。若 `SettingsController` 也做持久化，會造成雙重來源 (SSOT Issue)。
    *   *解決方案：* 建議將持久化交由 `SettingsController` 統一管理。初始化時讀取 `SettingsController` 的值並餵給 `EasyLocalization` 的 `startLocale`。或者，完全依賴 `EasyLocalization` 的持久化，`SettingsController` 僅作為 UI 的 Proxy (Wrapper)。本 Spec 採用 **SettingsController 為主** 的策略，以保持架構一致性。
*   **Web 資源路徑：** Flutter Web 對 JSON 載入路徑較敏感，確保 JSON 檔案不包含 BOM 格式，且 `pubspec.yaml` 路徑正確。

#### **4.2 提交訊息 (Commit Message)**

```text
feat: implement multi-language support (i18n)

Task: FEAT-SETTINGS-I18N-001

- Added `easy_localization` dependency.
- Created translation assets for en, zh-TW, ja.
- Updated `SettingsController` to manage locale state.
- Implemented arrow-style language selector in Settings.
- Applied translations to Main Menu and Game Board.
```
