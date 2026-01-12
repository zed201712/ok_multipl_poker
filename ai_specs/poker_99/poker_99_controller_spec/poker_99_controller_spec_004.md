## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                          |
|:---|:--------------------------------------------|
| **任務 ID (Task ID)** | `FEAT-POKER-99-CONTROLLER-004`              |
| **標題 (Title)** | `FIX BOT LOGIC, UNIFY TURN CALCULATION AND IMPROVE UI` |
| **創建日期 (Date)** | `2026/01/12`                                |
| **目標版本 (Target Version)** | `N/A`                                       |
| **專案名稱 (Project)** | `ok_multipl_poker`                          |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

*   **說明：** 修正機器人（Bot）運作邏輯，統一玩家回合計算機制，並優化遊戲介面的資訊展示。
*   **目的：** 解決 Bot 在自動對戰模式下的同步問題，確保特殊牌（如「指定」）的邏輯正確，並提升玩家的操作體驗。

#### **1.2 詳細需求 (Detailed Requirements)**

1.  **統一回合計算 (Poker99State)**:
    *   將原本分散在 `Delegate` 的 `_calculateNextPlayerId` 邏輯遷移至 `Poker99State.nextPlayerId()`。
    *   **支援指定功能**：在狀態中加入 `targetPlayerId`，當有指定目標且該玩家未淘汰時，下一回合直接跳轉。
    *   **優化循環邏輯**：改善 `isReverse` (迴轉) 與淘汰玩家跳過的判定機制。

2.  **牌組定義調整 (PlayingCard)**:
    *   區分兩張鬼牌為 `joker1()` 與 `joker2()`，確保牌組唯一性。

3.  **Bot 控制器重構 (_BotContext & Controller)**:
    *   **生命週期管理**：為 `_BotContext` 加入 `StreamSubscription` 管理，避免遊戲結束或重新開始時出現監聽洩漏。
    *   **狀態同步優化**：Bot 的行動回呼 (`onAction`) 現在會透過 `_updateStateAndAddStream` 同步更新本地與模擬的 Firestore 狀態。
    *   **自動 Bot 模式**：在 `startGame` 時，若房間內僅有 1 名玩家，自動切換為 `_isBotPlaying` 模式並啟動 Bot 對戰。
    *   **結算處理**：當判定有贏家時，自動幫所有 Bot 發送 `restart_request`，簡化測試流程。

4.  **UI 介面優化 (Poker99BoardWidget)**:
    *   **展示出牌紀錄**：在分數板旁邊新增 `ShowOnlyCardAreaWidget`，展示最後一手出的牌。
    *   **佈局調整**：將分數展示改為橫向排列，並加入適當的間距與陰影效果。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **修改：** `lib/entities/poker_99_state.dart` (回合邏輯)
*   **修改：** `lib/game_internals/playing_card.dart` (鬼牌定義)
*   **修改：** `lib/game_internals/poker_99_delegate.dart` (呼叫新回合計算)
*   **修改：** `lib/multiplayer/firestore_poker_99_controller.dart` (Bot 流程控管)
*   **修改：** `lib/multiplayer/poker_99_ai/poker_99_ai.dart` (清理冗餘代碼)
*   **修改：** `lib/play_session/poker_99_board_widget.dart` (UI 顯示)

#### **2.2 程式碼風格 (Style)**

*   維持邏輯與狀態的分離，State 負責資料運算，Controller 負責流程，Delegate 負責規則。
*   移除 `print` 調試訊息。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  確認在只有一名玩家點擊「開始遊戲」時，會正確進入 Bot 模式。
2.  驗證「指定 (7)」功能是否能正確將回合轉交給目標玩家。
3.  驗證「迴轉 (4)」功能是否能正確切換順/逆時針方向。
4.  檢查 UI 是否正確顯示最後一張打出的牌。

#### **3.2 邏輯檢查與改善建議**

*   **邏輯檢查**：
    *   `nextPlayerId` 中使用 `seats.indexOf(state.currentPlayerId)`，若 `currentPlayerId` 為空字串或不在座位上，會返回 `-1`。建議加入防錯處理或確保初始狀態正確。
    *   Bot 的 `onAction` 觸發過快可能導致 UI 連續跳動，雖然目前有延遲，但需注意併發衝突。
*   **改善建議**：
    *   `Poker99State` 的 `targetPlayerId` 在使用完後應在下一次 state 更新時重置為空，避免重複觸發跳轉邏輯（目前 Delegate 已有處理）。

---

### **Section 4: 產出 Commit Message**

```text
refactor(poker_99): fix bot logic, unify turn calculation and improve UI

- Move turn calculation logic to Poker99State and support target player assignment
- Refactor _BotContext for better stream management and state synchronization
- Enable automatic bot mode for single-player starts
- Update UI to display the last played card and improve score layout
- Include Task Specification: FEAT-POKER-99-CONTROLLER-004
```
