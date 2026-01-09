## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                          |
|:---|:--------------------------------------------|
| **任務 ID (Task ID)** | `FEAT-POKER-99-UI-002`                      |
| **標題 (Title)** | `IMPLEMENT POKER 99 BOARD UI & LOGIC`       |
| **創建日期 (Date)** | `2026/01/10`                                |
| **目標版本 (Target Version)** | `N/A`                                       |
| **專案名稱 (Project)** | `ok_multipl_poker`                          |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

*   **說明：** 將 `Poker99BoardWidget` 從現有的 Big Two 範本完全轉移至 Poker 99 的遊戲邏輯。
*   **目的：** 提供一個直覺的介面，讓玩家能根據選中的卡片動態選擇 Poker 99 的特殊功能（如 +20/-20、指定、反轉等），並清楚呈現目前分數與出牌順序。

#### **1.2 詳細需求 (Detailed Requirements)**

1.  **控制器與狀態替換**:
    *   將 `FirestoreBigTwoController` 替換為 `FirestorePoker99Controller`。
    *   將所有 `BigTwoState` 引用替換為 `Poker99State`。
    *   Delegate 替換為 `Poker99Delegate`。

2.  **三列佈局修改**:
    *   **第一列 (Opponents)**: 
        *   使用 `_bigTwoManager.otherPlayers` (應重命名或確認在 Poker99Delegate 中可用) 顯示對手。
        *   在對手頭像區域增加一個 Overlay 標籤。如果該對手 ID 等於 `state.nextPlayerId()`，則顯示「下個出牌」文字。
    *   **第二列 (Board Area)**: 
        *   中央顯示 `state.currentScore`，建議使用醒目的字體與樣式。
    *   **第三列 (Player Hand & Actions)**:
        *   實作單選邏輯：玩家點擊手牌時，僅能選中一張（Poker 99 每次出一張）。
        *   **動態按鈕 (Action Buttons)**: 根據選中的牌（`_player.selectedCards`）動態呈現以下按鈕：
            *   **Q (12)**: 顯示 `[+20, -20]`。
            *   **10**: 顯示 `[+10, -10]`。
            *   **K (13)**: 顯示 `[99]` (setTo99)。
            *   **J (11)**: 顯示 `[跳過]` (skip)。
            *   **5**: 顯示 `[指定]` (target)。需處理目標選擇（見改善建議）。
            *   **4**: 顯示 `[反轉]` (reverse)。
            *   **黑桃 A**: 顯示 `[0]` (setToZero)。
            *   **Joker**: 顯示 `[99, 0, 指定, 反轉]`。
            *   **其餘一般牌**: 顯示 `[出牌]` (自動計算數值)。

3.  **程式碼規範**:
    *   遵循 `effective_dart`。
    *   保持現有排版，非必要不刪除註解。
    *   使用 `Provider` 傳遞 `Poker99State`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **修改：** `lib/play_session/poker_99_board_widget.dart`

#### **2.2 重要邏輯細節**

*   `playCards` 調用：當點擊功能按鈕時，構建 `Poker99PlayPayload` 並調用 `_gameController.playCards(payload)`。
*   對於 `5` 或 `Joker` 的「指定」功能：目前若 UI 未實作「選擇目標」流程，預設可先指定 `state.nextPlayerId()` 以外的其他玩家。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  確認點擊手牌中的 Q 會正確出現兩個按鈕。
2.  確認點擊按鈕後，Firestore 上的 `currentScore` 有對應增減。
3.  確認「下個出牌」標籤會隨 `isReverse` 狀態與出牌順序正確移動。

#### **3.2 邏輯檢查與改善建議**

*   **邏輯檢查**：
    *   `Joker` 在 Delegate 中也支援 `skip`， spec 中未列出，可視需求補上。
    *   「指定」功能需要一個目標 ID。如果 UI 層目前沒做彈窗選人，建議在點擊「指定」後，預設抓取 `otherPlayers` 列表中的第一個或特定的存活玩家。
*   **改善建議**：
    *   **目標選擇 UI**：建議在點擊「指定」後，使對手頭像進入「可選中」狀態，或者彈出一個簡單的列表讓玩家選人，否則 AI 難以應對玩家的精確打擊。
    *   **分數預覽**：在點擊 +20 等按鈕前，若總分會超過 99，應將按鈕設為 `disabled` (灰底)。

---

### **Section 4: 產出 Commit Message**

```text
feat(poker_99): refactor board UI for Poker 99 rules and actions

- Replace BigTwo controller and state with Poker99 entities
- Implement dynamic action buttons (+/-20, +/-10, target, etc.) based on selected card
- Add "Next Player" overlay indicator for opponents
- Display current game score in the central area
- Enforce single card selection for Poker 99
- Include Task Specification: FEAT-POKER-99-UI-002
```
