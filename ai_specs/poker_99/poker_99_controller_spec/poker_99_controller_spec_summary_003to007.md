# Poker 99 控制器與 AI 重構任務總結 (Spec Summary)

## 1. 這系列 Spec 的目的
這系列規格文件（003-007）旨在對 Poker 99 的遊戲邏輯與控制器進行深度的架構重構與功能增強。
主要目標包括：
- **解耦 AI 邏輯**：將 AI 從 Firestore/Auth 等基礎設施中分離，使其成為純粹的邏輯單元，便於測試與複用。
- **泛型化機器人環境**：打造通用的 `BotContext<T>`，使其不依賴特定遊戲實作，提升系統的可擴展性。
- **統一遊戲核心邏輯**：將回合切換、特殊牌效果（如 4、7、10、Q）、勝負判定等邏輯收斂至 `State` 中，確保 UI、AI 與控制器行為高度一致。
- **引入策略模式 (Strategy Pattern)**：消除控制器內部的條件分支污染（如 `if (isBotPlaying)`），明確分離「線上模式」與「單機模式」的執行細節。
- **提升使用者體驗**：優化單機對戰流程、修復特殊牌邏輯 Bug（特別是「指定」功能），並增強 UI 的資訊展示（如顯示最後一手出的牌）。

## 2. 應該輸出與修改的檔案清單
根據系列 Spec，涉及的檔案如下：

### 核心實體與邏輯 (Core Entities & Logic)
- `lib/entities/poker_99_state.dart` (修改：收納回合計算 `nextPlayerId` 與指定目標邏輯)
- `lib/game_internals/poker_99_delegate.dart` (修改：簡化規則判定，呼叫 State 統一邏輯)
- `lib/game_internals/playing_card.dart` (修改：定義具唯一性的鬼牌 `joker1`, `joker2`)

### AI 與 機器人環境 (AI & Bot Environment)
- `lib/multiplayer/poker_99_ai/poker_99_ai.dart` (修改：移除 Firebase 依賴，轉型為實作 `TurnBasedAI` 介面的邏輯單元)
- `lib/multiplayer/turn_based_game_state.dart` (修改：定義 `TurnBasedCustomState` 介面與泛型約束)
- `lib/multiplayer/turn_based_ai.dart` (新增：定義通用的 `TurnBasedAI<T>` 介面)

### 控制器與策略 (Controller & Strategy)
- `lib/multiplayer/firestore_poker_99_controller.dart` (重構：整合 `BotContext` 管理，並轉型為 `GamePlayStrategy` 的上下文)
- `lib/multiplayer/strategy/game_play_strategy.dart` (新增：定義遊戲流程行為介面)
- `lib/multiplayer/strategy/online_multiplayer_strategy.dart` (新增：封裝 Firestore 線上遊戲邏輯)
- `lib/multiplayer/strategy/bot_game_strategy.dart` (新增：封裝本地機器人對戰邏輯)

### UI 組件 (UI Components)
- `lib/play_session/poker_99_board_widget.dart` (修改：新增最後出牌紀錄展示區域與優化分數佈局)

## 3. 檔案職責說明

| 檔案 / 組件 | 主要職責 |
| :--- | :--- |
| **`Poker99State`** | **資料與運算核心**。負責維護遊戲數值（點數、手牌），並精確計算下一個玩家 ID（處理迴轉、指定、淘汰跳過）。 |
| **`Poker99AI`** | **出牌決策大腦**。接收狀態更新，基於規則權重決定出牌策略，並透過回呼 (onAction) 通知外部執行動作。 |
| **`BotContext<T>`** | **本地模擬伺服器**。管理虛擬房間與機器人資訊，在本地模擬 Firestore 的狀態流以驅動單機模式。 |
| **`FirestorePoker99Controller`** | **任務調度與 Context**。負責初始化 AI、根據玩家人數動態切換遊戲策略，並作為 Provider 供 UI 調用。 |
| **`GamePlayStrategy` 系列** | **行為執行封裝**。隔離「向雲端發送指令」與「在本地環境操作」的細節，讓控制器只需專注於「何時」執行。 |
| **`Poker99BoardWidget`** | **視圖呈現與回饋**。展示遊戲版面，並透過新增的 `ShowOnlyCardAreaWidget` 即時回饋最後打出的牌，提升代入感。 |
