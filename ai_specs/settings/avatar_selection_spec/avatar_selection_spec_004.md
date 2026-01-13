## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-SETTINGS-AVATAR-004` |
| **標題 (Title)** | `ROBUST AVATAR PERSISTENCE WITH THEME MAPPING` |
| **創建日期 (Date)** | `2026/01/14` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

*   **說明：** 重構頭像存取邏輯，引入 `playerAvatarCardTheme` 持久化欄位。透過「主題名稱 + 主題內索引」的對應方式，解決因卡片主題內頭像數量增減而導致的頭像錯亂問題。
*   **目的：**
    1.  **穩定性 (Robustness)：** 確保在未來版本增加或刪除特定主題的頭像時，使用者的頭像選擇保持不變。
    2.  **相容性 (Compatibility)：** 對外維持 `playerAvatarNumber` (全域索引) 的介面，確保現有 UI 元件無須修改。
    3.  **平滑遷移 (Migration)：** 自動將舊版的「全域索引」轉換為新版的「主題 + 內部分量」儲存格式。

#### **1.2 詳細需求 (Detailed Requirements)**

1.  **持久化層擴充 (Persistence Layer)**
    *   在 `SettingsPersistence` 及其相關實作 (`LocalStorageSettingsPersistence`, `MemoryOnlySettingsPersistence`) 中新增：
        *   `Future<String?> getPlayerAvatarCardTheme()`
        *   `Future<void> savePlayerAvatarCardTheme(String value)`
    *   `LocalStorage` 的 Key 使用 `'playerAvatarCardTheme'`。

2.  **SettingsController 邏輯重構**
    *   **屬性保持：** `ValueNotifier<int> playerAvatarNumber` 必須保留，作為全域索引供 UI 使用。
    *   **載入流程 (`_loadStateFromPersistence`)：**
        1.  讀取 `playerAvatarNumber` (視為 index) 與 `playerAvatarCardTheme` (String)。
        2.  **若 `playerAvatarCardTheme` 存在：**
            *   視讀取到的 `playerAvatarNumber` 為「該主題內的索引 (relative index)」。
            *   遍歷 `BigTwoCardTheme.values`，累計之前主題的頭像總數，計算出當前全域索引。
            *   更新 `playerAvatarNumber.value` 為計算出的全域索引。
        3.  **若 `playerAvatarCardTheme` 不存在 (舊版資料)：**
            *   視讀取到的 `playerAvatarNumber` 為「舊版全域索引」。
            *   計算此全域索引對應到的 `BigTwoCardTheme` 與該主題內的相對索引。
            *   立即呼叫 `_store.savePlayerAvatarCardTheme` 以完成資料遷移。
    *   **儲存流程 (`setPlayerAvatarNumber`)：**
        1.  輸入值為 `globalIndex`。
        2.  計算該 `globalIndex` 屬於哪一個 `BigTwoCardTheme` 以及在該主題中的 `relativeIndex`。
        3.  儲存 `relativeIndex` 到原本的 `playerAvatarNumber` 欄位（以維持向下相容）。
        4.  儲存 `theme.name` 到 `playerAvatarCardTheme` 欄位。
        5.  更新 `playerAvatarNumber.value = globalIndex`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響的檔案清單 (Affected Files)**

*   `lib/settings/persistence/settings_persistence.dart`
*   `lib/settings/persistence/local_storage_settings_persistence.dart`
*   `lib/settings/persistence/memory_settings_persistence.dart`
*   `lib/settings/settings.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `effective_dart`。
*   保持現有註解，不進行多餘的排版更動。
*   使用 `Provider` 模式下的 `SettingsController` 進行操作。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **現有轉換測試：** 確保舊版 App 升級後，頭像依然正確顯示。
2.  **穩定性測試：** 模擬在代碼中調整 `BigTwoCardTheme.weaveZoo` 的頭像數量，確認其他主題（如 `weaveDreamMiniature`）的頭像全域索引能正確重新計算，且使用者選定的頭像圖案不變。
3.  **邊界檢查：** 若儲存的主題名稱在當前版本找不到，應回退到預設頭像 (0)。

---

### **Section 4: 改善建議與邏輯檢查 (Review & Suggestions)**

#### **4.1 邏輯檢查與建議**

*   **Helper Method：** 建議在 `SettingsController` 中建立兩個私有方法：
    *   `_getGlobalIndex(String themeName, int relativeIndex)`
    *   `(BigTwoCardTheme, int) _getThemeAndRelativeIndex(int globalIndex)`
*   **預設值：** 若 `getPlayerAvatarCardTheme` 回傳 null，代表是舊用戶或新用戶，邏輯應能正確處理。
*   **順序依賴：** 注意 `avatarList` 的初始化順序，確保在載入持久化資料前，`avatarList` 或 `BigTwoCardTheme` 的資訊已可供計算使用。

#### **4.2 提交訊息 (Commit Message)**

```text
refactor: implement robust avatar persistence with theme mapping

Task: FEAT-SETTINGS-AVATAR-004

- Added `playerAvatarCardTheme` to `SettingsPersistence` and implementations.
- Refactored `SettingsController` to map global avatar index to (Theme, Relative Index).
- Implemented migration logic for legacy global index storage.
- Ensured `playerAvatarNumber` remains consistent for external consumers.
```
