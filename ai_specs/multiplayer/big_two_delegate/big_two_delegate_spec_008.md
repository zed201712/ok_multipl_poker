## AI 專案任務指示文件 (Feature Task)

| 區塊                        | 內容                                      |
|:--------------------------|:----------------------------------------| 
| **任務 ID (Task ID)**       | `FEAT-BIG-TWO-DELEGATE-008`             |
| **標題 (Title)**            | `2-3 PLAYER MODES & AI HELPER ALGORITHMS` |
| **創建日期 (Date)**           | `2025/12/23`                            |
| **目標版本 (Target Version)** | `N/A`                                   |
| **專案名稱 (Project)**        | `ok_multipl_poker`                      |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 擴充 Big Two 遊戲引擎以支援 2 人及 3 人對局模式。
*   **核心機制：**
    1.  **固定發三家牌：** 無論是 2 人或 3 人局，發牌邏輯均視為「3 個座位」進行發牌 (通常每家 17 張)。
    2.  **虛擬玩家 (Virtual Player)：** 在 2 人局中，第 3 個座位由「虛擬玩家」佔據。該玩家持有手牌但不參與遊戲 (輪到時自動跳過/Pass)。
    3.  **動態起始規則：** 不再硬性規定梅花 3 (C3) 先出，而是由「持有真人玩家手中最小牌」的玩家先出。
    4.  **AI 輔助運算：** 實作能計算「當前可出牌型」與「特定牌型組合」的演算法，用於未來的 AI 決策或玩家提示。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **實體更新 (Entity Update)**
    *   修改 `BigTwoPlayer`，新增 `final bool isVirtualPlayer` 欄位 (預設為 `false`)。

2.  **遊戲初始化與座位邏輯 (Initialization & Seating)**
    *   **`initializeGame` & `_processRestartRequest`**：
        *   若 `room.seats` 人數為 3 人：正常分配 3 個座位。
        *   若 `room.seats` 人數為 2 人：分配 3 個座位 (2 個真人 + 1 個 ID 為 `virtual_player` 的虛擬玩家)。
        *   發牌：將牌組分配給這 3 個座位 (每人 17 張)，剩餘 1 張牌。
        *   **餘牌處理：** 將該張餘牌分配給「持有目前最小牌」的**真人玩家**。該玩家將持有 18 張牌。
    *   **起始玩家判定**：
        *   遍歷所有**非虛擬玩家 (isVirtualPlayer == false)** 的手牌。
        *   找出持有「絕對數值最小的一張牌」的玩家 ID 作為 `startingPlayerId`。
        *   更新 `validateFirstPlay` 邏輯：第一手牌必須包含這張「非虛擬玩家最小牌」，而非寫死的 C3。

3.  **回合流程控制 (Flow Control)**
    *   修改 `_nextTurn` 邏輯：當計算出下一位玩家是 `isVirtualPlayer` 時，該玩家視為自動 Pass，直接將控制權轉給再下一位玩家，直到找到真人玩家或觸發 Round Over。

4.  **AI 輔助/提示演算法 (AI Helpers)**
    *   在 `BigTwoDelegate` 中新增以下輔助函式 (需公開以便外部 AI/UI 調用)：
        *   **`getPlayablePatterns`**: 根據當前 `lockedHandType`，判斷玩家手牌能組成哪些合法的牌型 (如 Single, Pair, Straight 等)。
        *   **`getPlayableCombinations`**: 針對「特定牌型 (Pattern)」，列出玩家手牌中所有能打贏 `lastPlayedHand` 的具體牌組 (List of Strings)。
        *   **`getAllPlayableCombinations`**: 綜合上述兩者，列出當前局勢下，玩家所有合法的出牌組合。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/entities/big_two_player.dart` (新增欄位)
*   **修改：** `lib/game_internals/big_two_delegate.dart` (核心邏輯、AI 演算法)
*   **新增：** `test/game_internals/big_two_delegate_helpers_test.dart` (針對新演算法的測試)
*   **修改：** `test/game_internals/big_two_delegate_test.dart` (核心邏輯單元測試與整合測試)

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **Effective Dart：** 遵循變數命名與 lint 規範。
*   **演算法優化：** 尋找牌型組合時，應避免不必要的暴力破解 (Brute-force)，善用手牌已排序的特性。
*   **Immutability：** 回傳的 List 應為新的實例，不可修改原始 State 或 Player 的手牌。

#### **2.3 函式簽名規範 (Function Signatures)**

**`lib/game_internals/big_two_delegate.dart`**

```dart
/// 尋找非虛擬玩家手上的最小牌，回傳該牌的 String 代碼 (例如 'C3', 'D4')
String _findLowestHumanCard(List<BigTwoPlayer> players);

