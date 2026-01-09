## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                          |
|:---|:--------------------------------------------|
| **任務 ID (Task ID)** | `FEAT-POKER-99-DELEGATE-001`                |
| **標題 (Title)** | `IMPLEMENT POKER 99 CORE LOGIC IN DELEGATE` |
| **創建日期 (Date)** | `2026/01/09`                                |
| **目標版本 (Target Version)** | `N/A`                                       |
| **專案名稱 (Project)** | `ok_multipl_poker`                          |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

*   **說明：** 在 `Poker99Delegate` 中實作 Poker 99 的核心遊戲規則，包括卡牌點數計算、特殊功能牌處理、抽牌機制、以及玩家淘汰邏輯。
*   **目的：** 使 `Poker99Delegate` 能夠正確處理 `play_cards` 行動，並根據規則更新 `Poker99State`，實現遊戲從開始到結束的完整流程控制。

#### **1.2 詳細需求 (Detailed Requirements)**

1.  **卡牌點數與功能規則實作**:
    *   **一般牌 (2, 3, 6, 7, 8, 9)**: 依面值加分。
    *   **Ace (A)**: 數值固定為 1 (或根據變體可選 1 或 11，此處先實作固定為 1)。
    *   **4 (Reverse)**: 改變出牌順序 (`isReverse = !isReverse`)。
    *   **5 (Assign)**: 指定下一個出牌的人 (需在 `payload` 帶入 `targetPlayerId`)。
    *   **10 (Plus/Minus 10)**: 加 10 或減 10 (需在 `payload` 帶入 `value: 10` 或 `-10`)。
    *   **Jack (J) (Skip)**: 跳過下一位玩家。
    *   **Queen (Q) (Plus/Minus 20)**: 加 20 或減 20 (需在 `payload` 帶入 `value: 20` 或 `-20`)。
    *   **King (K) (Set to 99)**: 直接將 `currentScore` 設為 99。

2.  **出牌流程 (`_playCards`)**:
    *   **驗證**: 確認玩家擁有該牌，且出牌後 `currentScore` 不會超過 99（除非是特殊功能牌如 K, 10, Q 可調控）。
    *   **更新狀態**: 更新 `currentScore`、`isReverse`、`lastPlayedHand`、`lastPlayedById`。
    *   **抽牌**: 出牌後，從 `deckCards` 抽一張牌補回手牌。若 `deckCards` 已空，則將 `discardCards` (除最後一張外) 洗牌後補入 `deckCards`。

3.  **輪次切換與淘汰邏輯**:
    *   計算下一個玩家 `nextPlayerId` 時需考慮 `isReverse`。
    *   若某玩家在輪到他時，手牌中沒有任何一張牌可以出（出牌後都會 > 99），該玩家淘汰 (`hasPassed = true`)。
    *   **勝利條件**: 當 `participants` 中僅剩一位未淘汰的玩家時，設定該玩家為 `winner`。

4.  **提供輔助方法**:
    *   `getPlayableCards(Poker99State state, List<PlayingCard> handCards)`: 計算當前手牌中哪些卡片是合法可出的（不會導致總分 > 99）。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **修改：** `lib/game_internals/poker_99_delegate.dart` (實作 `processAction` 與私有邏輯)
*   **參考：** `lib/entities/poker_99_state.dart` (了解欄位)
*   **參考：** `lib/game_internals/playing_card.dart` (卡牌數值獲取)

#### **2.2 程式碼風格 (Style)**

*   遵循 `effective_dart`。
*   保持邏輯純粹，不直接操作 UI 或資料庫，僅透過傳入的 `Poker99State` 計算並回傳新的 `Poker99State`。
*   使用 `BigTwoDeckUtilsMixin` (或將其更名/抽象) 來處理洗牌與排序。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **單元測試**: 建立測試案例模擬 99 點時出 K (維持 99)、出 10 (減為 89)、出 5 (指定玩家) 等情境。
2.  **邊界檢查**: 模擬 `deckCards` 抽完時的洗牌邏輯。
3.  **淘汰測試**: 確認當玩家手牌全大於 99 可容忍值時，觸發淘汰邏輯。

---

### **Section 4: Commit 程式碼分析與審查 (Analysis & Review)**

#### **4.1 潛在影響分析**
*   **Payload 結構**: `play_cards` 行動的 `payload` 需要擴展以支援 10, Q 的正負選擇以及 5 的目標指定。
*   **與 Big Two 差異**: Poker 99 是「先出牌後補牌」，這與 Big Two 「打完為止」的邏輯不同，需確保 `deckCards` 管理正確。

---

### **Section 5: 產出 Commit Message**

```text
feat: implement Poker 99 core rules, card effects, and elimination logic

- Implement card functions for Poker 99 (1, 4, 5, 10, J, Q, K)
- Add draw and reshuffle mechanism for deck and discard piles
- Implement player elimination logic based on playable cards
- Include Task Specification: FEAT-POKER-99-DELEGATE-001
```