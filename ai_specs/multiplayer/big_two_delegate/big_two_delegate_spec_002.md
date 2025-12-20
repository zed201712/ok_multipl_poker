| **任務 ID (Task ID)** | `FEAT-BIG-TWO-DELEGATE-002` |
| **創建日期 (Date)** | `2025/12/20` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

根據 `FEAT-BIG-TWO-DELEGATE-001` 的分析與規格，實作 `lib/game_internals/big_two_delegate.dart` 中的完整大老二遊戲邏輯。重點在於將目前的佔位符方法 (`processAction`) 替換為實際的規則驗證與狀態更新邏輯。

### 2. 實作範圍 (Implementation Scope)

#### 2.1. 動作處理標準化
修改 `processAction` 方法以支援下列動作名稱（與 `FirestoreBigTwoController` 一致）：
*   `request_restart`: 處理重開局請求。
*   `play_cards`: 處理玩家出牌。
*   `pass_turn`: 處理玩家跳過回合。

#### 2.2. 核心邏輯實作

需實作下列私有方法或輔助邏輯：

1.  **`_processRestartRequest`**:
    *   更新 `restartRequesters` 清單。
    *   若所有玩家皆請求重開，則呼叫 `_initializeGame` (或類似邏輯) 重置遊戲狀態。

2.  **`_playCards`**:
    *   **驗證**:
        *   檢查是否輪到該玩家。
        *   檢查玩家手牌是否包含出的牌。
        *   **第一手限制**: 若是開局第一手，必須包含梅花 3 ('C3')。
        *   **牌型與大小驗證**:
            *   若為 **Free Turn** (發球權)，允許任意合法牌型。
            *   若為 **Follow** (跟牌)，牌型需與上一手相同且點數更大。
    *   **更新**:
        *   從玩家手牌移除出的牌。
        *   更新 `lastPlayedHand` 與 `lastPlayedById`。
        *   重置 `passCount` 為 0。
        *   **勝利判定**: 若手牌為空，設定 `winner`。
        *   **切換回合**: 計算下一位玩家 ID。

3.  **`_passTurn`**:
    *   **驗證**: 若當前玩家擁有發球權（`lastPlayedById` 是自己，或遊戲剛開始），則**不可 Pass**。
    *   **更新**:
        *   `passCount` + 1。
        *   切換回合至下一位玩家。
        *   若 `passCount` 達 (玩家數-1)，雖然不需要特別清空 `lastPlayedHand` (視 UI 實作而定)，但下一位玩家將自動獲得 Free Turn 權限（因為 `lastPlayedById` 會是他自己或上一位出牌者，且輪回他時 `passCount` 的邏輯需確保他能出任意牌）。

#### 2.3. 牌型驗證輔助 (Card Logic Helpers)

為了支援上述邏輯，需實作或引用下列輔助功能 (可視情況放在 `PlayingCard` extension 或 Delegate 內部)：
*   **牌型識別**: 單張 (Single), 對子 (Pair), 順子 (Straight), 同花 (Flush), 葫蘆 (Full House), 鐵支 (Quads), 同花順 (Straight Flush)。
*   **大小比較**:
    *   點數: 3 < 4 < ... < 10 < J < Q < K < A < 2。
    *   花色: 梅花 < 方塊 < 紅心 < 黑桃。

### 3. 程式碼結構參考

```dart
class BigTwoDelegate extends TurnBasedGameDelegate<BigTwoState> {
  // ... initializeGame, stateFromJson, stateToJson 等保持或微調 ...

  @override
  BigTwoState processAction(BigTwoState currentState, String actionName, String participantId, Map<String, dynamic> payload) {
    if (currentState.winner != null && actionName != 'request_restart') return currentState;

    if (actionName == 'request_restart') {
      return _processRestartRequest(currentState, participantId);
    }

    // 驗證輪次
    if (currentState.currentPlayerId != participantId) return currentState;

    if (actionName == 'play_cards') {
      final cardsStr = List<String>.from(payload['cards'] ?? []);
      return _playCards(currentState, participantId, cardsStr);
    } else if (actionName == 'pass_turn') {
      return _passTurn(currentState, participantId);
    }

    return currentState;
  }

  // ... 實作 _processRestartRequest, _playCards, _passTurn ...
  
  // ... 實作牌型驗證與比較邏輯 ...
}
```

### 4. 驗證標準
執行單元測試或整合測試，確認：
1.  第一手未出梅花 3 應無效。
2.  持有發球權時 Pass 應無效。
3.  小牌壓大牌應無效。
4.  合法出牌後，手牌減少，輪次切換。
5.  三家 Pass 後，發球權正確回到最後出牌者。
