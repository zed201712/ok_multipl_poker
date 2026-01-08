## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                       |
|:---|:-----------------------------------------|
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-UI-016`                    |
| **標題 (Title)** | `MATCHING FLOW REFACTOR & CELEBRATION`   |
| **創建日期 (Date)** | `2026/01/08`                             |
| **目標版本 (Target Version)** | `N/A`                                    |
| **專案名稱 (Project)** | `ok_multipl_poker`                       |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 重構 `BigTwoBoardWidget` 的配對與遊戲前狀態顯示邏輯，並加入遊戲獲勝時的慶祝效果 (Confetti & Sound)。
*   **目的：**
    1.  **程式碼清晰度 (Clarity)：** 將原本混雜在 `build` 方法中的配對狀態判斷邏輯拆分為獨立的方法與明確的狀態機 (`_LocalMatchStatus`)。
    2.  **使用者體驗 (UX)：** 增加配對等待時的明確狀態，以及遊戲獲勝時的視覺與聽覺回饋。
    3.  **狀態管理 (State Management)：** 修正遊戲狀態與 UI 顯示狀態的同步機制。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **重構配對 UI 邏輯 (`BigTwoBoardWidget`)**
    *   引入 `_LocalMatchStatus` Enum (`idle`, `waiting`, `inRoom`)。
    *   根據 `_localMatchStatus` 顯示對應的 UI 子組件：
        *   `_buildMatchStatusIdleUI`: 顯示 "Ready" 與 "Match Room" 按鈕。
        *   `_buildMatchStatusWaitingUI`: 顯示 "Matching..." 與 Loading Indicator。
        *   `_buildRoomMatchingUI`: 顯示房間人數、"Start" 按鈕與 "Leave" 按鈕。

2.  **新增獲勝慶祝效果**
    *   引入 `Confetti` Widget (需確保專案中有此組件或類似實作)。
    *   在遊戲結束 (`GameStatus.finished`) 時：
        *   播放音效 (`SfxType.congrats`)。
        *   顯示 Confetti 動畫，持續約 2 秒。
    *   UI 層使用 `Stack` 包裹 Board 與 Confetti Overlay。

3.  **狀態同步修正**
    *   監聽 `_gameController.gameStateStream`。
    *   根據 `gameState` 更新 `_localMatchStatus`，確保應用程式重啟或重新連線時能正確恢復 UI 狀態。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **Board Widget:** `lib/play_session/big_two_board_widget.dart`

#### **2.2 程式碼風格 (Style)**

*   **UI 分割：** 保持 `build` 方法簡潔，將不同狀態的 UI 抽取為獨立 Widget 方法。
*   **狀態命名：** `_LocalMatchStatus` 僅用於 UI 顯示控制，區別於 `GameStatus`。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **配對流程：** 點擊 "Match Room" -> UI 變為 Waiting -> 進入 Room 後變為 Room UI (Start Button)。
2.  **慶祝效果：** 模擬遊戲結束 (或實際遊玩至結束)，確認音效播放且 Confetti 出現並在 2 秒後消失。
3.  **狀態恢復：** 在 "In Room" 狀態下 Hot Restart，確認 UI 仍顯示 Room UI 而非退回 Idle。

---

### **Section 4: Commit 程式碼分析與審查 (Analysis & Review)**

#### **4.1 Commit: ff9a58dc4ba7b36c4de89768c67d20689107ea68**
*   **Author:** okawa <a@a.a>
*   **Date:** Thu Jan 8 12:46:56 2026 +0900
*   **Message:** `feat: _buildMatchStatusWaitingUI`

#### **4.2 變更摘要**
*   **Refactoring:** 引入 `_LocalMatchStatus` 並重構了 `build` 方法，將 UI 拆解為 `_buildMatchStatusIdleUI`, `_buildMatchStatusWaitingUI`, `_buildRoomMatchingUI`。
*   **Feature:** 新增 `_playerWon` 方法處理獲勝邏輯，包含音效與 `Confetti` 動畫控制。
*   **Layout:** 使用 `Stack` 包裹主介面以支援 Overlay。

#### **4.3 審查結論**
*   **邏輯正確性 (Logic):**
    *   **潛在問題 (Potential Issue):** 在 `initState` 的 Stream Listener 中，狀態同步邏輯可能不完整。如果 App 重啟或重新進入頁面時，已在房間內 (`bigTwoState != null` 且 `gameStatus == matching`)，目前的邏輯：
        ```dart
        if (mounted && _localMatchStatus == _LocalMatchStatus.waiting) { ... }
        else if (_isGameReadyState(gameState)) { ... }
        ```
        會因為 `_localMatchStatus` 預設為 `idle` 且 `_isGameReadyState` 為 false (matching) 而導致無法正確切換到 `inRoom` 狀態，使用者會看到 Idle UI (Match Room 按鈕) 但實際已在房間中。
*   **改善建議 (Improvements):**
    *   修正 Stream Listener 邏輯，當檢測到 `bigTwoState != null` 且 `gameStatus == matching` 時，若當前狀態為 `idle`，應自動切換為 `inRoom`。
    *   建議增加 `_checkCurrentState` 方法在 `initState` 初次執行時同步狀態。

---

### **Section 5: 產出 Commit Message**

```text
feat(ui): refactor matching flow and add victory celebration

- UI: Refactored `BigTwoBoardWidget` to use `_LocalMatchStatus` for clearer matching states (Idle, Waiting, InRoom).
- UI: Added `Confetti` and sound effects for game victory.
- UI: Extracted sub-widgets (`_buildMatchStatusIdleUI`, etc.) for better readability.
- Fix: Resolved layout structure by wrapping board in `Stack` for overlays.
```
