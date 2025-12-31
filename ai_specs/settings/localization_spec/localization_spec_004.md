## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-SETTINGS-I18N-004` |
| **標題 (Title)** | `FIX MAIN MENU I18N REFRESH ISSUE ON WEB` |
| **創建日期 (Date)** | `2025/12/31` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：**
    1.  **解決 MainMenuScreen 在 Web 環境下的刷新問題：** 用戶回報 `MainMenuScreen` 在 Web 環境下，設定變更後（例如語言切換）無法即時反應多語言變更，需手動重新整理。
    2.  **原因分析：** `MainMenuScreen` 作為一個 `StatelessWidget`，雖然透過 `context.watch<SettingsController>()` 監聽了設定變更，但 `easy_localization` 的 `tr()` 方法依賴於 Context 的 Locale 變更通知。在某些情況下（特別是 Web 或某些 Provider 結構），僅監聽 `SettingsController` 物件本身可能不足以觸發依賴 `InheritedWidget` (如 `EasyLocalizationProvider`) 的重建，或者 `SettingsController` 變更時並未觸發整個頁面的 Rebuild。
    3.  **解決方案：** 參照 `SettingsScreen` 的修復方式，使用 `ValueListenableBuilder<Locale>` 明確監聽 `settingsController.currentLocale`，強制 UI 在 Locale 變更時重繪。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **MainMenuScreen (`lib/main_menu/main_menu_screen.dart`)**
    *   **包裹 `ValueListenableBuilder<Locale>`:**
        *   將主要的 UI 結構（在 `ValueListenableBuilder<BigTwoCardTheme>` 之外或之內，視最佳實踐而定）包裹在 `ValueListenableBuilder<Locale>` 中。
        *   監聽對象：`settingsController.currentLocale`。
    *   **結構建議：**
        ```dart
        // 外層
        return ValueListenableBuilder<Locale>(
          valueListenable: settingsController.currentLocale,
          builder: (context, locale, child) {
             // 內層原本的 CardTheme Builder
             return ValueListenableBuilder<BigTwoCardTheme>(...);
          }
        );
        ```

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **UI：** `lib/main_menu/main_menu_screen.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `Effective Dart`。
*   使用 `ValueListenableBuilder` 巢狀結構。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **Web 測試 (模擬)：** 雖然無法直接在此環境跑 Web，但邏輯上應確保 `MainMenuScreen` 的 `build` 方法會在 `currentLocale` 變更時被呼叫。
2.  **流程驗證：**
    *   進入設定頁。
    *   切換語言。
    *   返回主選單。
    *   主選單按鈕 ("Play", "Settings") 應顯示為新語言。

#### **4.2 提交訊息 (Commit Message)**

```text
fix: solve main menu i18n refresh issue on web

Task: FEAT-SETTINGS-I18N-004

- Wrapped `MainMenuScreen` in `ValueListenableBuilder<Locale>` to force rebuild on language change.
```
