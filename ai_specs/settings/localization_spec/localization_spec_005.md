## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-LOCALIZATION-005` |
| **標題 (Title)** | `LOCALIZE GAME SESSION UI STRINGS` |
| **創建日期 (Date)** | `2026/01/05` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：**
    1.  **多語言化遊戲主畫面文字：** 針對 `BigTwoBoardCardArea` 與 `BigTwoBoardWidget` 中尚未翻譯的硬編碼字串（Hardcoded Strings）進行 `easy_localization` 整合。
    2.  **優化翻譯邏輯：** 修正字串拼接導致的翻譯彈性不足問題，並確保動態內容（如牌型名稱）能隨語言切換即時更新。
    3.  **狀態管理：** 確保所有 UI 文字均在 `build` 方法中透過 `tr()` 生成，以利用 `easy_localization` 的機制或 `SettingsController` 的重繪觸發更新。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **BigTwoBoardCardArea (`lib/play_session/big_two_board_card_area.dart`)**
    *   **Last Played Title:**
        *   **現狀：** `title: 'Last Played $lastPlayedTitle'`，且 `lastPlayedTitle` 來自 `pattern.displayName` (可能是硬編碼)。
        *   **修改：** 應將牌型名稱透過 `tr()` 處理。
        *   **Key:** `game.last_played_title` (例如: "Last Played (@:patterns.{pattern_name})") 或拆分為兩段 UI。
        *   **建議代碼：**
            ```dart
            // 移除 pattern.displayName 依賴，直接翻譯
            String patternName = pattern != null ? 'patterns.${pattern.name}'.tr() : '';
            // 使用參數化翻譯
            title: 'game.last_played'.tr(args: [patternName]),
            ```
    *   **Discard Pile:**
        *   **現狀：** `title: 'Discard Pile'`
        *   **修改：** 使用 `tr()`。
        *   **Key:** `game.discard_pile`
    *   **Discard Dialog:**
        *   **現狀：** `title: 'Discard Pile'`, `const Text('Close')`
        *   **修改：** 全部替換為 `tr()`。
        *   **Key:** `common.close` (通用關閉)

2.  **BigTwoBoardWidget (`lib/play_session/big_two_board_widget.dart`)**
    *   **Matching Status:**
        *   **現狀：** `Text('${'matching'.tr()}\nPlayers: ${_gameController.participantCount()}')`
        *   **問題：** "Players:" 為硬編碼，且換行結構寫死。
        *   **修改：** 使用帶參數的翻譯 Key。
        *   **Key:** `game.matching_status` (Value 範例: "Matching...\nPlayers: {}")
    *   **Leave / Restart Buttons:**
        *   檢查 `_leaveButton()` 實作（若在該檔內）是否已翻譯。
        *   若 `GameStatus.finished` 狀態下有 "Restart" 按鈕，需確保使用 `game.restart` Key。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **UI:** `lib/play_session/big_two_board_card_area.dart`
*   **UI:** `lib/play_session/big_two_board_widget.dart`
*   **Assets:** `assets/translations/en-US.json`, `assets/translations/zh-TW.json` (需新增對應 Keys)

#### **2.2 程式碼風格 (Style)**

*   遵循 `Effective Dart`。
*   **避免**在 `build` 之外 (如 `initState`) 賦值翻譯字串，確保熱重載與語言切換能即時生效。
*   使用 `tr(args: [])` 或 `tr(namedArgs: {})` 處理動態變數，而非 Dart 字串插值 `$var`。

---

### **Section 3: 邏輯檢查與改善建議 (Logic Review & Improvements)**

#### **3.1 潛在邏輯錯誤 (Logic Check)**

1.  **Pattern Display Name 依賴錯誤：**
    *   `BigTwoBoardCardArea` 中 `pattern.displayName` 若是在 `BigTwoCardPattern` class 內定義的 getter 且回傳固定字串，則切換語言時不會變更。
    *   **Fix:** 必須在 UI 層使用 `tr('patterns.${pattern.name}')` 動態取得翻譯。

2.  **Context Watch 位置：**
    *   `BigTwoBoardCardArea` 已正確使用 `context.watch<SettingsController>()`，這通常足夠觸發 rebuild。但需確保 `EasyLocalization` 的 `Locale` 變更也能傳遞。

#### **3.2 未翻譯字串清單 (Missing Translations identified)**

*   `"Discard Pile"`
*   `"Last Played"`
*   `"Close"`
*   `"Players: "` (拼接字串中)
*   `"Restart"` (假設存在於結束畫面邏輯中)

#### **3.3 提交訊息 (Commit Message)**

```text
feat: localize game session ui strings

Task: FEAT-LOCALIZATION-005

- Localized 'Last Played', 'Discard Pile', and 'Close' in BigTwoBoardCardArea.
- Refactored matching status text in BigTwoBoardWidget to use parameterized translation.
- Fixed logic to translate card patterns dynamically instead of using static display names.
```
