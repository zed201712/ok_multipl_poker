## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-UI-011` |
| **標題 (Title)** | `IMPLEMENT GLOBAL SCALING FOR BOARD WIDGET` |
| **創建日期 (Date)** | `2025/12/26` |
| **更新日期 (Update)** | `2025/12/26` (Reflected Implementation) |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：**
    解決 `BigTwoBoardWidget` 在各式裝置上佈局不一致的問題。採用 **Global Scaling (FittedBox Approach)** 策略，將遊戲畫面視為固定比例的畫布（橫向設計），並自動縮放以適應不同螢幕尺寸。

*   **目的：**
    1.  **適應性 (Adaptability)：** 確保遊戲介面在手機、平板等不同螢幕上，皆能維持設計時的比例與佈局，避免元件重疊。
    2.  **橫向體驗 (Landscape Experience)：** 鎖定設計解析度為橫向，提供更寬廣的桌面視野。
    3.  **一致性 (Consistency)：** 保持各元件間的相對位置與比例，確保視覺體驗一致。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **定義設計解析度 (Design Resolution)**
    *   **設定值：** `Size(896, 414)` (Landscape, 類似 iPhone 11/Max 橫向邏輯解析度)。
    *   所有佈局邏輯（Padding, Offset, Positioned）皆基於此解析度運作。

2.  **實作全局縮放 (FittedBox Implementation)**
    *   在 `BigTwoBoardWidget` 的 `Scaffold` body 中，使用 `FittedBox` 包裹主要的遊戲佈局 (`Stack`)。
    *   **結構層級：**
        ```dart
        Scaffold(
          body: Center( // 確保縮放後置中
            child: FittedBox(
              fit: BoxFit.contain, // 保持比例縮放，確保內容完整可見
              child: SizedBox(
                 width: 896, // designSize.width
                 height: 414, // designSize.height
                 child: Stack( ... ) // 原有的遊戲內容
              ),
            ),
          ),
        )
        ```

3.  **手牌區域優化 (SelectablePlayerHandWidget)**
    *   **佈局容器變更：** 將 `Wrap` 改為 `Row`。
        *   *原因：* 在固定高度的橫向設計中，`Wrap` 自動換行會導致手牌區高度不可控，進而遮擋桌面或超出邊界。
    *   **卡牌尺寸固定：** 設定固定的 `cardWidth` (e.g., 40.0) 與對應比例的 `height`，確保在 `Row` 中排列整齊。

4.  **UI 文字與狀態顯示**
    *   將介面文字統一為英文以符合國際化或專案慣例：
        *   "配對中..." -> "Matching...\nPlayers: {count}"
        *   "準備開始..." -> "Ready to start"
        *   "開始遊戲" -> "Start"

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/play_session/big_two_board_widget.dart` (Scaling Logic & Layout)
*   **修改：** `lib/play_session/selectable_player_hand_widget.dart` (Row Layout & Fixed Size)

#### **2.2 程式碼風格 (Style)**

*   遵循 `Effective Dart`。
*   使用 `static const Size designSize = Size(896, 414);` 定義常數。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **橫向/縮放測試：**
    *   在不同模擬器 (直式/橫式) 執行，確認 `FittedBox` 能將內容縮放至螢幕寬度 (或高度) 內，且無內容被切斷。
2.  **手牌顯示：**
    *   發滿 13 張牌，確認 `Row` 排列正常，無溢位 (Overflow) 警告 (配合 SingleChildScrollView 或足夠的寬度/重疊邏輯)。
3.  **互動測試：**
    *   確認縮放後的按鈕與卡牌仍可準確點擊。

---

### **Section 4: 改善建議與邏輯檢查 (Review & Suggestions)**

#### **4.1 邏輯檢查與建議**

*   **長寬比問題 (Aspect Ratio)：**
    *   使用 896:414 (約 2.16:1) 適合現代全面屏手機的橫向模式。
    *   在較方正的裝置 (如 iPad 4:3) 上，上下會有較多留白 (Letterboxing)，這是 `BoxFit.contain` 的預期行為。
*   **手牌溢位風險：**
    *   若手牌過多 (例如 >13 張或寬度不足)，單純 `Row` 可能會 Overflow。建議 `SelectablePlayerHandWidget` 內部實作卡牌重疊 (Overlap) 邏輯或使用 `ListView.horizontal`，但在目前 `FittedBox` 架構下，固定寬度通常足夠容納標準手牌數。

#### **4.2 提交訊息 (Commit Message)**

```text
feat: implement landscape global scaling for board

Task: FEAT-BIG-TWO-UI-011

- Updated BigTwoBoardWidget to use FittedBox with 896x414 landscape design resolution.
- Refactored SelectablePlayerHandWidget to use Row and fixed card sizes for stable layout.
- Updated UI text to English.
```
