## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                          |
|:---|:--------------------------------------------|
| **任務 ID (Task ID)** | `FEAT-POKER-99-CONTROLLER-003`              |
| **標題 (Title)** | `REFACTOR POKER 99 AI AND IMPLEMENT BATTLE MODE` |
| **創建日期 (Date)** | `2026/01/10`                                |
| **目標版本 (Target Version)** | `N/A`                                       |
| **專案名稱 (Project)** | `ok_multipl_poker`                          |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

*   **說明：** 重構 `Poker99AI` 使其脫離對 `FirebaseFirestore` 的直接依賴，並在 `FirestorePoker99Controller` 中實作 `battleAgainstBots` 模式。
*   **目的：** 提升架構的可維護性，將 AI 簡化為純邏輯元件，並由控制器統一管理遊戲流程與通訊。

#### **1.2 詳細需求 (Detailed Requirements)**

1.  **重構 `Poker99AI`**:
    *   **移除依賴**：刪除 `FirebaseFirestore`、`FirebaseAuth` 與 `FirestoreTurnBasedGameController` 的引用。
    *   **介面調整**：
        *   建構子改為接收 `String aiUserId` 與 `Poker99Delegate delegate`。
        *   新增 `updateState(TurnBasedGameState<Poker99State>? gameState)` 方法，供外部注入遊戲狀態。
        *   新增一個回呼函數 `void Function(String action, Map<String, dynamic>? payload) onAction`，用於傳出 AI 決定採取的行動。
    *   **功能調整**：
        *   移除 `_init`、`_onRoomsSnapshot`、`_matchRoom` 等與房間配對相關的邏輯。這些職責將移交給控制器。
        *   `_onGameStateUpdate` 邏輯改由 `updateState` 觸發。
        *   `_gameController.sendGameAction` 改為呼叫 `onAction`。

2.  **增強 `FirestorePoker99Controller`**:
    *   **管理 AI 狀態**：
        *   在 `_initTestModeAIs` 中，除了建立 `Poker99AI`，需保留與之對應的 `MockFirebaseAuth` 或其封裝的 `FirestoreTurnBasedGameController`，以便替該 AI 發送 Firestore 指令。
    *   **橋接 AI 與遊戲流**：
        *   監聽內部的 `_gameController.gameStateStream`。
        *   當狀態更新時，遍歷 `_testModeAIs` 並呼叫其 `updateState`。
        *   實作 AI 的 `onAction` 回呼：當 AI 觸發動作時，由控制器使用對應身份的 `_gameController` 向 Firestore 發送指令。
    *   **實作 `battleAgainstBots`**:
        *   新增 `Future<void> battleAgainstBots()`。
        *   邏輯：自動執行房間配對，並在測試模式下確保 AI 參與。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **修改：** `lib/multiplayer/poker_99_ai/poker_99_ai.dart`
*   **修改：** `lib/multiplayer/firestore_poker_99_controller.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `effective_dart` 程式碼風格。
*   狀態管理使用 `Provider`。
*   保持非必要不調整排版、不刪除註解。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  確認 `Poker99AI` 檔案中不再出現與 Firestore 直接連線的操作。
2.  確認在 UI 調用 `battleAgainstBots` 後，AI 能正常被初始化並在輪到它們時出牌。
3.  確認 AI 的出牌邏輯（優先權、10/Q/5 的判斷）在重構後依然保持正確。

#### **3.2 邏輯檢查與改善建議**

*   **邏輯檢查**：
    *   需確保 AI 行動的延遲（模擬思考）在重構後依然有效，避免瞬間完成所有回合導致 UI 或邏輯異常。
*   **改善建議**：
    *   `FirestorePoker99Controller` 可以封裝一個 `BotContext` 類別，持有 AI 實例、Mock Auth 以及對應的 GameController，方便管理。

---

### **Section 4: 產出 Commit Message**

```text
refactor(poker_99): decouple AI from Firestore and add battleAgainstBots mode

- Remove direct Firestore/Auth dependencies from Poker99AI
- Implement state injection and action callback in Poker99AI
- Update FirestorePoker99Controller to manage AI instances and bridge actions
- Add battleAgainstBots method to facilitate bot-only or mixed matches
- Include Task Specification: FEAT-POKER-99-CONTROLLER-003
```
