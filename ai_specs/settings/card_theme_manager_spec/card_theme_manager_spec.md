## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-SETTINGS-THEME-001` |
| **標題 (Title)** | `INTRODUCE CARD THEME MANAGER` |
| **創建日期 (Date)** | `2025/12/28` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 引入 `CardThemeManager` 介面與 `GoblinCardThemeManager` 實作，將卡片圖案、背景與頭像資源的路徑管理從 UI 邏輯中抽離。同時將使用者頭像 (Avatar) 的資料型態由 `String` 改為 `int` (0-based index)，以利於陣列存取與後續擴充。
*   **目的：**
    1.  **解耦 (Decoupling)：** UI 元件 (如 `BigTwoBoardCardArea`, `SelectablePlayerHandWidget`) 不應硬編碼 (Hardcode) 圖片路徑，改由 Theme Manager 統一提供。
    2.  **型態優化 (Type Refactor)：** 將 `avatarNumber` 由字串 ("1", "2") 改為整數索引 (0, 1)，更符合程式邏輯並簡化列表操作。
    3.  **可擴充性 (Extensibility)：** 未來若需新增其他風格 (如 "Cyberpunk Theme")，只需新增實作 `CardThemeManager` 的類別並切換即可。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **架構變更 (Architecture Changes)**
    *   新增 `lib/style/card_theme_manager/` 目錄。
    *   定義 `CardThemeManager` 抽象類別，包含取得卡片圖片、背景圖片、Avatar 列表等方法。
    *   實作 `GoblinCardThemeManager`，負責管理哥布林風格的資源路徑。
    *   定義 `AvatarEntity`，封裝頭像圖片路徑與描述。

2.  **資料結構變更 (Data Structure Changes)**
    *   **SettingsController**: `playerAvatarNumber` 由 `ValueNotifier<String>` 改為 `ValueNotifier<int>`。
    *   **BigTwoPlayer / ParticipantInfo**: `avatarNumber` 欄位由 `String` 改為 `int`。
    *   **SettingsPersistence**: 儲存與讀取 `avatarNumber` 的介面與實作需對應修改為 `int`。

3.  **UI 整合 (UI Integration)**
    *   **MainMenuScreen / PlaySessionScreen**: 背景圖片改由 `settingsController.currentCardTheme` 取得。
    *   **BigTwoBoardCardArea / PlayingCardImageWidget**: 卡片正反面圖片路徑改由 Theme Manager 提供。
    *   **AvatarSelectionScreen**: 頭像列表改由 `settings.avatarList` 取得，選取邏輯改為 `int` 索引。

4.  **遷移邏輯 (Migration)**
    *   需處理舊有資料 (String "1", "2"...) 與新資料 (int 0, 1...) 的兼容性或轉換。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **新增：**
    *   `lib/style/card_theme_manager/card_theme_manager.dart`
    *   `lib/style/card_theme_manager/goblin_card_theme_manager.dart`
    *   `lib/style/card_theme_manager/avatar_entity.dart`
*   **修改：**
    *   `lib/entities/big_two_player.dart` (型態變更)
    *   `lib/entities/participant_info.dart` (型態變更)
    *   `lib/settings/settings.dart` (引入 Theme, 型態變更)
    *   `lib/settings/persistence/*` (Persistence 實作變更)
    *   `lib/play_session/*` (UI 使用 Theme)
    *   `lib/settings/avatar_selection_screen.dart` (邏輯重構)

#### **2.2 程式碼風格 (Style)**

*   保持 `Effective Dart` 風格。
*   資源路徑統一收斂至 `CardThemeManager` 實作中，外部不得直接引用 `assets/images/...` 字串。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **外觀檢查：** 進入遊戲，確認背景、卡背、卡面顯示是否正確載入 Goblin Theme 資源。
2.  **頭像切換：** 進入設定頁面，切換頭像，確認 `playerAvatarNumber` 更新正確，且 UI 即時反映。
3.  **持久化測試：** 重啟 App，確認設定的頭像是否被保留。
4.  **多人連線資料傳輸：** (若有環境) 確認傳送至 Firestore 的 `BigTwoPlayer` 資料包含正確的 `int` avatarNumber，且其他玩家能正確解析顯示。

---

### **Section 4: Commit 程式碼分析與審查 (Analysis & Review)**

#### **4.1 邏輯檢查與潛在風險 (Logical Review)**

1.  **SharedPreferences 兼容性崩潰 (Critical)**
    *   **問題：** `LocalStorageSettingsPersistence` 中直接將 `prefs.getString` 改為 `prefs.getInt`。若舊用戶的手機中已儲存了 String 型態的 "1"，呼叫 `prefs.getInt('playerAvatarNumber')` 會在 Android 上拋出 `ClassCastException`，導致 App 啟動崩潰。
    *   **建議：** 實作更健壯的讀取邏輯。先嘗試 `get` (Object)，判斷型態。若是 String 則 `tryParse` 並存回 int；若是 int 則直接使用。

2.  **Firestore 資料與索引偏移 (Major)**
    *   **問題：**
        1.  舊資料在 Firestore 中可能存為 String "1"。新程式碼 `(json['avatarNumber'] as num?)?.toInt()` 若遇到 String 會拋出 Cast Error。
        2.  **索引偏移：** 舊版 "1" 對應 `goblin_1_001.png`。新版 `avatarList` 是 0-based，所以 index 0 對應 `goblin_1_001.png`。若直接將舊字串 "1" 轉為 int 1，會對應到 `goblin_1_002.png`，導致用戶頭像改變。
    *   **建議：**
        *   `fromJson` 需同時支援 String 與 int 輸入。
        *   若輸入為 String "1"，應轉換為 int 0 (value - 1)。

3.  **預設值一致性**
    *   `SettingsController` 預設 `playerAvatarNumber = 0`。
    *   `FakeSettingsController` 預設也是 `0`。
    *   需確保 `AvatarSelectionScreen` 處理 `0` 時是指向列表的第一個元素。

#### **4.2 改善建議實作 (Suggested Improvements)**

*   **SettingsPersistence 遷移代碼範例：**
    ```dart
    // In LocalStorageSettingsPersistence
    @override
    Future<int> getPlayerAvatarNumber() async {
      final prefs = await instanceFuture;
      final value = prefs.get('playerAvatarNumber');
      if (value is int) {
        return value;
      } else if (value is String) {
        // Migration: Old "1" -> New 0
        final oldNum = int.tryParse(value) ?? 1;
        final newIndex = (oldNum > 0) ? oldNum - 1 : 0;
        await savePlayerAvatarNumber(newIndex); // Migrate immediately
        return newIndex;
      }
      return 0; // Default
    }
    ```

*   **Entity fromJson 兼容代碼範例：**
    ```dart
    // In BigTwoPlayer.fromJson
    avatarNumber: _parseAvatarNumber(json['avatarNumber']),
    
    // Helper
    static int _parseAvatarNumber(dynamic value) {
      if (value is int) return value;
      if (value is String) {
        final i = int.tryParse(value) ?? 1;
        return (i > 0) ? i - 1 : 0;
      }
      return 0;
    }
    ```

#### **4.3 審查結論**
*   **Verdict:** 架構重構方向正確，但資料遷移 (Migration) 邏輯存在高風險錯誤，必須修正後才可發布。

