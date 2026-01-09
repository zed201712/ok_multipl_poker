## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                          |
|:---|:--------------------------------------------|
| **任務 ID (Task ID)** | `FEAT-POKER-99-CONTROLLER-001`              |
| **標題 (Title)** | `IMPLEMENT FIRESTORE POKER 99 CONTROLLER`   |
| **創建日期 (Date)** | `2026/01/09`                                |
| **目標版本 (Target Version)** | `N/A`                                       |
| **專案名稱 (Project)** | `ok_multipl_poker`                          |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

*   **說明：** 參考 `FirestoreBigTwoController` 的架構，實作 `FirestorePoker99Controller`，串接 Firestore 回合制遊戲機制與 Poker 99 的遊戲邏輯。
*   **目的：** 提供外部（如 UI 層）一個簡單的介面來操作 Poker 99 遊戲，包含匹配、出牌、重開局等功能。

#### **1.2 詳細需求 (Detailed Requirements)**

1.  **類別建立**: 建立 `FirestorePoker99Controller` 類別。
2.  **房間匹配**: `matchRoom` 支援最大人數 6 人。
3.  **核心功能移植**: 複製並調整以下方法：
    *   `leaveRoom`, `endRoom`, `restart`, `startGame`, `participantCount`, `dispose`。
4.  **出牌邏輯 (`playCards`)**:
    *   輸入參數改為 `Poker99PlayPayload payload`。
    *   發送 `play_cards` 行動至 `_gameController`。
5.  **類型替換**:
    *   將所有 `BigTwoDelegate` 替換為 `Poker99Delegate`。
    *   將所有 `BigTwoState` 替換為 `Poker99State`。
    *   `collectionName` 設定為 `'poker_99_rooms'`。
6.  **測試模式處理**:
    *   `_testModeAIs` 暫時使用 `BigTwoAI` 類型。
    *   `_initTestModeAIs` 標記 `TODO`，待後續實作 Poker 99 專屬 AI。
7.  **移除不適用功能**: 移除 `passTurn`（Poker 99 規則中不允許主動 Pass）。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **新增：** `lib/multiplayer/firestore_poker_99_controller.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `effective_dart` 程式碼風格。
*   確保與 `FirestoreTurnBasedGameController` 的整合正確。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  確認程式碼編譯通過，無類型錯誤。
2.  檢查 `playCards` 是否正確將 `Poker99PlayPayload` 轉為 JSON 發送。
3.  確認 `matchRoom` 的 `maxPlayers` 已設為 6。

#### **3.2 邏輯檢查與改善建議**

*   **邏輯檢查**：Poker 99 與 Big Two 的 `collectionName` 必須分開（已確認使用 `poker_99_rooms`）。
*   **改善建議**：未來實作 `Poker99AI` 時，需確保其能處理 `Poker99PlayPayload` 中複雜的 `action`（如指定玩家或加減分）。

---

### **Section 4: 產出 Commit Message**

```text
feat: implement FirestorePoker99Controller

- Create FirestorePoker99Controller based on Big Two controller architecture
- Support up to 6 players in matchRoom
- Implement playCards using Poker99PlayPayload
- Integrate Poker99Delegate and Poker99State
- Mark AI initialization as TODO
- Include Task Specification: FEAT-POKER-99-CONTROLLER-001
```
