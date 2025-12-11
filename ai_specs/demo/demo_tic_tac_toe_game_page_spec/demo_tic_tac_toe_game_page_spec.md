## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
| :--- |:---| 
| **任務 ID (Task ID)** | `FEAT-DEMO-TIC-TAC-TOE-GAME-PAGE-001` |
| **創建日期 (Date)** | `2025/12/11` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 本文件旨在分析 `lib/demo/tic_tac_toe_game_page.dart` 的現有實作。該檔案透過 `FirestoreTurnBasedGameController` 展示了一個完整的、可運作的井字棋 (Tic-Tac-Toe) 遊戲範例，涵蓋了遊戲狀態定義、遊戲規則實現，以及與 Firebase 即時同步的 UI 介面。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **遊戲狀態定義 (`TicTacToeState`)**:
    1.  **`board`**: 一個 `List<String>`，代表 3x3 的遊戲盤面，每個位置可為 'X', 'O', 或空字串。
    2.  **`winner`**: 一個可為 null 的 `String`，記錄遊戲的贏家。
    3.  **序列化**: 包含 `fromJson` 和 `toJson` 方法，以便與 Firestore 進行資料交換。

*   **遊戲規則實現 (`TicTacToeDelegate`)**:
    1.  繼承自 `TurnBasedGameDelegate<TicTacToeState>`，負責定義井字棋的核心邏輯。
    2.  **`initializeGame`**: 遊戲開始時，建立一個全空的 3x3 盤面。
    3.  **`processAction`**: 處理玩家的下棋動作 (`place_mark`)。它會驗證是否為該玩家的回合，以及下棋位置是否有效，然後更新盤面狀態。
    4.  **`getCurrentPlayer`**: 根據盤面上 'X' 和 'O' 的數量，判斷目前輪到哪一位玩家。
    5.  **`getGameStatus`** 和 **`getWinner`**: 判斷遊戲是否結束並回報贏家。

*   **遊戲 UI 介面 (`TicTacToeGamePage`)**:
    1.  使用 `StatefulWidget` 和 `StreamBuilder` 來建構，UI 會根據 `FirestoreTurnBasedGameController` 提供的 `gameStateStream` 自動更新。
    2.  **遊戲配對**:
        *   提供「配對」按鈕，點擊後呼叫 `_gameController.matchAndJoinRoom` 來尋找或建立一個兩人遊戲房間。
        *   配對成功後，UI 顯示進入房間，並可選擇離開。
    3.  **遊戲進行**:
        *   房主（第一個加入的玩家）可以看到「開始遊戲」按鈕，點擊後呼叫 `_gameController.startGame()`。
        *   遊戲開始後，UI 會顯示輪到誰下棋。
        *   玩家點擊盤面格子時，會呼叫 `_gameController.sendGameAction()` 來發送動作。
    4.  **狀態顯示**: 即時顯示遊戲盤面、目前玩家等資訊。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **分析對象：** `lib/demo/tic_tac_toe_game_page.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **狀態管理:** 遊戲核心狀態由 `FirestoreTurnBasedGameController` 管理，UI 透過 `Stream` 進行反應式更新。
*   **遊戲邏輯:** 透過 `TurnBasedGameDelegate` 模式將遊戲規則與 Firestore 的通訊邏輯分離。
*   **後端服務:** 使用 Firebase Auth 進行使用者驗證，使用 Firestore 作為即時資料庫。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`FirestoreTurnBasedGameController<TicTacToeState>`:**
    *   這是驅動整個遊戲的核心控制器。它需要一個 `delegate` (即 `TicTacToeDelegate`) 來運作。
    *   **主要方法**:
        *   `matchAndJoinRoom()`: 自動配對並加入房間。
        *   `startGame()`: 由房主呼叫以開始遊戲。
        *   `sendGameAction()`: 玩家發送遊戲動作 (如下棋)。
        *   `leaveRoom()`: 離開目前房間。
        *   `gameStateStream`: 提供遊戲狀態的即時串流。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  閱讀並分析 `lib/demo/tic_tac_toe_game_page.dart` 的程式碼。
    2.  將分析結果整理成一份重點說明文件，解釋其架構和運作方式。
2.  **文字輸出：** 產生這份說明文件，即當前這份 `demo_tic_tac_toe_game_page_spec.md`。

#### **3.2 驗證步驟 (Verification Steps)**

*   **文件正確性**: 確認本文件是否準確地描述了 `tic_tac_toe_game_page.dart` 的三個主要部分：`TicTacToeState`（狀態）、`TicTacToeDelegate`（規則）和 `TicTacToeGamePage`（UI）。
*   **流程完整性**: 確認文件是否涵蓋了從「配對」到「開始遊戲」，再到「玩家互動」的完整流程。
*   **可讀性**: 確認文件內容清晰易懂，有助於理解該範例的運作原理。
