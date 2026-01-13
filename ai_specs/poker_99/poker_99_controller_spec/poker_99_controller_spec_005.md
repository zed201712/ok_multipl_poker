## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                          |
|:---|:--------------------------------------------|
| **任務 ID (Task ID)** | `FEAT-POKER-99-CONTROLLER-005`              |
| **標題 (Title)** | `GENERIC BOT CONTEXT AND DECOUPLING POKER 99 STATE` |
| **創建日期 (Date)** | `2026/01/13`                                |
| **目標版本 (Target Version)** | `N/A`                                       |
| **專案名稱 (Project)** | `ok_multipl_poker`                          |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

*   **說明：** 重構 `_BotContext` 為泛型 `_BotContext<T>`，解耦對特定遊戲狀態（如 `Poker99State`）與 AI（`Poker99AI`）的直接依賴。
*   **目的：** 提升架構靈活性，使底層機器人管理邏輯可複用於不同類型的回合制遊戲，並將特定遊戲的初始化邏輯集中於控制器。

#### **1.2 詳細需求 (Detailed Requirements)**

1.  **修改 `TurnBasedGameState` 與 `T` 的類型約束**:
    *   在 `lib/multiplayer/turn_based_game_state.dart` 中，定義 `TurnBasedCustomState` 介面，要求實作者必須提供 `currentPlayerId` 與 `winner`。
    *   將 `TurnBasedGameState<T>` 的 `T` 限制為 `T extends TurnBasedCustomState`。
    *   使 `_BotContext` 在 `_updateState` 後，能透過介面從 `customState` 複製 `currentPlayerId` 與 `winner` 到 `_turnBasedGameState`。

2.  **重構 `_BotContext<T>`**:
    *   將 `_BotContext` 修改為 `_BotContext<T extends TurnBasedCustomState>`。
    *   將 `_delegate` 型別改為 `TurnBasedGameDelegate<T>`。
    *   引入 `TurnBasedAI<T>` 介面，並將 `_bots` 型別改為 `List<TurnBasedAI<T>>`。
    *   移除 `_BotContext` 建構子中寫死的 `Poker99AI` 實例化邏輯。

3.  **解耦與遷移邏輯**:
    *   將 `Poker99State` 實作 `TurnBasedCustomState` 介面。
    *   將 `Poker99AI` 實作 `TurnBasedAI<Poker99State>` 介面。
    *   將原本在 `_BotContext` 內部的 AI 建立邏輯移至 `FirestorePoker99Controller`。
    *   `_BotContext` 建構子改為接收已建立好的 `bots` 列表。

4.  **參數化配置**:
    *   調整 `_BotContext.createRoom` 的輸入參數，使其接受 `maxPlayers`。
    *   由 `FirestorePoker99Controller` 調用時傳入固定值 `6`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **修改：** `lib/multiplayer/turn_based_game_state.dart` (定義介面與泛型約束)
*   **修改：** `lib/entities/poker_99_state.dart` (實作介面)
*   **修改：** `lib/multiplayer/poker_99_ai/poker_99_ai.dart` (實作新 AI 介面)
*   **修改：** `lib/multiplayer/firestore_poker_99_controller.dart` (全面重構 `_BotContext` 與控制器初始化邏輯)

#### **2.2 程式碼風格 (Style)**

*   遵循 `effective_dart` 程式碼風格。
*   狀態管理使用 `Provider`。
*   保持非必要不調整排版、不刪除註解。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  確認 `_BotContext` 類別定義中不再出現 `Poker99State` 或 `Poker99AI` 字樣。
2.  確認 `FirestorePoker99Controller` 能夠成功編譯並正確實例化 `_BotContext<Poker99State>`。
3.  進入 Poker 99 遊戲並開啟 Bot 模式，驗證遊戲流程（發牌、Bot 出牌、勝利判定、重開請求）是否與重構前一致。

#### **3.2 邏輯檢查與改善建議**

*   **邏輯檢查**：
    *   需確保 `TurnBasedGameState` 的 `copyWith` 與 `fromJson` 邏輯在引入泛型約束後依然運作正常。
    *   檢查 `_BotContext` 的 `_updateState` 中對 `winner` 的判斷是否依然能正確停止 `StreamSubscription`。
*   **改善建議**：
    *   建議將 `TurnBasedAI` 介面定義在 `lib/multiplayer/turn_based_ai.dart`，以達成更徹底的解耦。

---

### **Section 4: 產出 Commit Message**

```text
refactor(poker_99): generalize _BotContext and decouple Poker99 specific logic

- Define TurnBasedCustomState interface for game state generic constraints
- Refactor _BotContext to use generic T and TurnBasedAI interface
- Move AI instantiation logic to FirestorePoker99Controller
- Update createRoom to accept maxPlayers as a parameter
- Ensure compatibility with TurnBasedGameState and existing Poker 99 logic
- Include Task Specification: FEAT-POKER-99-CONTROLLER-005
```
