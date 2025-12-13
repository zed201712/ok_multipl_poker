## AI 專案任務指示文件 (Analysis Task)

| 區塊 | 內容                                    |
| :--- |:--------------------------------------|
| **任務 ID (Task ID)** | `FEAT-DEMO-TIC-TAC-TOE-GAME-PAGE-001` |
| **創建日期 (Date)** | `2025/12/13`                          |
| **目標版本 (Target Version)** | `N/A`                                 |
| **專案名稱 (Project)** | `ok_multipl_poker`                    |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 分析 `lib/demo/tic_tac_toe_game_page.dart` 檔案的內部結構與邏輯，並以清晰、易於理解的文字整理其核心功能，作為後續開發或重構的參考文件。

#### **1.2 功能分析 (Functional Analysis)** **【必填】**

`tic_tac_toe_game_page.dart` 實現了一個完整的多人井字棋遊戲，其結構可分為三個主要部分：

*   **1. `TicTacToeState` (遊戲狀態定義):**
    *   這是一個純粹的資料物件，用來儲存一局井字棋在任何特定時間點的所有狀態。
    *   `board`: 一個長度為 9 的字串列表，代表 3x3 的棋盤，每個位置可以是 'X'、'O' 或空字串 ''。
    *   `winner`: 儲存遊戲贏家。可能是 'X'、'O'，或是在平手時為 'DRAW'。遊戲進行中則為 `null`。
    *   `restartRequesters`: 一個列表，記錄了所有已點擊「重新開始」按鈕的玩家 ID。
    *   `playerIds`: 儲存參與此局遊戲的兩位玩家的 ID。

*   **2. `TicTacToeDelegate` (遊戲規則實現):**
    *   這個類別是遊戲的核心邏輯，它定義了井字棋的規則，並告訴通用的 `FirestoreTurnBasedGameController` 如何操作 `TicTacToeState`。
    *   `initializeGame`: 當遊戲開始或重置時被呼叫，功能是建立一個全新的、空的棋盤狀態。
    *   `processAction`: 處理玩家的每一個動作。它是一個純函數，接收當前狀態和一個動作，然後回傳一個新的狀態。
        *   若 `actionName` 是 `place_mark`：它會檢查玩家身份、位置是否可下，然後更新棋盤並呼叫 `_checkWinner` 檢查遊戲是否結束。
        *   （在舊版本中）`request_restart` 的邏輯也在此處理，但此部分在新架構下已被移至 `getAtomicUpdateForAction`。
    *   `getAtomicUpdateForAction`: 為 `request_restart` action 提供原子性更新 `restartRequesters` 欄位的操作，以解決 race condition。
    *   `getCurrentPlayer`: 根據棋盤上 'X' 和 'O' 的數量，判斷現在輪到哪一位玩家。
    *   `getWinner`: 從遊戲狀態中回傳贏家資訊。

*   **3. `TicTacToeGamePage` (UI 介面與互動):**
    *   這是一個 StatefulWidget，負責將遊戲狀態渲染到螢幕上，並處理使用者的輸入。
    *   **狀態監聽**: 使用 `StreamBuilder` 監聽 `_gameController.gameStateStream`，並根據 `GameStatus` (如 `matching`, `playing`, `finished`) 來顯示不同的 UI。
    *   **遊戲流程 UI**:
        *   **初始/配對中**: 顯示「歡迎」訊息和「配對」按鈕。點擊後，呼叫 `_gameController.matchAndJoinRoom` 並顯示「等待玩家」的訊息。
        *   **遊戲中 (`GameStatus.playing`)**: 顯示 3x3 的棋盤，並在頂部提示輪到哪位玩家。棋盤僅在輪到當前使用者時才可點擊。點擊棋盤格子會呼叫 `_gameController.sendGameAction('place_mark', ...)`。
        *   **遊戲結束 (`GameStatus.finished`)**: 顯示贏家或平手的訊息，並顯示一個「重新開始」的區塊，讓玩家可以請求開啟新的一局。
    *   **控制器**: 在 `initState` 中，它會初始化 `FirestoreTurnBasedGameController`，並將 `TicTacToeDelegate` 傳入，將遊戲邏輯與 Firebase 後端連接起來。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 分析的檔案 (File Under Analysis)** **【必填】**

*   `lib/demo/tic_tac_toe_game_page.dart`

#### **2.2 技術棧 (Stack)**

*   **UI**: Flutter
*   **狀態管理**: `StreamBuilder` 搭配 `BehaviorSubject` (來自 `rxdart`，在 Controller 內部)。
*   **後端與遊戲邏輯**: `FirestoreTurnBasedGameController`，它封裝了與 `cloud_firestore` 的互動邏輯。


---

### **Section 3: 輸出 (Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  本任務為分析任務，不涉及程式碼修改。主要步驟是閱讀和理解目標檔案。
2.  **分析輸出：** 輸出應為此 spec 文件本身，其中已包含對目標檔案的文字分析與描述。