/// 功能 3: 回傳該玩家現在可以出的牌型種類 (考慮了 lockedHandType)
List<BigTwoCardPattern> getPlayablePatterns(BigTwoState state, BigTwoPlayer player);

/// 功能 4: 針對特定牌型，回傳所有可打出的牌組 (必須 beat lastPlayedHand)
List<List<String>> getPlayableCombinations(
    BigTwoState state, 
    BigTwoPlayer player, 
    BigTwoCardPattern pattern
);

/// 功能 5: 回傳當前所有可打出的牌組 (功能 3 + 功能 4 的總集)
List<List<String>> getAllPlayableCombinations(BigTwoState state, BigTwoPlayer player);
```

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **2 人局測試：**
    *   初始化遊戲，確認 `participants` 長度為 3。
    *   確認其中一位是 `isVirtualPlayer: true`。
    *   確認兩位真人與一位虛擬玩家手牌數量均等。
    *   確認起始玩家是持有「兩人手中最小牌」的那一位，且該牌必須在第一手打出。
    *   模擬輪次，確認當輪到虛擬玩家時，狀態會自動跳轉至下一位真人，且虛擬玩家狀態標記為 `hasPassed: true` (若當局尚未結束)。

2.  **AI 演算法測試 (Unit Tests)：**
    *   **情境 A (Free Turn)：** 給定一手雜牌，呼叫 `getAllPlayableCombinations`，確認回傳包含所有單張、對子、以及合法的 5 張組合。
    *   **情境 B (Locked - Pair)：** 上家出 `Pair(10)`, 玩家手上有 `Pair(9)` 和 `Pair(J)`。確認只回傳 `Pair(J)`。
    *   **情境 C (Locked - FullHouse)：** 上家出 `FullHouse(33355)`。玩家有 `FullHouse(44466)`。確認能正確回傳。
    *   **情境 D (Pass)：** 玩家無牌可出，回傳空 List。

3.  **邊界測試：**
    *   測試 5 張牌型的比大小邏輯 (同花順 > 鐵支 > 葫蘆 > 順子)。
    *   測試「非 C3 開局」的情況 (例如最小牌是 方塊 4)。

---

### **Section 4: 實作與審查記錄 (Implementation & Review Log)**

#### **4.1 實作狀態 (Implementation Status)**

*   **日期：** `2025/12/23`
*   **狀態：** 已完成 (Implemented & Reviewed)
*   **審查重點：**
    1.  **虛擬玩家機制**：已在 `initializeGame` 與 `_nextTurn` 中實作。`_nextTurn` 採用遞迴方式自動跳過 `isVirtualPlayer` 為真的玩家，並正確處理 `passCount` 與回合結束 (Round Over) 邏輯。
    2.  **餘牌分配**：已確認將第 52 張牌分配給持有「目前最小牌」的真人玩家。
    3.  **比牌邏輯 (`isBeating`)**：已在 `BigTwoDelegate` 中實作完整比牌邏輯，並透過 `test/game_internals/big_two_delegate_test.dart` 進行驗證，包含特殊牌型 (炸彈) 處理。
    4.  **AI 輔助函式**：`getPlayablePatterns`, `getPlayableCombinations`, `getAllPlayableCombinations` 已實作並通過 `big_two_delegate_helpers_test.dart` 測試。

#### **4.2 測試覆蓋 (Test Coverage)**

*   `test/game_internals/big_two_delegate_helpers_test.dart`: 涵蓋 AI 輔助算法與初始化邊界條件 (2人/3人)。
*   `test/game_internals/big_two_delegate_test.dart`: 涵蓋核心規則 (`getCardPattern`, `isBeating`, `checkPlayValidity`) 與 `processAction` 狀態流轉。
