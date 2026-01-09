## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                          |
|:---|:--------------------------------------------|
| **任務 ID (Task ID)** | `FEAT-POKER-99-CONTROLLER-002`              |
| **標題 (Title)** | `IMPLEMENT POKER 99 AI PLAYING LOGIC`       |
| **創建日期 (Date)** | `2026/01/09`                                |
| **目標版本 (Target Version)** | `N/A`                                       |
| **專案名稱 (Project)** | `ok_multipl_poker`                          |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

*   **說明：** 修改 `Poker99AI` 以實現具體的出牌邏輯，並將其整合至 `FirestorePoker99Controller` 的測試模式中。
*   **目的：** 讓 AI 不再只是發送 `pass_turn`，而是能根據遊戲規則與手牌狀況進行有效的決策。

#### **1.2 詳細需求 (Detailed Requirements)**

1.  **實作 `_performTurnAction` 邏輯**:
    *   從 `Poker99State` 中獲取 AI 玩家（`_aiUserId`）的手牌。
    *   使用 `_delegate.getPlayableCards` 過濾出合法可出的牌。
    *   **選牌策略**:
        *   優先權：`Joker` > `Value 13 (K)` > `Value 12 (Q)` > ... > `Value 1 (A)`。
        *   從可出的牌中挑選優先權最高的一張。
    *   **行動策略 (Poker99Action)**:
        *   **Joker / King (13)**: 選擇 `setTo99`。
        *   **Queen (12) / Ten (10)**: 
            *   若 `currentScore + 20/10 <= 99`，選擇 `increase`。
            *   否則選擇 `decrease`。
        *   **Five (5)**: 選擇 `target`。
            *   計算 `targetPlayerId`: 根據 `state.isReverse` 找到「上一個玩家」。
            *   若 `!isReverse`，目標為 `(myIndex - 1)` 的玩家；若 `isReverse`，目標為 `(myIndex + 1)` 的玩家（需處理循環邊界）。
        *   **其餘牌**: 選擇 `increase` (若為黑桃 A 且 `setToZero` 可用，可考慮優化，但目前依需求以優先權為主)。
    *   **發送動作**: 構建 `Poker99PlayPayload` 並調用 `_gameController.sendGameAction('play_cards', payload: payload.toJson())`。

2.  **控制器整合**:
    *   修改 `FirestorePoker99Controller._initTestModeAIs`。
    *   移除 `TODO` 並實作 `Poker99AI` 的初始化。
    *   確保在測試模式開啟時，自動加入 2-3 個 AI 玩家。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **修改：** `lib/multiplayer/poker_99_ai/poker_99_ai.dart`
*   **修改：** `lib/multiplayer/firestore_poker_99_controller.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `effective_dart` 程式碼風格。
*   使用 `extension` 或 helper method 處理目標玩家計算。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  確認 AI 能正確選出手牌中數值最大的牌（Joker 除外）。
2.  確認當分數接近 99 時，10 與 Q 會正確選擇 `decrease`。
3.  確認出 5 時，目標玩家 ID 是正確的「上家」。
4.  確認 UI 測試模式下 AI 能自動出牌直到遊戲結束。

#### **3.2 邏輯檢查與改善建議**

*   **邏輯檢查**：
    *   「上一個玩家」的定義：在 `Poker99` 中，指定 (Assign) 的對象通常是想陷害的人。指定「上家」在不反轉的情況下，等於讓上家連續打兩次（或在反轉後讓其承擔 99 分風險）。
    *   若 `getPlayableCards` 為空，AI 應無法發送 `play_cards`，這部分 `Poker99Delegate` 會判定輸贏，AI 端僅需確保不崩潰。
*   **改善建議**：
    *   目前的優先順序是「先消耗大牌」，這在 99 遊戲中是合理的生存策略（保命）。
    *   針對黑桃 Ace，未來可以加入 `currentScore > 80` 時優先使用 `setToZero` 的邏輯。

---

### **Section 4: 產出 Commit Message**

```text
feat(poker_99): implement AI playing logic and controller integration

- Implement Poker 99 AI card selection strategy (Priority: Joker > K > Q ... > A)
- Add logic for Poker99Action selection (increase/decrease for 10/Q, target for 5)
- Calculate targetPlayerId based on current turn direction (isReverse)
- Initialize Poker99AI in FirestorePoker99Controller for test mode
- Include Task Specification: FEAT-POKER-99-CONTROLLER-002
```
