| **任務 ID (Task ID)** | `FEAT-BIG-TWO-DELEGATE-003` |
| **創建日期 (Date)** | `2025/12/20` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

修改 `BigTwoState` 以支援中央棄牌堆 (`deckCards`) 與鎖定牌型 (`lockedHandType`) 的記錄，並重構 `BigTwoDelegate` 中的 `processAction` 邏輯，包含 `nextTurn`、`pass_turn` 與 `playCards` 的具體實作，確保回合輪替與狀態更新符合規則。

### 2. 需求規格 (Requirements)

#### 2.1. 修改實體 `BigTwoState`
在 `lib/entities/big_two_state.dart` 中新增以下欄位：
1.  `final List<String> deckCards;`
    *   **用途**: 記錄中央棄牌堆（所有已出的牌）。
    *   **預設值**: `[]` (空列表)。
2.  `final String lockedHandType;`
    *   **用途**: 表示目前回合鎖定的牌型（例如："Single", "Pair", "FullHouse" 等，視具體牌型判斷邏輯而定）。
    *   **預設值**: `""` (空字串)。

*注意*: 需同步更新 `BigTwoState` 的建構子 (`constructor`)、`copyWith`、`fromJson` 與 `toJson` 方法。

#### 2.2. 修改 `BigTwoDelegate` 邏輯

在 `lib/game_internals/big_two_delegate.dart` 中，更新 `processAction` 及其輔助方法以實現以下邏輯：

##### A. 輔助邏輯 `_nextTurn` (或整合於流程中)
當需要切換到下一位玩家時：
1.  **計算下一位玩家**:
    *   呼叫 `BigTwoState` 的 `nextPlayerId()` 方法取得 `nextUid`。
    *   更新 `currentPlayerId` 為 `nextUid`。
2.  **新回合判定 (New Trick Reset)**:
    *   檢查 `passCount` 是否達到 `seats.length - 1` (即除了最後出牌者外，其他人都 Pass 了)。
    *   **若條件成立**:
        *   將 `participants` 中所有玩家的 `hasPassed` 屬性重置為 `false`。
        *   將 `lockedHandType` 重置為 `""`。
        *   將 `passCount` 也應重置為 0，且 `lastPlayedHand` 雖保留顯示但邏輯上視為新局。

##### B. 重寫 `pass_turn` 動作邏輯
當收到 `pass_turn` 動作且驗證合法後：
1.  **更新 Pass 狀態**:
    *   將 `passCount` 加 1。
    *   找出當前玩家 (`currentPlayer`)，將其 `hasPassed` 屬性設為 `true`。
2.  **輪替**:
    *   執行上述 `nextTurn` 邏輯。

##### C. 重寫 `playCards` 動作邏輯
當收到 `play_cards` 動作且驗證合法後：
1.  **手牌更新**:
    *   從當前玩家的 `cards` 中移除 `cardsPlayed`。
2.  **棄牌堆更新**:
    *   將 `cardsPlayed` 加入到 `deckCards` 中。
3.  **狀態更新**:
    *   更新 `lastPlayedHand` 為 `cardsPlayed`。
    *   更新 `lastPlayedById` 為當前玩家 ID。
    *   根據出的牌更新 `lockedHandType` (若為新的一輪)。
    *   重置 `passCount` 為 0。
4.  **輪替**:
    *   執行上述 `nextTurn` 邏輯。

### 3. 實作建議 (Implementation Details)

```dart
// BigTwoState 修改示意
@JsonSerializable(explicitToJson: true)
class BigTwoState {
  // ... 原有欄位
  final List<String> deckCards;
  final String lockedHandType;

  BigTwoState({
    // ...
    this.deckCards = const [],
    this.lockedHandType = '',
  });
  
  // copyWith, fromJson, toJson 需對應更新
}
```

```dart
// BigTwoDelegate 修改示意
BigTwoState _passTurn(BigTwoState state, String playerId) {
    // 1. Update Pass Count and Player Status
    int newPassCount = state.passCount + 1;
    
    List<BigTwoPlayer> newParticipants = state.participants.map((p) {
      if (p.uid == playerId) {
        return p.copyWith(hasPassed: true);
      }
      return p;
    }).toList();

    // 2. Prepare intermediate state
    BigTwoState tempState = state.copyWith(
      passCount: newPassCount,
      participants: newParticipants,
    );

    // 3. Next Turn Logic
    return _nextTurn(tempState);
}

BigTwoState _playCards(BigTwoState state, String playerId, List<String> cardsPlayed) {
    // ... (Validation logic) ...

    // 1. Update Player Hand
    List<BigTwoPlayer> newParticipants = state.participants.map((p) {
        if (p.uid == playerId) {
            List<String> newCards = List.from(p.cards)..removeWhere((c) => cardsPlayed.contains(c));
            return p.copyWith(cards: newCards); // Note: hasPassed remains false or explicitly false
        }
        return p;
    }).toList();

    // 2. Update Deck and Game Info
    List<String> newDeckCards = List.from(state.deckCards)..addAll(cardsPlayed);
    
    // Determine new locked hand type if needed
    // String newHandType = ... 

    BigTwoState tempState = state.copyWith(
        participants: newParticipants,
        deckCards: newDeckCards,
        lastPlayedHand: cardsPlayed,
        lastPlayedById: playerId,
        passCount: 0, 
        // lockedHandType: newHandType
    );

    // 3. Next Turn Logic
    return _nextTurn(tempState);
}

BigTwoState _nextTurn(BigTwoState state) {
    String? nextPid = state.nextPlayerId();
    if (nextPid == null) return state; // Should handle game over or error

    String nextPlayerId = nextPid;
    List<BigTwoPlayer> participants = state.participants;
    String lockedHandType = state.lockedHandType;
    int passCount = state.passCount;

    // Check if everyone else passed (Round Over / Free Turn for next player)
    if (passCount >= state.seats.length - 1) {
        // Reset hasPassed for all
        participants = participants.map((p) => p.copyWith(hasPassed: false)).toList();
        lockedHandType = "";
        // passCount = 0; // Optional: Reset pass count here or keep it high until play occurs? 
                         // Usually playCards resets it. If passCount is high, the next player (winner of trick) has control.
    }

    return state.copyWith(
        currentPlayerId: nextPlayerId,
        participants: participants,
        lockedHandType: lockedHandType,
        // passCount: passCount
    );
}
```

### 4. 驗證 (Verification)
*   檢查 `BigTwoState.g.dart` 是否正確重新生成。
*   測試 `playCards` 後，牌是否從手牌移至 `deckCards`。
*   測試 `pass_turn` 後，玩家 `hasPassed` 是否變為 `true`。
*   測試當 N-1 名玩家 Pass 後，下一位玩家獲得出牌權，且 `lockedHandType` 重置，所有玩家 `hasPassed` 重置。
