## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                          |
|:---|:--------------------------------------------|
| **任務 ID (Task ID)** | `FEAT-POKER-99-CONTROLLER-006`              |
| **標題 (Title)** | `GENERIC BOT CONTEXT REFACTORING AND DECOUPLING` |
| **創建日期 (Date)** | `2026/01/13`                                |
| **目標版本 (Target Version)** | `N/A`                                       |
| **專案名稱 (Project)** | `ok_multipl_poker`                          |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

*   **說明：** 接續 `poker_99_controller_spec_005.md` 未完成的部分，全面重構 `_BotContext` 為泛型 `_BotContext<T>`，徹底解耦對 `Poker99AI` 與 `Poker99Delegate` 的依賴。
*   **目的：** 使 `_BotContext` 成為通用的機器人運行環境，由外部控制器注入特定遊戲的機器人實例與邏輯。

#### **1.2 詳細需求 (Detailed Requirements)**

1.  **重構 `_BotContext<T extends TurnBasedCustomState>`**:
    *   將 `_BotContext` 定義為泛型類別。
    *   **移除依賴**：刪除 `_bots` 列表（`List<Poker99AI>`）與 `Poker99Delegate`。
    *   **新增成員變數**：
        *   `final List<ParticipantInfo> botsInfo;`：存儲機器人的參與資訊。
        *   `final TurnBasedGameDelegate<T> _delegate;`：通用的遊戲代理。
        *   `final void Function(TurnBasedGameState<T> gameState, RoomState roomState) onBotsAction;`：當狀態更新時，通知外部執行機器人動作的回呼函數。
    *   **修改建構子**：
        *   接收上述新增變數。
        *   不再在內部實例化 `Poker99AI`。
        *   接收 `initialCustomState` 用於初始化 `_turnBasedGameState`。

2.  **調整 `_BotContext` 內部邏輯**:
    *   **`createRoom()`**: 
        *   使用 `botsInfo` 生成參與者列表。
        *   `maxPlayers` 設定為 `botsInfo.length + 1` (機器人數量 + 使用者 1 人)。
    *   **`_botsAction()` (或重新命名為 `_notifyBots`)**:
        *   不再遍歷內部 `_bots`。
        *   直接呼叫 `onBotsAction(_turnBasedGameState, _roomState)`。
    *   **`_updateState()`**:
        *   移除特定於 `Poker99State` 的邏輯（例如手動修改 `restartRequesters`）。
        *   僅負責更新 `_turnBasedGameState` 的基本欄位（`customState`, `currentPlayerId`, `winner`, `gameStatus`）。
        *   當 `winner != null` 時，依然負責取消 `_streamSubscription`。

3.  **重構 `FirestorePoker99Controller`**:
    *   **持有機器人實例**：在控制器中維護 `final List<Poker99AI> _bots = [];`。
    *   **初始化 `_BotContext<Poker99State>`**:
        *   在控制器建構子中建立 `ParticipantInfo` 列表並實例化 `Poker99AI`。
        *   傳入 `onBotsAction` 實作：遍歷 `_bots` 並呼叫其 `updateState`（僅當輪到該機器人或遊戲結束時）。
    *   **解耦 AI 與 State**：確保 `Poker99AI` 透過介面或回呼與控制器溝通，不直接依賴 `_BotContext`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **修改：** `lib/multiplayer/firestore_poker_99_controller.dart` (重構 `_BotContext` 類別與控制器初始化邏輯)

#### **2.2 程式碼風格 (Style)**

*   遵循 `effective_dart` 程式碼風格。
*   狀態管理使用 `Provider`。
*   保持非必要不調整排版、不刪除註解。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  確認 `_BotContext` 檔案定義中完全不包含 `Poker99` 關鍵字（除了作為範例泛型參數傳入處）。
2.  確認 `createRoom` 生成的房間人數正確對應機器人數量。
3.  驗證在單機機器人模式下，機器人依然能正常接收狀態更新並執行出牌/重開請求。

#### **3.2 邏輯檢查與改善建議**

*   **邏輯檢查**：
    *   `_BotContext` 移除手動修改 `restartRequesters` 後，需確保 `Poker99AI` 內部的 `_onGameStateUpdate` 邏輯能正確補足此功能（已在 `poker_99_ai.dart` 中實作）。
    *   檢查 `onBotsAction` 是否在所有需要的狀態變更點（包括初始啟動與每次 Action 後）都被正確觸發。
*   **改善建議**：
    *   將 `_BotContext` 移出 `firestore_poker_99_controller.dart` 成為獨立檔案 `lib/multiplayer/bot_context.dart`，以實現更好的模組化。 (本次任務暫不移動，維持在原檔案修改)

---

### **Section 4: 產出 Commit Message**

```text
refactor(poker_99): make _BotContext generic and decouple from specific AI logic

- Refactor _BotContext to _BotContext<T> using TurnBasedCustomState
- Replace direct Poker99AI dependency with onBotsAction callback
- Update createRoom to use botsInfo and dynamic maxPlayers
- Move bot instantiation and management to FirestorePoker99Controller
- Remove Poker99-specific state patching from _BotContext
- Include Task Specification: FEAT-POKER-99-CONTROLLER-006
```
