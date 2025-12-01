## AI 專案任務指示文件：建立可自定義的 CardPlayer Class

### **文件標頭 (Metadata)**

| 區塊 | 內容 | 目的/對 AI 的意義 |
| :--- | :--- | :--- |
| **任務 ID (Task ID)** | `FEAT-GAME-CARDPLAYER-001` | 方便追蹤和版本控制。 |
| **創建日期 (Date)** | `2025/12/01` | - |
| **目標版本 (Target Version)** | `N/A` | 新增核心遊戲機制元件。 |
| **專案名稱 (Project)** | `ok_multipl_poker` | - |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

建立一個名為 `CardPlayer` 的新 Dart class，它繼承自 `Player` 的核心邏輯，但允許在建立實例時傳入自定義的初始手牌與最大牌數，並建立一個新的測試檔案來驗證其功能的正確性。

#### **1.2 詳細需求 (Detailed Requirements)**

*   **`CardPlayer` Class 邏輯:**
    *   在 `lib/game_internals/` 路徑下，建立一個名為 `card_player.dart` 的新檔案。
    *   `CardPlayer` class 應繼承 (extend) `ChangeNotifier`。
    *   `CardPlayer` 的建構子 (constructor) 應能接收兩個**可選的**具名參數：`int? maxCards` 和 `List<PlayingCard>? initialHand`。
    *   `CardPlayer` 內部應有一個名為 `hand` 的 `List<PlayingCard>` 屬性，其初始值應為 `initialHand` 參數；如果未提供 `initialHand`，則 `hand` 應為一個空列表 (`[]`)。
    *   `CardPlayer` 應有一個名為 `maxCards` 的 `final int` 屬性，其值應為 `maxCards` 參數；如果未提供，則預設為 `13`。
    *   保留 `removeCard(PlayingCard card)` 方法，其功能與原始的 `Player` class 相同，調用後需執行 `notifyListeners()`。

*   **測試邏輯:**
    *   在 `test/game_internals/` 路徑下，建立一個名為 `card_player_test.dart` 的新測試檔案。
    *   在此檔案中，至少包含以下三個測試案例：
        1.  **預設初始化測試:** 驗證當不帶任何參數建立 `CardPlayer` 時，其 `hand` 為空列表，且 `maxCards` 為預設值 `13`。
        2.  **自定義手牌測試:** 驗證當傳入一個 `initialHand` 列表來建立 `CardPlayer` 時，其 `hand` 屬性的內容與傳入的列表完全相符。
        3.  **`removeCard` 功能測試:** 驗證呼叫 `removeCard` 方法後，指定的牌會從 `hand` 列表中被移除。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **新增:** `lib/game_internals/card_player.dart`
*   **新增:** `test/game_internals/card_player_test.dart`
*   **參考:** `lib/game_internals/player.dart` (作為新 class 的功能參考)

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **語言:** Dart
*   **測試框架:** `flutter_test`
*   **慣例:** 遵循 `effective_dart` 程式碼風格。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)**

1.  **執行計劃：** 簡要說明將如何建立 `card_player.dart` 以及對應的測試檔案 `card_player_test.dart`。
2.  **程式碼輸出：** 分別提供 `card_player.dart` (新增) 和 `card_player_test.dart` (新增) 的完整內容。

#### **3.2 驗證步驟 (Verification Steps)**

1.  確認 `lib/game_internals/card_player.dart` 檔案被成功建立，且 class 的實作符合要求。
2.  確認新的 `test/game_internals/card_player_test.dart` 檔案被建立。
3.  在專案根目錄執行 `flutter test test/game_internals/card_player_test.dart` 指令，確認所有測試案例皆能通過。

---

### **Section 4: 上一輪回饋 (Previous Iteration Feedback)**

*   無，此為初次建立。
