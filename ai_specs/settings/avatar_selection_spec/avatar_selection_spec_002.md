## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-SETTINGS-AVATAR-002` |
| **標題 (Title)** | `REFACTOR AVATAR STORAGE TO USE ID` |
| **創建日期 (Date)** | `2025/12/26` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 重構頭像 (Avatar) 的儲存方式，由儲存「完整路徑 (Full Path)」改為儲存「編號 (Avatar Number)」。
*   **目的：**
    1.  **資料優化 (Optimization)：** 減少 Firestore 與網路傳輸的資料量 (字串長度縮減)。
    2.  **解耦 (Decoupling)：** 避免將本地資源路徑 (`assets/...`) 直接寫入遠端資料庫，保留未來更換資源目錄結構的彈性。
    3.  **多人同步 (Sync)：** 確保 `ParticipantInfo` 與 `BigTwoPlayer` 攜帶頭像資訊，以便在遊戲中顯示對手頭像。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **SettingsController 重構**
    *   **位置：** `lib/settings/settings.dart`
    *   **修改狀態：** 將 `playerAvatarPath` (ValueNotifier<String>) 移除，改為 `playerAvatarNumber` (ValueNotifier<String>)。
    *   **預設值：** `"1"` (代表 `goblin_1_001.png`)。
    *   **Getter 擴充：** 新增一個 Getter `String get currentAvatarPath`，負責將 `avatarNumber` 組合回完整路徑 (e.g., `assets/images/goblin_cards/goblin_1_${number.padLeft(3, '0')}.png`) 以供 UI 使用。
    *   **Setter 修改：** 修改為 `setPlayerAvatarNumber(String number)`，並呼叫對應的 Persistence 儲存方法。

2.  **實體類別擴充 (Entity Update)**
    *   **ParticipantInfo (`lib/entities/participant_info.dart`)**
        *   新增欄位：`final String avatarNumber;`
        *   建構子與 `copyWith` (如有) 需同步更新。
        *   執行 `build_runner` 更新 `.g.dart`。
    *   **BigTwoPlayer (`lib/entities/big_two_player.dart`)**
        *   新增欄位：`final String avatarNumber;`
        *   預設值可設為 `"1"`。
        *   執行 `build_runner` 更新 `.g.dart`。

3.  **Persistence 與測試工具更新 (Persistence & Test Utilities)**
    *   **SettingsPersistence (`lib/settings/persistence/settings_persistence.dart`)**
        *   介面方法重新命名：`getPlayerAvatarPath` -> `getPlayerAvatarNumber`。
        *   介面方法重新命名：`savePlayerAvatarPath` -> `savePlayerAvatarNumber`。
    *   **MemoryOnlySettingsPersistence (`lib/settings/persistence/memory_settings_persistence.dart`)**
        *   同步實作介面變更。
        *   內部變數 `playerAvatarPath` 改為 `playerAvatarNumber`，預設值改為 `"1"`。
    *   **FakeSettingsController (`lib/settings/fake_settings_controller.dart`)**
        *   `playerAvatarPath` (ValueNotifier) 改為 `playerAvatarNumber`，預設值改為 `"1"`。
        *   方法 `setPlayerAvatarPath` 改為 `setPlayerAvatarNumber`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/settings/settings.dart` (Refactor State & Logic)
*   **修改：** `lib/entities/participant_info.dart` (Add Field)
*   **修改：** `lib/entities/big_two_player.dart` (Add Field)
*   **修改：** `lib/settings/persistence/settings_persistence.dart` (Interface Rename)
*   **修改：** `lib/settings/persistence/local_storage_settings_persistence.dart` (Impl Rename & Logic)
*   **修改：** `lib/settings/persistence/memory_settings_persistence.dart` (Test Impl Update)
*   **修改：** `lib/settings/fake_settings_controller.dart` (Test Fake Update)

#### **2.2 程式碼風格 (Style)**

*   遵循 `Effective Dart`。
*   保持 `SettingsController` 的 `ValueNotifier` 模式。
*   實體類別需維持 `JsonSerializable` 標註。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **單元測試/邏輯驗證：**
    *   呼叫 `setPlayerAvatarNumber("5")`，檢查 `currentAvatarPath` 是否正確回傳 `.../goblin_1_005.png` (假設命名規則)。
2.  **序列化驗證：**
    *   建立 `ParticipantInfo` 物件並轉為 JSON，確認包含 `avatarNumber` 欄位。
3.  **Persistence 驗證：**
    *   重啟 App，確認 `avatarNumber` 能正確從本地儲存載入。

---

### **Section 4: 改善建議與邏輯檢查 (Review & Suggestions)**

#### **4.1 邏輯檢查與建議**

*   **相容性遷移 (Migration Strategy)：**
    *   **風險：** 使用者的 LocalStorage 可能仍存著舊的 Key (`playerAvatarPath`) 或完整路徑字串。
    *   **建議：** 在 `_loadStateFromPersistence` 中加入簡單的遷移邏輯。如果讀取到的字串包含 "assets/"，則嘗試解析出數字部分，或者直接重置為預設值 "1"，並寫入新的 Key。
*   **資源命名規則 (Naming Convention)：**
    *   **風險：** 目前假設檔名為 `goblin_1_001.png`。如果未來有 `goblin_2_xxx`，單純存一個數字可能不夠。
    *   **建議：** 確保 `avatarNumber` 的解析邏輯與 `AvatarSelectionScreen` 的資源列表邏輯一致。如果圖片命名不規則，建議建立一個 `Map<String, String> avatarIdToPath` 的查找表 (Const Map)。
*   **Controller 影響範圍：**
    *   `FirestoreRoomStateController` 在建立房間時會建構 `participants` 資料。
    *   **Action：** 重構完 `SettingsController` 後，記得更新 `createRoom` 與 `join` 相關邏輯，將 `_settingsController.playerAvatarNumber.value` 填入 `ParticipantInfo`。
