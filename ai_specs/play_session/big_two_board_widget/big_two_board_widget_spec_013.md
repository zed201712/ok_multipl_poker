## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-UI-013` |
| **標題 (Title)** | `IMPLEMENT PLAYER AVATAR WIDGET IN BOARD` |
| **創建日期 (Date)** | `2025/12/26` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：**
    建立一個可重複使用的 `PlayerAvatarWidget`，並將其整合至 `BigTwoBoardWidget` 中，使本地玩家與對手皆能顯示其選擇的頭像。
*   **目的：**
    1.  **視覺識別 (Visual Identity)：** 讓玩家在遊戲中能透過頭像識別自己與對手 (目前僅顯示文字)。
    2.  **代碼重用 (Code Reusability)：** 將頭像顯示邏輯 (路徑解析、圓形裁切、邊框) 封裝為單一 Widget，取代重複的樣板程式碼。
    3.  **UI 豐富度 (UI Richness)：** 填補 Flex Grid 佈局中的視覺空白。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **新增 `PlayerAvatarWidget`**
    *   **位置：** `lib/widgets/player_avatar_widget.dart` (新檔案)。
    *   **參數：**
        *   `final String avatarNumber;` (必填)
        *   `final double size;` (選填，預設可設為 40.0 或 50.0)
    *   **顯示邏輯：**
        *   將 `avatarNumber` 格式化為路徑：`'assets/images/goblin_cards/goblin_1_${avatarNumber.padLeft(3, '0')}.png'`。
        *   使用 `Container` + `BoxDecoration` 實作圓形頭像與白框 (參考 `OnboardingSheet` 樣式)。
        *   **樣式細節：**
            *   `shape: BoxShape.circle`
            *   `border: Border.all(color: Colors.white, width: 3)`
            *   `fit: BoxFit.cover`

2.  **整合至對手區域 (`_OpponentHand`)**
    *   **位置：** `lib/play_session/big_two_board_widget.dart` 內的 `_OpponentHand` class。
    *   **佈局變更：**
        *   將原本的 `Column` (名字, 牌數) 包裝進一個 `Row`。
        *   在 `Row` 的左側加入 `PlayerAvatarWidget`。
        *   **資料來源：** `avatarNumber` 從 `BigTwoPlayer` 物件中取得。
    *   **間距：** 頭像與資訊區塊間加入適當 `SizedBox(width: 8)`。

3.  **整合至本地玩家區域 (Local Player Area)**
    *   **位置：** `lib/play_session/big_two_board_widget.dart` 的 Bottom Area。
    *   **佈局變更：**
        *   找到顯示 "YOUR TURN" 的 `Container`。
        *   將該 `Container` 與新增的 `PlayerAvatarWidget` 包裝進一個 `Row` (MainAxisSize.min)。
        *   `PlayerAvatarWidget` 放在 "YOUR TURN" 的左方。
    *   **資料來源：** 透過 `context.watch<SettingsController>().playerAvatarNumber.value` 取得。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **新增：** `lib/widgets/player_avatar_widget.dart`
*   **修改：** `lib/play_session/big_two_board_widget.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `Effective Dart`。
*   Widget 應為 `StatelessWidget`。
*   使用 `const` 建構子優化效能。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **本地頭像測試：**
    *   進入設定頁更換頭像。
    *   進入遊戲，確認 "YOUR TURN" 左側顯示正確的頭像。
2.  **對手頭像測試：**
    *   (若無多人連線環境) 檢查程式碼是否正確傳遞 `BigTwoPlayer.avatarNumber`。
    *   確認 Top, Left, Right 對手區域皆顯示頭像。
3.  **佈局測試：**
    *   確認加入頭像後，Left/Right 對手區域 (位於窄 `SizedBox` 內) 不會發生 Overflow。
    *   *註：* 由於左右對手是 `RotatedBox`，增加寬度 (視覺上的高度) 應不會影響版面，但需注意 `Row` 的長度是否超出 Grid 邊界。

---

### **Section 4: 改善建議與邏輯檢查 (Review & Suggestions)**

#### **4.1 邏輯檢查與建議**

*   **路徑解析安全性：**
    *   `PlayerAvatarWidget` 應處理 `avatarNumber` 為空字串或格式錯誤的情況，建議預設為 "1" 或顯示錯誤佔位圖，避免 crash。
*   **左右對手佈局風險：**
    *   在 Flex Grid 佈局中，左右對手區塊寬度僅佔 10% (`89.6 px`)。
    *   `_OpponentHand` 原本是垂直排列文字與圖示。改為 `Row` (頭像 + Column) 後，在 `RotatedBox` 旋轉 90 度後，這個 `Row` 會變成視覺上的「垂直堆疊」。
    *   **關鍵檢查：** 需確認 `Row` 的總寬度 (視覺上的高度) 不會超過 Middle Area 的高度 (`414 * (10/29) ≈ 142 px`)。若內容過多，建議調整頭像大小 (e.g., 30.0) 或字體大小。

#### **4.2 提交訊息 (Commit Message)**

```text
feat: add player avatar widget to game board

Task: FEAT-BIG-TWO-UI-013

- Created `PlayerAvatarWidget` to encapsulate avatar display logic.
- Integrated avatars into `_OpponentHand` for top/side players.
- Added local player avatar next to the "YOUR TURN" indicator.
```
