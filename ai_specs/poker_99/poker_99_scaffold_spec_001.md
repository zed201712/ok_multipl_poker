## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-POKER-99-UI--001` |
| **標題 (Title)** | `SCAFFOLD POKER 99 GAME ARCHITECTURE` |
| **創建日期 (Date)** | `2026/01/08` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 建立 Poker 99 遊戲的基礎架構。
*   **目的：** 透過複製並重構現有的 Big Two 遊戲架構 (`BoardWidget`, `Delegate`, `Controller`, `AI`)，快速搭建 Poker 99 的可運行骨架。
*   **範圍：** 僅進行檔案複製、類別重新命名 (`BigTwo` -> `Poker99`) 以及解決基本的編譯錯誤。詳細的 Poker 99 遊戲規則（如加減值、爆牌判定）將在後續任務實作。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **建立遊戲狀態實體 (`Poker99State`)**
    *   複製 `lib/entities/big_two_state.dart` 為 `lib/entities/poker_99_state.dart`。
    *   類別更名：`BigTwoState` -> `Poker99State`。
    *   **注意：** 暫時保留欄位以維持編譯，但標記 `lockedHandType` 等 Big Two 專用欄位為待移除/修改。

2.  **建立遊戲邏輯代理 (`Poker99Delegate`)**
    *   複製 `lib/game_internals/big_two_delegate.dart` 為 `lib/game_internals/poker_99_delegate.dart`。
    *   類別更名：`BigTwoDelegate` -> `Poker99Delegate`。
    *   移除/註解所有對 `BigTwoCardPattern` 的依賴，因為 Poker 99 不使用牌型（Pair, FullHouse 等）。
    *   暫時將 `getPlayablePatterns` 等複雜邏輯簡化為回傳空列表或基本值，確保編譯通過。

3.  **建立 Firestore 控制器 (`FirestorePoker99Controller`)**
    *   複製 `lib/multiplayer/firestore_big_two_controller.dart` 為 `lib/multiplayer/firestore_poker_99_controller.dart`。
    *   類別更名：`FirestoreBigTwoController` -> `FirestorePoker99Controller`。
    *   更新依賴：指向 `Poker99State` 與 `Poker99Delegate`。
    *   Collection Name 修改為 `poker_99_rooms`。

4.  **建立 AI 邏輯 (`Poker99PlayCardsAI`)**
    *   複製 `lib/multiplayer/big_two_ai/big_two_play_cards_ai.dart` 為 `lib/multiplayer/poker_99_ai/poker_99_play_cards_ai.dart`。
    *   類別更名：`BigTwoPlayCardsAI` -> `Poker99PlayCardsAI`。
    *   介面實作更名：`implements Poker99AI` (需新增抽象介面或是暫時移除介面限制)。
    *   **邏輯簡化：** `findBestMove` 暫時改為隨機出一張牌，移除 Big Two 的比牌邏輯。

5.  **建立 UI 介面 (`Poker99BoardWidget`)**
    *   複製 `lib/play_session/big_two_board_widget.dart` 為 `lib/play_session/poker_99_board_widget.dart`。
    *   類別更名：`BigTwoBoardWidget` -> `Poker99BoardWidget`。
    *   更新依賴：使用 `FirestorePoker99Controller` 與 `Poker99Delegate`。
    *   **UI 調整：** 暫時移除牌型按鈕 (`handTypeButtons`)，保留出牌與 Pass (或改為 Draw) 按鈕結構。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **新增：** `lib/entities/poker_99_state.dart`
*   **新增：** `lib/game_internals/poker_99_delegate.dart`
*   **新增：** `lib/multiplayer/firestore_poker_99_controller.dart`
*   **新增：** `lib/multiplayer/poker_99_ai/poker_99_play_cards_ai.dart`
*   **新增：** `lib/play_session/poker_99_board_widget.dart`
*   **可能新增：** `lib/multiplayer/poker_99_ai/poker_99_ai.dart` (Interface)

#### **2.2 程式碼風格 (Style)**

*   遵循 `effective_dart`。
*   狀態管理使用 `Provider`。
*   保持檔案結構與 Big Two 一致，方便後續對照維護。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  確認所有新檔案皆無編譯錯誤 (Analysis 無 Error)。
2.  確認 `Poker99BoardWidget` 可以被實例化並顯示（即使邏輯尚未完全運作）。
3.  確認 `FirestorePoker99Controller` 指向正確的 Firestore Collection (`poker_99_rooms`)。

---

### **Section 4: Commit 程式碼分析與審查 (Analysis & Review)**

#### **4.1 邏輯差異預警 (Logical Divergence Alert)**
*   **牌型系統：** Big Two 依賴 `BigTwoCardPattern`，Poker 99 依賴數值加總與功能牌 (10, J, Q, K, A)。複製後需盡快移除 Pattern 相關程式碼。
*   **抽牌機制：** Poker 99 每回合出牌後**必須**抽一張牌，Big Two 則是把手牌打完。此架構複製後，需在 Delegate 的 `processAction` 中加入抽牌邏輯。
*   **狀態欄位：** `BigTwoState.lockedHandType` 在 Poker 99 中無意義，應替換為 `currentScore` (當前點數 0~99) 和 `isReverse` (迴轉狀態)。

