## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-SETTINGS-THEME-002` |
| **標題 (Title)** | `INTRODUCE CARD THEME SELECTION` |
| **創建日期 (Date)** | `2025/12/29` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 實作卡片主題切換功能。引入 `CardTheme` Enum 作為主題的唯一識別，並在設定頁面提供切換 UI。同時新增 "Weave Dream Miniature" (編織夢境微縮模型) 風格的 Manager 實作。
*   **目的：**
    1.  **集中管理 (Centralization)：** 透過 Enum 統一管理所有可用主題及其對應的 Manager 實作。
    2.  **使用者體驗 (UX)：** 讓使用者能預覽並選擇喜歡的卡片風格。
    3.  **擴充性 (Extensibility)：** 未來新增主題時，只需在 Enum 新增 Case 並實作對應 Manager。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **Enum 定義 (Enum Definition)**
    *   建立 `CardTheme` enum，包含兩個 case：
        *   `goblin` (既有的哥布林風格)
        *   `weaveDreamMiniature` (新增的編織風格)
    *   **Property:** 實作 `CardThemeManager get cardManager` getter。
        *   `goblin` 回傳 `GoblinCardThemeManager` 實作。
        *   `weaveDreamMiniature` 回傳 `WeaveCardThemeManager` 實作。
    *   **Helper:** 可能需要 `next` 與 `previous` getter 或 helper method 以支援循環切換 UI。

2.  **介面擴充 (Interface Extension)**
    *   在 `CardThemeManager` 抽象類別中新增 getter:
        *   `String get themePreviewImagePath;`
    *   在 `GoblinCardThemeManager` 與 `WeaveCardThemeManager` 中實作此 getter。

3.  **新增主題實作 (New Theme Implementation)**
    *   建立 `WeaveCardThemeManager`。
    *   設定其對應的背景、卡背、與 Avatar 資源路徑 (假設資源已存在或使用 Placeholder)。

4.  **設定頁面 UI (Settings UI)**
    *   在 `SettingsScreen` (或 `SettingsWidget`) 新增主題選擇區塊。
    *   **Layout:** [左箭頭 Icon] - [主題預覽圖 (Image)] - [右箭頭 Icon]。
    *   **互動:** 點擊箭頭循環切換 `settingsController.currentTheme`。

5.  **狀態管理與持久化 (State & Persistence)**
    *   `SettingsController` 需新增 `ValueNotifier<CardTheme> currentCardTheme` (或類似機制)。
    *   `SettingsPersistence` 需支援儲存與讀取 `CardTheme` (建議存 String name 以避免 Enum 順序變動造成錯誤)。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **新增：**
    *   `lib/style/card_theme_manager/card_theme.dart` (Enum 定義)
    *   `lib/style/card_theme_manager/weave_card_theme_manager.dart` (新實作)
*   **修改：**
    *   `lib/style/card_theme_manager/card_theme_manager.dart` (新增 preview 介面)
    *   `lib/style/card_theme_manager/goblin_card_theme_manager.dart` (實作 preview getter)
    *   `lib/settings/settings.dart` (Controller 新增 Theme 狀態)
    *   `lib/settings/persistence/local_storage_settings_persistence.dart` (儲存邏輯)
    *   `lib/settings/settings_screen.dart` (新增 UI 選擇器)

#### **2.2 程式碼風格 (Style)**

*   遵循 `Effective Dart`。
*   Enum 的 getter 若回傳物件，應考慮物件創建成本 (是否 Singleton 或 const)。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **UI 檢查：** 設定頁面出現主題預覽圖與切換箭頭。
2.  **切換測試：** 點擊箭頭，預覽圖變更，且背景/卡片風格即時更新。
3.  **循環測試：** 在最後一個主題點擊右箭頭應回到第一個；在第一個點擊左箭頭應跳至最後一個。
4.  **持久化測試：** 選擇 `weaveDreamMiniature` 後重啟 App，確認主題仍維持該選擇。

---

### **Section 4: Commit 程式碼分析與審查 (Analysis & Review)**

#### **4.1 邏輯檢查與潛在風險 (Logical Review)**

1.  **物件創建開銷 (Performance)**
    *   **問題：** 若 `CardTheme` enum 中的 `get cardManager` 每次被呼叫都執行 `return GoblinCardThemeManager();`，且該 Manager 沒有定義為 `const` 建構子，會造成頻繁的記憶體分配。
    *   **修正建議：**
        *   若 Manager 無內部狀態 (State)，應宣告為 `const` 建構子，並在 getter 回傳 `const GoblinCardThemeManager()`。
        *   或者使用 Singleton Pattern / Static final instance。

2.  **循環依賴 (Circular Dependency)**
    *   **風險：** `card_theme.dart` (Enum) 引用了 `goblin_card_theme_manager.dart`，而 Manager 實作通常只繼承抽象層，應無反向依賴。但需注意不要讓 `CardThemeManager` 抽象層去引用 `CardTheme` Enum (若非必要)，保持抽象層純淨。

3.  **持久化強健性 (Persistence Robustness)**
    *   **風險：** 直接存 Enum index (0, 1) 風險高。若未來插入新主題至中間，使用者設定會跑掉。
    *   **修正建議：** `SettingsPersistence` 應儲存 `CardTheme.name` (String)，讀取時透過 `CardTheme.values.firstWhere(...)` 找回，並提供 fallback (如 default to goblin)。

#### **4.2 改善建議實作 (Suggested Improvements)**

*   **Enum Extension for Navigation:**
    ```dart
    extension CardThemeNavigation on CardTheme {
      CardTheme next() {
        final nextIndex = (index + 1) % CardTheme.values.length;
        return CardTheme.values[nextIndex];
      }
      
      CardTheme previous() {
        final prevIndex = (index - 1 + CardTheme.values.length) % CardTheme.values.length;
        return CardTheme.values[prevIndex];
      }
    }
    ```

#### **4.3 審查結論**
*   **Verdict:** 規格合理，需注意 Manager 實作的效能優化 (Const/Singleton) 與 Persistence 的 String 轉換。
