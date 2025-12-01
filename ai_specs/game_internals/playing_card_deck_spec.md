## AI 專案任務指示文件：新增發牌與洗牌功能

### **文件標頭 (Metadata)**

| 區塊 | 內容                   | 目的/對 AI 的意義 |
| :--- |:---------------------| :--- |
| **任務 ID (Task ID)** | `FEAT-GAME-DECK-001` | 方便追蹤和版本控制。 |
| **創建日期 (Date)** | `2025/12/01`         | - |
| **目標版本 (Target Version)** | `N/A`                | 新增核心遊戲機制。 |
| **專案名稱 (Project)** | `ok_multipl_poker`   | - |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

在 `PlayingCard` class 中實作一個靜態函式，該函式能生成一副不重複的 52 張撲克牌並將其洗亂，同時建立一個新的測試檔案來驗證此功能的正確性。

#### **1.2 詳細需求 (Detailed Requirements)**

*   **發牌邏輯:**
    *   在 `lib/game_internals/playing_card.dart` 的 `PlayingCard` class 中，新增一個名為 `createDeck` 的 `static` 函式。
    *   此函式應回傳 `List<PlayingCard>`。
    *   函式內部需產生 52 張獨一無二的 `PlayingCard` 物件，涵蓋四種花色（Clubs, Spades, Hearts, Diamonds）和 13 個點數（1 到 13）。
    *   在回傳牌組列表之前，必須使用 `List.shuffle()` 方法將其順序打亂。
*   **測試邏輯:**
    *   在 `test/game_internals/` 路徑下建立一個名為 `playing_card_test.dart` 的新測試檔案。
    *   在此檔案中，新增一個測試群組 (group)，專門用來測試 `PlayingCard.createDeck()` 的功能。
    *   測試案例必須至少包含以下三個驗證項目：
        1.  **數量驗證:** 驗證回傳的 `List` 長度是否**正好**為 52。
        2.  **唯一性驗證:** 驗證這 52 張牌中**沒有任何重複**的牌 (提示: 可以將 `List` 轉換為 `Set` 來比對長度)。
        3.  **洗牌驗證:** 驗證兩次呼叫 `createDeck()` 所產生的牌組順序是**不同**的，以確認洗牌功能有被執行。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **修改:** `lib/game_internals/playing_card.dart`
*   **新增:** `test/game_internals/playing_card_test.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **語言:** Dart
*   **測試框架:** `flutter_test`
*   **慣例:** 遵循 `effective_dart` 程式碼風格。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)**

1.  **執行計劃：** 簡要說明將如何修改 `playing_card.dart` 以及如何建立新的測試檔案。
2.  **程式碼輸出：** 分別提供 `playing_card.dart` (修改後) 和 `playing_card_test.dart` (新增) 的完整內容。

#### **3.2 驗證步驟 (Verification Steps)**

1.  確認 `playing_card.dart` 檔案被成功修改，並包含了 `createDeck` 函式。
2.  確認新的 `test/game_internals/playing_card_test.dart` 檔案被建立。
3.  在專案根目錄執行 `flutter test test/game_internals/playing_card_test.dart` 指令，確認所有測試案例皆能通過。

---

### **Section 4: 上一輪回饋 (Previous Iteration Feedback)**

*   無，此為初次建立。
