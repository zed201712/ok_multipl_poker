## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                          |
|:---|:--------------------------------------------|
| **任務 ID (Task ID)** | `FEAT-FIRESTORE-BIG-TWO-CONTROLLER-003`     |
| **標題 (Title)** | `REFACTOR BIG TWO AI AND INTRODUCE STRATEGY PATTERN` |
| **創建日期 (Date)** | `2026/01/13`                                |
| **目標版本 (Target Version)** | `N/A`                                       |
| **專案名稱 (Project)** | `ok_multipl_poker`                          |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

*   **說明：** 參考 `FirestorePoker99Controller` 的架構，重構 `FirestoreBigTwoController` 與 `BigTwoPlayCardsAI`。
*   **目的：** 
    *   將 AI 與 `FirebaseFirestore` 解耦，使其成為純邏輯組件。
    *   引入 `BotContext<BigTwoState>` 統一管理機器人行為。
    *   實作 `GamePlayStrategy` 模式，解耦「線上多人」與「單機 Bot」模式的流程控制。

#### **1.2 詳細需求 (Detailed Requirements)**

1.  **重構 `BigTwoPlayCardsAI` (及 `BigTwoAI`)**:
    *   **移除依賴**：刪除 `FirebaseFirestore`、`FirebaseAuth` 與 `FirestoreTurnBasedGameController` 的引用。
    *   **介面調整**：
        *   建構子改為接收 `String aiUserId`、`BigTwoDelegate delegate` 以及 `void Function(BigTwoState state) onAction`。
        *   實作 `updateState(TurnBasedGameState<BigTwoState> gameState, RoomState roomState)`，由外部注入狀態。
    *   **邏輯調整**：
        *   `_onGameStateUpdate` 邏輯改由 `updateState` 觸發。
        *   原本透過 `_gameController.sendGameAction` 發出的動作，改為使用 `delegate.processAction` 計算出新狀態後，透過 `onAction` 回傳。
        *   保留 AI 的思考延遲（`Future.delayed`）。

2.  **重構 `FirestoreBigTwoController`**:
    *   **引入 `BotContext<BigTwoState>`**：
        *   在控制器中初始化 `BotContext`，管理機器人資訊、Delegate 與 AI 實例。
        *   實作 `onBotsAction` 回呼，當輪到機器人時呼叫其 `updateState`。
    *   **引入 `GamePlayStrategy` 模式**：
        *   實作 `OnlineMultiplayerStrategy<BigTwoState>` 與 `BotGameStrategy<BigTwoState>`。
        *   在 `startGame()` 時，若玩家人數 ≤ 1，自動切換至 `BotGameStrategy`。
        *   將 `matchRoom`、`startGame`、`restart`、`leaveRoom`、`endRoom` 等流程委派給策略物件。
    *   **清理舊代碼**：移除 `_testModeAIs` 相關的舊初始化邏輯與對 `MockFirebaseAuth` 的依賴。

3.  **遵循介面規範**:
    *   確保 `BigTwoState` 實作 `TurnBasedCustomState`。
    *   確保 `BigTwoPlayCardsAI` 的行為與重構前的邏輯一致（包含出牌優先權、Pass 判定等）。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **修改：** `lib/multiplayer/firestore_big_two_controller.dart`
*   **修改：** `lib/multiplayer/big_two_ai/big_two_ai.dart`
*   **修改：** `lib/multiplayer/big_two_ai/big_two_play_cards_ai.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `effective_dart` 程式碼風格。
*   狀態管理使用 `Provider`。
*   保持非必要不調整排版、不刪除註解。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  確認 `BigTwoPlayCardsAI` 中不再包含任何 Firestore 引用。
2.  驗證在只有一名玩家點擊「開始遊戲」時，能正確啟動 Bot 模式並進入遊戲。
3.  驗證機器人在單機模式下能正常出牌、Pass，並在遊戲結束後自動發送重開請求。
4.  確認線上多人模式（超過 1 人開始）依然運作正常，且不會觸發本地 Bot 邏輯。

#### **3.2 邏輯檢查與改善建議**

*   **邏輯檢查**：
    *   Big Two 的 `isFirstTurn` 判定（包含梅花 3 必須出牌）需在 AI 邏輯中維持正確。
    *   確認 `BotContext` 更新狀態時，能正確觸發 `FirestoreBigTwoController` 的 `gameStateStream` 更新。
*   **改善建議**：
    *   由於 `BigTwoAI` 目前在 `big_two_ai.dart` 中是一個具象類別但在 `big_two_play_cards_ai.dart` 中被當作介面或父類別使用，建議統一將其定義為抽象介面或直接併入 `BigTwoPlayCardsAI`（若無其他實作）。

---

### **Section 4: 產出 Commit Message**

```text
refactor(big_two): decouple AI from Firestore and introduce BotContext with Strategy pattern

- Remove Firestore/Auth dependencies from BigTwoAI and BigTwoPlayCardsAI
- Implement BotContext<BigTwoState> for local bot management
- Introduce GamePlayStrategy to handle Online vs Bot game flows
- Update FirestoreBigTwoController to delegate flow control to strategies
- Maintain existing Big Two AI logic and ensure single-player auto-bot mode
- Include Task Specification: FEAT-FIRESTORE-BIG-TWO-CONTROLLER-003
```
