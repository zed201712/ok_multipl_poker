## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-SETTINGS-I18N-002` |
| **標題 (Title)** | `FIX LOCALIZATION REFRESH & IMPLEMENT GAME BOARD I18N` |
| **創建日期 (Date)** | `2025/12/31` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：**
    1.  **修正設定頁面刷新問題：** 解決在 `SettingsScreen` 切換語言後，頁面文字沒有即時更新（需等待重新進入或熱重載）的問題。
    2.  **遊戲介面多語言化：** 將 `BigTwoBoardWidget` 中的硬編碼文字（Hardcoded Strings）替換為多語言支援，包含遊戲狀態與牌型按鈕。
*   **限制：**
    *   在修改 `BigTwoBoardWidget` 時，**嚴禁修改程式碼結構**（如邏輯流程、變數定義位置等），僅允許替換 `Text("String")` 為 `Text("key".tr())` 形式。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **資源檔更新 (Asset Updates)**
    *   在 `assets/translations/` 的 `en.json`, `zh-TW.json`, `ja.json` 中新增以下 Key：
        *   `your_turn`: "YOUR TURN" / "輪到你了" / "あなたの番"
        *   `match_room`: "Match Room" / "配對房間" / "マッチルーム" (若尚未存在)
        *   **牌型 (Patterns):** 使用 `patterns.{enumName}` 格式。
            *   `patterns.single`: "Single" / "單張" / "シングル"
            *   `patterns.pair`: "Pair" / "對子" / "ペア"
            *   `patterns.straight`: "Straight" / "順子" / "ストレート"
            *   `patterns.fullHouse`: "Full House" / "葫蘆" / "フルハウス"
            *   `patterns.fourOfAKind`: "Four of a Kind" / "鐵支" / "フォーカード"
            *   `patterns.straightFlush`: "Straight Flush" / "同花順" / "ストレートフラッシュ"

2.  **設定頁面 (SettingsScreen)**
    *   **問題分析：** 目前 `SettingsScreen` 僅在「語言選擇 Row」使用了 `ValueListenableBuilder`，導致標題與其他文字未監聽語言變更。
    *   **解決方案：** 將 `SettingsScreen` 的 `build` 方法中的主要 `Scaffold` 或 `ResponsiveScreen` 包裹在 `ValueListenableBuilder<Locale>` 中，監聽 `settings.currentLocale`。這樣當語言變更時，整個頁面會重繪，觸發 `tr()` 更新。

3.  **遊戲介面 (BigTwoBoardWidget)**
    *   引入 `easy_localization`。
    *   **狀態文字替換：**
        *   `'Matching...\nPlayers: ...'` -> 使用 `'matching'.tr()` 加上玩家人數變數。
        *   `'Ready to start'` -> `'ready'.tr()`
        *   `'Start'` -> `'start'.tr()`
        *   `'Match Room'` -> `'match_room'.tr()`
    *   **提示文字替換：**
        *   `"YOUR TURN"` -> `'your_turn'.tr()`
    *   **按鈕文字替換 (handTypeButtons):**
        *   `Text(pattern.displayName)` -> 修改為 `Text('patterns.${pattern.name}'.tr())`。
        *   利用 `pattern.name` (CamelCase) 對應 JSON Key。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **資源：** `assets/translations/en.json`, `zh-TW.json`, `ja.json`
*   **UI：**
    *   `lib/settings/settings_screen.dart`
    *   `lib/play_session/big_two_board_widget.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `Effective Dart`。
*   使用 `Provider` 獲取狀態 (已存在)。
*   **關鍵：** 保持 `BigTwoBoardWidget` 原有結構，只動字串部分。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **設定頁面測試：** 進入設定，點擊左右箭頭切換語言，確認標題 "Settings" / "設定" / "設定" 即時變更，無需重啟。
2.  **遊戲頁面測試：**
    *   進入遊戲大廳，確認 "Ready to start", "Match Room" 顯示為對應語言。
    *   開始遊戲後，確認 "YOUR TURN" 與下方的牌型按鈕 (Single, Pair...) 顯示為對應語言。

---

### **Section 4: 改善建議與邏輯檢查 (Review & Suggestions)**

#### **4.1 邏輯檢查**

*   **SettingsScreen Refresh:** 雖然 `easy_localization` 的 `context.setLocale` 理論上會重建 Root Widget，但在某些架構下（特別是使用了多層 Provider 或 Router 時），直接在頁面層級監聽 `currentLocale` 是最保險且反應最快的做法，能確保 User Experience 的流暢性。
*   **Pattern Display Name:** 原本 `pattern.displayName` 用於顯示，現在改用 Key。需確保所有 `BigTwoCardPattern` 的 enum names 都有對應的 JSON Key，否則會顯示 Key 字串。

#### **4.2 提交訊息 (Commit Message)**

```text
fix: improve localization refresh and add game board i18n

Task: FEAT-SETTINGS-I18N-002

- Wrapped `SettingsScreen` in `ValueListenableBuilder` to ensure immediate UI updates on language change.
- Added translation keys for game status, "Your Turn", and card patterns in en/zh-TW/ja.
- Updated `BigTwoBoardWidget` to use `tr()` for UI texts and buttons without altering code structure.
```
