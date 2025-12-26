## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-SETTINGS-AVATAR-003` |
| **標題 (Title)** | `ENHANCE AVATAR SELECTION UX WITH DESCRIPTION & CONFIRMATION` |
| **創建日期 (Date)** | `2025/12/26` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 優化 `AvatarSelectionScreen` 的使用者體驗，將原本「點擊即選定並返回」的行為，改為「預覽選擇 -> 顯示說明 -> 確認後生效」的流程。
*   **目的：**
    1.  **資訊豐富化 (Information)：** 為每個頭像提供文字描述，增加角色代入感。
    2.  **防呆機制 (Confirmation)：** 避免使用者誤觸頭像導致直接更改設定並跳出，提供確認步驟。
    3.  **UI 佈局優化 (Layout)：** 利用 `ResponsiveScreen` 的空間配置，加入底部操作區。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **資料結構新增**
    *   在 `_AvatarSelectionScreenState` 中新增描述資料：
        ```dart
        final String _defaultAvatarDescription = 'A mysterious goblin.'; // TODO: 填入預設描述
        final Map<String, String> _avatarDescriptions = {
          '1': 'The brave beginner goblin.',
          // TODO: 補齊其他對應描述，或預留空 Map 待填
        };
        ```
    *   新增 **Local State** `String _selectedAvatarNumber`：
        *   `initState` 時，需初始化為 `context.read<SettingsController>().playerAvatarNumber.value`。
        *   **注意：** 用戶在 GridView 點擊時，僅更新此 Local State，**不**直接呼叫 `settings.setPlayerAvatarNumber`。

2.  **UI 佈局更新**
    *   **GridView 互動修改：**
        *   `onTap` 事件改為 `setState(() => _selectedAvatarNumber = avatarNumber)`。
        *   選取框 (Border) 的判斷依據改為 `_selectedAvatarNumber == avatarNumber`。
    *   **底部區域新增 (Bottom Area)：**
        *   利用 `ResponsiveScreen` 的 `rectangularMenuArea` (或在 body Column 中自行構建底部區塊)。
        *   **內容包含：**
            1.  **描述文字 (Description Text)：** 顯示 `_avatarDescriptions[_selectedAvatarNumber] ?? _defaultAvatarDescription`。文字需置中，樣式需清晰。
            2.  **操作按鈕列 (Action Bar)：** 位於描述文字下方。
                *   **左側 (Cancel)：** 紅色 X 按鈕 (Icon: `close`, Color: `Colors.red`)。點擊後執行 `Navigator.pop` (不儲存)。
                *   **右側 (Confirm)：** 綠色或主題色打勾按鈕 (Icon: `check`)。點擊後執行 `settings.setPlayerAvatarNumber(_selectedAvatarNumber)` 並 `Navigator.pop`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/settings/avatar_selection_screen.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `Effective Dart`。
*   UI 應保持與現有 `Permanent Marker` 字體風格一致。
*   使用 `Row` 與 `MainAxisAlignment.spaceEvenly` 或 `spaceBetween` 來排列底部按鈕。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **預覽行為：** 進入畫面，點擊不同頭像。確認黃色選取框會移動，且下方描述文字會隨之改變，但 Settings 中的頭像尚未變更。
2.  **取消操作：** 點擊紅色 X 按鈕。確認回到上一頁後，設定檔中的頭像維持原樣。
3.  **確認操作：** 點擊打勾按鈕。確認回到上一頁後，設定檔中的頭像已更新為最後選擇的項目。
4.  **例外處理：** 選擇一個沒有定義在 Map 中的 `avatarNumber`，確認顯示 `_defaultAvatarDescription`。

---

### **Section 4: 改善建議與邏輯檢查 (Review & Suggestions)**

#### **4.1 邏輯檢查與建議**

*   **初始狀態同步：** 務必確保進入畫面時，選取框正確停在當前設定的頭像上 (在 `initState` 處理)。
*   **按鈕樣式：** 建議按鈕使用 `FloatingActionButton` (mini) 樣式或圓形 `ElevatedButton`，以符合遊戲風格。
*   **空間配置：** 若描述文字過長，可能會導致畫面溢出 (Overflow)。建議將描述文字包在 `Flexible` 或限制行數，或確保 `ResponsiveScreen` 的佈局能容納。
*   **AssetManifest：** 雖然本次任務未強制要求，但若圖片是動態生成的，確保 Map 的 Key 與圖片生成的 ID 邏輯一致 (目前是 `'1', '2'...`)。

#### **4.2 提交訊息 (Commit Message)**

```text
feat: enhance avatar selection with description and confirmation

Task: FEAT-SETTINGS-AVATAR-003

- Added `_avatarDescriptions` map and default description.
- Implemented local state `_selectedAvatarNumber` for previewing.
- Added bottom area with dynamic description text.
- Added Cancel (X) and Confirm (Check) buttons for safe selection flow.
```
