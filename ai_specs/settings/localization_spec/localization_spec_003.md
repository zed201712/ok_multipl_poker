## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-SETTINGS-I18N-003` |
| **標題 (Title)** | `COMPLETE GAME BOARD TRANSLATIONS & FIX SETTINGS LOCALE SYNC` |
| **創建日期 (Date)** | `2025/12/31` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：**
    1.  **補全遊戲介面翻譯：** 針對 `BigTwoBoardWidget` 中遺漏的按鈕文字 (Leave, Pass, Cancel, Play) 進行多語言支援。
    2.  **修正設定頁面語言顯示錯置：** 解決設定頁面中，顯示的語言名稱 (e.g., "English") 與實際生效的 UI 語言 (e.g., 中文) 不一致的問題。
    3.  **Onboarding 頁面多語言化：** 將 `OnboardingSheet` 中的歡迎與輸入文字進行多語言支援。
*   **根本原因 (Root Cause for Mismatch):**
    *   `SettingsController` 的 `currentLocale` 初始值可能為預設值 ('en')，但 `EasyLocalization` 載入時使用了裝置系統語言 ('zh')。設定頁面目前依賴 `SettingsController` 的值來顯示語言名稱，導致與實際 UI (由 `EasyLocalization` 驅動) 不符。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **資源檔更新 (Asset Updates)**
    *   在 `assets/translations/` 的 `en.json`, `zh-TW.json`, `ja.json` 中新增以下 Key：
        *   `leave`: "Leave" / "離開" / "退出"
        *   `pass`: "Pass" / "Pass" / "パス" (中文常用 Pass 或 過，這裡統一用 Pass 或 過，請使用 "Pass") -> 修正: 中文使用 "過牌" 或 "Pass"。用戶指示 "Pass"，則中文可翻 "跳過" 或 "Pass"。讓我們使用 "Pass" (英文), "跳過" (中文), "パス" (日文)。
        *   `cancel`: "Cancel" / "取消" / "キャンセル"
        *   `play_action`: "Play" / "出牌" / "出す" (為了與 Main Menu 的 "Play" (開始遊戲) 區分，使用 `play_action`)。
        *   `welcome`: "Welcome!" / "歡迎!" / "ようこそ!"
        *   `your_name`: "Your Name" / "你的名字" / "あなたの名前"
        *   `lets_play`: "Let's Play!" / "開始玩吧!" / "遊ぼう!"

2.  **遊戲介面 (BigTwoBoardWidget)**
    *   替換對應按鈕的 `Text`：
        *   `Text('Leave')` -> `Text('leave'.tr())`
        *   `Text('Pass')` -> `Text('pass'.tr())`
        *   `Text('Cancel')` -> `Text('cancel'.tr())`
        *   `Text('Play')` -> `Text('play_action'.tr())`

3.  **設定與狀態 (Settings Logic)**
    *   **SettingsScreen (`lib/settings/settings_screen.dart`):**
        *   在顯示當前語言名稱時 (`_getLanguageDisplayName`)，**改為傳入 `context.locale`**，而非 `settings.currentLocale.value`。這確保顯示的名稱永遠對應當前 UI 語言。
    *   **SettingsController (`lib/settings/settings.dart`):**
        *   修改 `cycleLanguage` 方法：在計算 `currentIndex` 時，使用 `context.locale` 作為基準，而非 `currentLocale.value`。這確保點擊切換時，是從當前實際語言切換到下一個。

4.  **Onboarding 頁面 (OnboardingSheet)**
    *   **UI 文字替換：**
        *   `Text('Welcome!', ...)` -> `Text('welcome'.tr(), ...)`
        *   `Text('Tap to change avatar')` -> `Text('tap_to_change_avatar'.tr())` (此 Key 已存在)
        *   `InputDecoration(labelText: 'Your Name', ...)` -> `InputDecoration(labelText: 'your_name'.tr(), ...)`
        *   `Text("Let's Play!", ...)` -> `Text('lets_play'.tr(), ...)`

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **資源：** `assets/translations/en.json`, `zh-TW.json`, `ja.json`
*   **UI：**
    *   `lib/play_session/big_two_board_widget.dart`
    *   `lib/settings/settings_screen.dart`
    *   `lib/settings/onboarding_sheet.dart`
*   **邏輯：**
    *   `lib/settings/settings.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `Effective Dart`。
*   使用 `tr()`。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **遊戲按鈕測試：** 進入遊戲，確認下方按鈕顯示為對應語言 (例如中文環境下應顯示 "跳過", "取消", "出牌")。
2.  **設定頁面顯示測試：**
    *   將手機/模擬器語言設為中文。
    *   啟動 App，進入設定。
    *   確認語言欄位顯示 "繁體中文" (即使 App 預設是英文)。
    *   確認 UI 文字 (如 "設定") 也是中文。
3.  **切換測試：** 點擊右箭頭，確認語言從 "繁體中文" 切換到 "日本語" (或下一個順序語言)，且 UI 即時更新。
4.  **Onboarding 測試：** 若為新用戶（或重置進度後），Onboarding 頁面的 "Welcome!", "Your Name", "Let's Play!" 應顯示為對應系統語言。

#### **4.2 提交訊息 (Commit Message)**

```text
fix: complete game board and onboarding i18n, sync settings locale

Task: FEAT-SETTINGS-I18N-003

- Added translation keys for leave, pass, cancel, play_action, welcome, your_name, and lets_play.
- Updated `BigTwoBoardWidget` and `OnboardingSheet` to use new translation keys.
- Updated `SettingsScreen` to display language name based on `context.locale` to fix mismatch with system locale.
- Updated `SettingsController.cycleLanguage` to cycle based on `context.locale`.
```
