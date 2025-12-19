| **任務 ID (Task ID)** | `FEAT-BIG-TWO-DELEGATE-001` |
| **創建日期 (Date)** | `2025/12/19` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

分析 `lib/game_internals/big_two_delegate.dart` 的現狀，並定義實作完整大老二 (Big Two) 遊戲規則的規格。目前該檔案中的 `processAction` 僅為佔位符 (Placeholder)，且動作名稱 (Action Name) 與 Controller 定義不一致。

本任務目標是完善 `BigTwoDelegate`，使其能正確處理出牌 (`play_cards`) 與跳過 (`pass_turn`)，並包含必要的規則驗證。

### 2. 現狀分析 (Current State Analysis)

參考 `lib/game_internals/big_two_delegate.dart`：

1.  **初始化 (`initializeGame`)**: 已完成。能正確發牌並找出持有梅花 3 ('C3') 的起始玩家。
2.  **狀態查詢 (`getCurrentPlayer`, `getWinner`)**: 已完成。
3.  **動作處理 (`processAction`)**: **未完成**。
    *   目前代碼：
        ```dart
        if (action == 'play_hand') { ... }
        else if (action == 'pass') { ... }
        ```
    *   **問題點**:
        *   `FirestoreBigTwoController` (參考 `FEAT-FIRESTORE-BIG-TWO-CONTROLLER-001`) 發送的動作名稱為 `'play_cards'` 和 `'pass_turn'`。
        *   Delegate 目前監聽的是 `'play_hand'` 和 `'pass'`，導致前後端不匹配。
        *   缺乏驗證邏輯：沒有檢查牌型合法性、是否大過上家、是否為回合擁有者 (Free Turn)。

### 3. 需求規格 (Requirements)

#### 3.1. 動作名稱標準化
將 `processAction` 中的動作名稱統一修正為：
*   `'play_hand'` -> `'play_cards'`
*   `'pass'` -> `'pass_turn'`
*   新增 `'request_restart'` (處理重開局邏輯)

#### 3.2. 實作 `play_cards` 邏輯
當收到 `play_cards` 動作時，需執行以下驗證與更新：
1.  **權限檢查**: 確認 `currentPlayerId` 為發送者。
2.  **手牌檢查**: 確認玩家確實持有 payload 中聲明的卡牌。
3.  **規則驗證**:
    *   **首局首出**: 若是遊戲第一手 (`lastPlayedHand` 為空 且 `lastPlayedById` 為空)，出的牌必須包含梅花 3 ('C3')。
    *   **發球權 (Free Turn)**: 若 `lastPlayedById` 為自己 (或是上一輪所有人都 Pass)，可以出任意合法的牌型 (單張、對子、五張組合)。
    *   **跟牌 (Follow)**: 若非發球權，出的牌型必須與 `lastPlayedHand` 張數相同 (或符合大老二特定壓制規則)，且大小必須大於 `lastPlayedHand`。
4.  **狀態更新**:
    *   從玩家手牌移除該組牌。
    *   更新 `lastPlayedHand` 為出的牌。
    *   更新 `lastPlayedById` 為當前玩家。
    *   重置 `passCount` 為 0。
    *   **勝利判定**: 若玩家手牌為空，設定 `winner` 為該玩家。
    *   **輪替**: 計算並更新 `currentPlayerId` 為下一家。

#### 3.3. 實作 `pass_turn` 邏輯
當收到 `pass_turn` 動作時：
1.  **權限檢查**: 確認 `currentPlayerId` 為發送者。
2.  **規則驗證**:
    *   **不可 Pass**: 若當前擁有發球權 (`lastPlayedById` == 自身 或 遊戲剛開始)，**不允許 Pass**。
3.  **狀態更新**:
    *   `passCount` 加 1。
    *   更新 `currentPlayerId` 為下一家。
    *   **發球權轉移判定**: 若 `passCount` 達到 (玩家人數 - 1)，代表其他人都 Pass 了。下一位玩家 (即 `lastPlayedById` 或其繼承者) 將獲得發球權。
        *   *注意*: 為了簡化狀態顯示，通常不清空 `lastPlayedHand`，而是由 UI 判斷若 `lastPlayedById == currentPlayerId` 則視為新的一輪。

#### 3.4. 牌型比對邏輯 (Card Comparison Logic)
需實作輔助方法來比較牌的大小。
*   **點數 (Rank)**: 3 < 4 < 5 < ... < 10 < J < Q < K < A < 2。
*   **花色 (Suit)**: 梅花 (Clubs) < 方塊 (Diamonds) < 愛心 (Hearts) < 黑桃 (Spades)。 (依據台灣/常見大老二規則)

### 4. 建議實作範例 (`big_two_delegate.dart` 片段)

```dart
  @override
  BigTwoState processAction(BigTwoState currentState, String actionName, String participantId, Map<String, dynamic> payload) {
    // 0. 基礎檢查
    if (currentState.winner != null) return currentState;
    
    // 1. 處理重開局
    if (actionName == 'request_restart') {
        // ... (參考 TicTacToe 範例實作重開邏輯)
        return _processRestart(currentState, participantId);
    }

    // 2. 輪次檢查
    if (currentState.currentPlayerId != participantId) return currentState;

    // 3. 分派動作
    if (actionName == 'play_cards') {
      final cardsStr = List<String>.from(payload['cards'] ?? []);
      return _playCards(currentState, participantId, cardsStr);
    } else if (actionName == 'pass_turn') {
      return _passTurn(currentState, participantId);
    }

    return currentState;
  }

  BigTwoState _playCards(BigTwoState state, String playerId, List<String> cardsPlayed) {
    // A. 驗證手牌擁有權
    // B. 驗證梅花3規則 (第一手)
    // C. 驗證牌型與大小 (Is Valid Move?)
    
    // 若驗證通過:
    // 移除手牌, 更新 lastPlayedHand, reset passCount, 檢查 Winner, 換下一家
    // ...
  }

  BigTwoState _passTurn(BigTwoState state, String playerId) {
    // A. 驗證是否可以 Pass (不能是 Free Turn)
    if (state.lastPlayedById == playerId || (state.lastPlayedHand.isEmpty && state.lastPlayedById.isEmpty)) {
        return state;
    }
    
    // 更新 passCount, 換下一家
    // ...
  }
```

### 5. 驗證計畫
1.  **單元測試**: 針對 `BigTwoDelegate` 撰寫測試。
    *   測試第一手未出梅花 3 被拒絕。
    *   測試小牌壓大牌被拒絕。
    *   測試 Pass 後權限轉移。
    *   測試 3 家 Pass 後，第 4 家獲得出牌權。
2.  **整合測試**: 配合 `FirestoreBigTwoController` 進行模擬對局。
