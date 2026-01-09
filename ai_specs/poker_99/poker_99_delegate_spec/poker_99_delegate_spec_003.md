## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                          |
|:---|:--------------------------------------------|
| **任務 ID (Task ID)** | `FEAT-POKER-99-DELEGATE-003`                |
| **標題 (Title)** | `REDEFINE WIN CONDITIONS AND ELIMINATION LOGIC` |
| **創建日期 (Date)** | `2026/01/09`                                |
| **目標版本 (Target Version)** | `N/A`                                       |
| **專案名稱 (Project)** | `ok_multipl_poker`                          |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

*   **說明：** 重構 `Poker99Delegate` 的勝負判定邏輯（`_checkEliminationAndWinner`）與分數邊界處理，並調整抽牌與跳過邏輯。
*   **目的：** 實作 Poker 99 的「單一輸家」規則，當玩家無法合法出牌時即判定為輸家，其餘玩家獲勝。同時處理牌堆耗盡與手牌耗盡的場景。

#### **1.2 詳細需求 (Detailed Requirements)**

1.  **分數邊界修正**:
    *   修改 `_playCards`：若計算出的 `newScore` 低於 0，則強制設為 0。
2.  **牌堆與跳過邏輯調整**:
    *   **取消重洗**: 移除 `_playCards` 中牌堆耗盡時將棄牌堆回洗的邏輯。若 `deckCards` 為空，則不再抽牌。
    *   **自動跳過**: 若輪到某玩家時其手牌為空，則直接跳過該玩家，不需出牌。
3.  **重寫勝負判定 (`_checkEliminationAndWinner`)**:
    *   **全體獲勝場景**: 當所有玩家的手牌皆已出完（`cards.isEmpty`），則所有人獲勝。將 `state.winner` 設定為所有玩家名稱的字串（以逗號或其他適當方式連接）。
    *   **輸家產生場景**: 若當前玩家仍有手牌，但 `getPlayableCards` 結果為空（即出任何牌都會超過 99），則該玩家為輸家。將 `state.winner` 設定為所有**其他**玩家的名稱字串。
4.  **單元測試更新**:
    *   在 `test/game_internals/poker_99_delegate_test.dart` 中新增以下測試：
        *   分數扣至負數時自動轉為 0。
        *   牌堆空了之後不再補牌。
        *   手牌空的玩家被跳過。
        *   所有玩家手牌空時，判定為全體贏家。
        *   無法出牌時，判定該玩家為輸家並結束遊戲。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **修改：** `lib/game_internals/poker_99_delegate.dart`
*   **修改：** `test/game_internals/poker_99_delegate_test.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `effective_dart` 程式碼風格。
*   **不要製造多餘的 git diff**，非必要不要刪除註解，不要調整文字排版。
*   檢查有無邏輯錯誤（例如：進入死循環、未處理所有玩家都沒牌的情況等）。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  執行 `flutter test test/game_internals/poker_99_delegate_test.dart` 確保所有新舊測試皆通過。
2.  手動檢查 `_checkEliminationAndWinner` 是否能正確處理「下一個玩家手牌為空」的遞迴跳過邏輯。

---

### **Section 4: 產出 Commit Message**

```text
feat: redefine Poker 99 win conditions and elimination logic

- Reset score to 0 if it drops below zero
- Disable deck reshuffling and skip players with empty hands
- Implement winner calculation: everyone wins if all hands are empty; otherwise, all except the one who can't play win
- Update tests for new elimination and win rules
- Include Task Specification: FEAT-POKER-99-DELEGATE-003
```
