
## AI 專案任務指示文件 (Feature Task)

| 區塊                        | 內容                                     |
| :------------------------ | :------------------------------------- |
| **任務 ID (Task ID)**       | `FEAT-POKER-99-CONTROLLER-007`         |
| **標題 (Title)**            | `INTRODUCE GAME PLAY STRATEGY PATTERN` |
| **創建日期 (Date)**           | `2026/01/13`                           |
| **目標版本 (Target Version)** | `N/A`                                  |
| **專案名稱 (Project)**        | `ok_multipl_poker`                     |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

* **說明：**
  針對 `FirestorePoker99Controller` 中混合處理「線上多人模式」與「單機 Bot 模式」的行為邏輯，引入 **Strategy Pattern**，將遊戲流程相關行為（配對、開始、重開、離開、結束）解耦為可替換的策略實作。
* **目的：**

    * 移除 `_isBotPlaying` 所造成的條件分支污染。
    * 明確分離「行為如何執行」與「何時執行」的責任。
    * 提高後續擴充新遊戲模式（例如教學模式、觀戰模式、Replay）的可維護性。

---

#### **1.2 設計原則 (Design Principles)**

* 遵循 **Strategy Pattern**：

    * 將「遊戲進行行為」抽象為介面。
    * 由 Controller 持有並切換策略，而非在方法內使用 `if / else` 判斷。
* Controller 僅作為 **Context**：

    * 不直接判斷是否為 Bot 模式。
    * 不包含任何模式分支邏輯。
* 策略本身不管理 UI 狀態，僅負責遊戲行為執行。
* 狀態管理仍使用 `Provider`，本任務不引入新的狀態管理方案。

---

### **Section 2: 詳細需求 (Detailed Requirements)**

#### **2.1 新增策略介面定義**

新增抽象介面：

```dart
abstract class GamePlayStrategy {
  Future<String?> matchRoom();
  Future<void> startGame();
  Future<void> restart();
  Future<void> leaveRoom();
  Future<void> endRoom();
}
```

* 該介面定義 Controller 所需的所有「遊戲流程相關行為」。
* Controller 僅能透過此介面操作遊戲流程。

---

#### **2.2 OnlineMultiplayerStrategy**

新增 `OnlineMultiplayerStrategy`，負責線上多人遊戲邏輯：

* **行為來源**：

    * 使用 `_gameController` 直接呼叫 Firestore API。
* **責任範圍**：

    * `matchRoom()` → 呼叫 `matchAndJoinRoom`
    * `startGame()` → 呼叫 `_gameController.startGame()`
    * `restart()` → 發送 `request_restart`
    * `leaveRoom()` / `endRoom()` → 對應 Firestore controller 行為
* **限制**：

    * 不處理 BotContext
    * 不檢查玩家數量
    * 不負責策略切換

---

#### **2.3 BotGameStrategy**

新增 `BotGameStrategy`，負責單機 Bot 遊戲邏輯：

* **行為來源**：

    * 使用 `BotContext<Poker99State>`
* **責任範圍**：

    * `matchRoom()` → 建立本地 Bot 房間
    * `startGame()` → 呼叫 `botContext.startGame()`
    * `restart()` → 重新建立房間並開始遊戲
    * `leaveRoom()` / `endRoom()` → 可為 no-op 或保留擴充點
* **限制**：

    * 不直接操作 `_gameController`
    * 不包含任何 UI 判斷邏輯

---

#### **2.4 FirestorePoker99Controller 重構**

##### **2.4.1 新增策略成員**

```dart
late GamePlayStrategy _gamePlayStrategy;
```

* Controller 僅透過 `_gamePlayStrategy` 執行遊戲流程行為。

---

##### **2.4.2 策略初始化與切換規則**

* 預設使用 `OnlineMultiplayerStrategy`
* 在以下條件下切換為 `BotGameStrategy`：

    * `startGame()` 時，發現房間參與者數量 ≤ 1
    * Controller 負責策略切換，但不負責執行策略細節

---

##### **2.4.3 Controller 方法重構規則**

以下方法：

```dart
matchRoom()
startGame()
restart()
leaveRoom()
endRoom()
```

必須滿足：

* Controller 方法內：

    * **不得出現 `_isBotPlaying`**
    * **不得出現 Bot / Online 的條件判斷**
* 僅轉呼叫 `_gamePlayStrategy` 對應方法

---

### **Section 3: 技術細節與範圍 (Technical Scope & Constraints)**

#### **3.1 受影響檔案**

* **修改：**

    * `lib/multiplayer/firestore_poker_99_controller.dart`
* **新增：**

    * `lib/multiplayer/strategy/game_play_strategy.dart`
    * `lib/multiplayer/strategy/online_multiplayer_strategy.dart`
    * `lib/multiplayer/strategy/bot_game_strategy.dart`

---

#### **3.2 程式碼風格與限制**

* 遵循 `effective_dart`
* 狀態管理使用 `Provider`
* 非必要：

    * 不移動既有 class
    * 不刪除既有註解
    * 不調整文字排版
    * 不製造多餘 git diff

---

### **Section 4: 驗證與檢查 (Verification & Review)**

#### **4.1 驗證步驟**

1. `FirestorePoker99Controller` 中不再存在 `_isBotPlaying`
2. 所有遊戲流程方法僅透過 `GamePlayStrategy`
3. 單機 Bot 模式下：

    * Bot 仍能正常接收狀態更新
    * 出牌與 restart 行為正常
4. 線上多人模式不受影響

---

#### **4.2 邏輯檢查與改善建議**

* **邏輯檢查**：

    * 確認策略切換僅發生於 Controller，避免策略彼此依賴。
    * BotGameStrategy 不應隱式操作 Firestore。
* **改善建議（非本次實作）**：

    * 未來可引入 `GamePlayStrategyFactory`，進一步降低 Controller 初始化責任。
    * 若遊戲流程狀態增多，可考慮搭配 State Pattern。

---

### **Section 5: 產出 Commit Message**

```text
refactor(poker_99): introduce GamePlayStrategy to decouple bot and online game flows

- Add GamePlayStrategy abstraction for core game flow actions
- Implement OnlineMultiplayerStrategy for Firestore-based gameplay
- Implement BotGameStrategy for local bot gameplay
- Remove _isBotPlaying branching logic from FirestorePoker99Controller
- Delegate game flow control to strategy implementations
- Improve extensibility for future game modes
- Include Task Specification: FEAT-POKER-99-CONTROLLER-007
```

---

## 補充：重要邏輯檢查（給你實作時用）

⚠️ **你現在這份 Controller 有一個潛在風險點（spec 已涵蓋，但實作時要注意）：**

```dart
startGame()
```

> 「是否切換策略」
> 應只做一次，避免：

* 已進入 BotGameStrategy 又被覆蓋
* 或重複 createRoom()

**建議實作時：**

* 在 Controller 明確設定 `_gamePlayStrategy = BotGameStrategy(...)`
* 並避免在 Strategy 內再切換 Strategy
