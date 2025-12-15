### **文件標頭 (Metadata)**

| 區塊 | 內容 | 目的/對 AI 的意義 |
| :--- |:---|:---|
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-BOARD-WIDGET-BIGTWO-002` | 方便追蹤和版本控制。 |
| **創建日期 (Date)** | `2025/12/16` | - |
| **目標版本 (Target Version)** | `N/A` | 重構遊戲狀態管理，提升通用性。 |
| **專案名稱 (Project)** | `ok_multipl_poker` | - |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

重構遊戲核心狀態管理，建立一個通用的 `CardBoardState` 基礎類別，並讓 `BigTwoBoardState` 繼承它。同時，更新相關的 UI 元件以適應新的狀態結構，並將中央出牌區的 Widget 替換為僅供顯示的 `ShowOnlyCardAreaWidget`。

#### **1.2 詳細需求 (Detailed Requirements)**

*   **建立通用狀態類別:**
    *   新增 `lib/game_internals/card_board_state.dart` 檔案。
    *   `CardBoardState` 應負責管理所有玩家 (`allPlayers`)、本地玩家索引 (`localPlayerIndex`) 以及勝利條件回呼 (`onWin`)。
*   **重構 `BigTwoBoardState`:**
    *   使其實現 (implements) `CardBoardState` 介面。
    *   移除獨立的 `player` 和 `otherPlayers` 屬性，改由 `allPlayers` 和 `localPlayerIndex` 計算得出。
    *   將 `centerPlayingArea` 的類型從 `PlayingArea` 改為 `CardPlayer`，用以統一管理牌組。
    *   修改 `restartGame()` 方法，使其能將牌發給 `allPlayers` 列表中的所有玩家，並將剩餘的牌放入 `centerPlayingArea`。
*   **建立僅顯示的卡牌區域 Widget:**
    *   新增 `lib/play_session/show_only_card_area_widget.dart` 檔案。
    *   這個 Widget (`ShowOnlyCardAreaWidget`) 應接收一個 `CardPlayer` 物件，並僅使用 `PlayingCardWidget` 顯示其手牌，不提供互動功能。
*   **更新遊戲主畫面 (`BigTwoBoardWidget`):**
    *   在佈局中，使用新的 `ShowOnlyCardAreaWidget` 來取代原有的 `PlayingAreaWidget`，用以顯示中央出牌區。
*   **更新玩家互動 Widget (`SelectablePlayerHandWidget`):**
    *   將其狀態依賴從 `BoardState` 更改為 `BigTwoBoardState`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **新增:**
    *   `lib/game_internals/card_board_state.dart`
    *   `lib/play_session/show_only_card_area_widget.dart`
*   **修改:**
    *   `lib/game_internals/big_two_board_state.dart`
    *   `lib/game_internals/card_player.dart`
    *   `lib/play_session/big_two_board_widget.dart`
    *   `lib/play_session/play_session_screen.dart`
    *   `lib/play_session/selectable_player_hand_widget.dart`
*   **刪除:**
    *   `test/game_internals/big_two_board_state_test.dart` (因 `BigTwoBoardState` 結構已變，測試失效)

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **狀態管理:** 繼續使用 `provider` 進行狀態管理。
*   **介面化:** 透過 `implements` 關鍵字實現介面，以達到代碼的通用性。
*   **風格:** 遵循 `effective_dart` 程式碼風格，並為新的類別和公共方法添加 DartDoc 註解。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)**

1.  **執行計劃：** 說明將如何建立 `CardBoardState`，重構 `BigTwoBoardState`，並更新相關 UI 元件以符合新的狀態模型。
2.  **程式碼輸出：** 提供所有新增及修改後檔案的完整內容。

#### **3.2 驗證步驟 (Verification Steps)**

1.  確認 `CardBoardState` 已建立，且 `BigTwoBoardState` 已實現其介面。
2.  確認 `BigTwoBoardWidget` 的中央區域已改用 `ShowOnlyCardAreaWidget`。
3.  確認 `restartGame` 的發牌邏輯在新架構下能正確運作。
4.  確認 `SelectablePlayerHandWidget` 能夠正確監聽 `BigTwoBoardState` 的變化。
5.  確認舊的測試檔案 `big_two_board_state_test.dart` 已被刪除。
6.  啟動應用程式，確保大老二遊戲畫面能正常渲染，且發牌功能無誤。
