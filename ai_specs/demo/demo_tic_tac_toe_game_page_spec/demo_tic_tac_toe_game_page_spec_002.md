## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
| :--- |:---| 
| **任務 ID (Task ID)** | `FEAT-DEMO-TIC-TAC-TOE-GAME-PAGE-002` |
| **創建日期 (Date)** | `2025/12/11` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 修正並完成 `lib/demo/tic_tac_toe_game_page.dart` 範例，使其成為一個功能完整的井字棋遊戲。這包括實作完整的 3x3 遊戲 UI，以及加入勝利條件的判斷邏輯。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **遊戲 UI 介面 (`TicTacToeGamePage`)**: 
    1.  將目前只顯示單一格子的 UI，改為使用 `GridView.builder` 渲染一個 3x3 的九宮格遊戲盤面。
    2.  每個格子都應為一個可點擊的 `GestureDetector` 或 `InkWell`。
    3.  點擊格子時，應呼叫 `_gameController.sendGameAction('place_mark', payload: {'index': i})`，並傳入正確的格子索引 `i`。
    4.  UI 應能正確顯示遊戲結束時的贏家或平手狀態。
    5.  當遊戲不在 `playing` 狀態時 (例如等待配對、遊戲結束)，遊戲盤面應呈現鎖定或不可點擊的狀態。

*   **遊戲規則實現 (`TicTacToeDelegate`)**:
    1.  **實作 `_checkWinner` 方法**: 
        *   加入完整的勝利判斷邏輯，檢查所有橫排、豎排及對角線。
        *   如果有名稱（'X' 或 'O'）連成一線，則回傳該名稱。
        *   如果棋盤已滿但無人獲勝，應回傳 `'DRAW'`，表示平手。
        *   如果遊戲尚未結束，則回傳 `null`。
    2.  **更新 `processAction` 方法**: 
        *   在放置棋子 (`place_mark`) 後，呼叫 `_checkWinner` 來更新 `TicTacToeState` 的 `winner` 欄位。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/demo/tic_tac_toe_game_page.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **UI 實作**: 使用 Flutter 內建的 `GridView` 來建立盤面，並保持與現有程式碼一致的風格。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  分析 `lib/demo/tic_tac_toe_game_page.dart` 的現有程式碼。
    2.  在 `TicTacToeDelegate` 中實作 `_checkWinner` 的邏輯。
    3.  修改 `TicTacToeGamePage` 的 `build` 方法，以 `GridView` 建立九宮格 UI。
    4.  輸出完整的 `tic_tac_toe_game_page.dart` 檔案內容。
2.  **程式碼輸出：** 產出修改後的 `lib/demo/tic_tac_toe_game_page.dart` 的完整程式碼。

#### **3.2 驗證步驟 (Verification Steps)**

*   **UI 驗證**: 確認 App 畫面上顯示的是一個 3x3 的九宮格。
*   **互動驗證**: 輪流點擊格子，確認 'X' 和 'O' 能被正確放置。
*   **勝利條件驗證**: 
    *   當任一方連成一線時，確認遊戲結束並顯示正確的贏家。
    *   當輪到非當前玩家點擊時，棋盤狀態不應改變。
*   **平手驗證**: 當棋盤下滿且無人獲勝時，確認遊戲顯示為平手狀態。
