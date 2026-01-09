## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                          |
|:---|:--------------------------------------------|
| **任務 ID (Task ID)** | `FEAT-POKER-99-DELEGATE-002`                |
| **標題 (Title)** | `ENHANCE POKER 99 LOGIC WITH PAYLOAD ENTITY AND SPECIAL CARDS` |
| **創建日期 (Date)** | `2026/01/09`                                |
| **目標版本 (Target Version)** | `N/A`                                       |
| **專案名稱 (Project)** | `ok_multipl_poker`                          |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

*   **說明：** 引入 `Poker99PlayPayload` 實體以標準化出牌行動的參數。實作「黑桃 A」歸零功能與「鬼牌」多功能選擇。
*   **目的：** 提高代碼健壯性，將邏輯判斷（如加或減）從 Delegate 移至呼叫端，Delegate 僅負責驗證合法性並執行狀態變更。

#### **1.2 詳細需求 (Detailed Requirements)**

1.  **新增 `Poker99PlayPayload` 實體**:
    *   檔案路徑: `lib/entities/poker_99_play_payload.dart`。
    *   欄位:
        *   `List<String> cards`: 玩家出的牌（通常為一張）。
        *   `Poker99Action action`: 玩家選擇的行動（對應 `Poker99Action` enum）。
        *   `int value`: 變動的數值（例如 10, -10, 20, -20, 0, 99）。
        *   `String targetPlayerId`: 指定的下一個玩家 ID（僅在 `action == target` 時有效）。
    *   需支援 `JsonSerializable` 並提供 `fromJson`/`toJson`。

2.  **更新 `Poker99Delegate`**:
    *   在 `processAction` 中，將 `Map<String, dynamic> payload` 轉換為 `Poker99PlayPayload`。
    *   `_playCards` 改為接收 `Poker99PlayPayload`。
    *   **邏輯變更**:
        *   **黑桃 A (Spades Ace)**: 當牌為黑桃 A 且 `action == setToZero` 時，`currentScore` 變為 0。
        *   **鬼牌 (Joker)**: 當牌為鬼牌時，允許 `action` 為 `skip`, `reverse`, `target`, `setToZero`, `setTo99`。
        *   **驗證**: Delegate 需檢查傳入的 `action` 是否符合該卡牌的特性（例如普通牌不能選 `skip`）。

3.  **規則細節與改善建議**:
    *   **邏輯解耦**: Delegate 不再透過 `card.value` 猜測玩家想加還是減，而是直接讀取 `payload.value`。
    *   **安全性**: 雖然 Delegate 相信 `payload.value`，但仍需驗證出牌後總分是否在 0~99 之間，且驗證該牌是否具備該 `action` 能力。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **新增：** `lib/entities/poker_99_play_payload.dart`
*   **修改：** `lib/game_internals/poker_99_delegate.dart`
*   **參考：** `lib/game_internals/poker_99_action.dart`
*   **參考：** `lib/game_internals/playing_card.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `effective_dart`。
*   使用 `json_serializable` 產生 JSON 轉換代碼。
*   狀態管理建議搭配 `Provider` 使用（在 UI 層級）。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  確認 `Poker99PlayPayload` 序列化正常。
2.  模擬黑桃 A 出牌，傳入 `setToZero` 行動，確認總分變 0。
3.  模擬鬼牌出牌，傳入 `target` 或 `setTo99`，確認功能觸發。
4.  檢查非法行動（例如 3 號牌傳入 `setTo99`）是否被拒絕（不更新狀態）。

---

### **Section 4: Commit 程式碼分析與審查 (Analysis & Review)**

#### **4.1 潛在影響分析**
*   **破壞性變更**: `_playCards` 的參數結構改變，現有的測試或呼叫端需要同步更新。
*   **擴展性**: 透過 `Poker99PlayPayload`，未來若增加更多特殊牌（如指定抽牌等），只需擴展 Enum 與 Payload 即可。

---

### **Section 5: 產出 Commit Message**

```text
feat(poker_99): implement Poker99PlayPayload and enhance delegate with special card logic (Spades Ace, Joker)
```