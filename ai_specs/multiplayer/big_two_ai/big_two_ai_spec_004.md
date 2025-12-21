| **任務 ID (Task ID)** | `FEAT-BIG-TWO-AI-004` |
| **創建日期 (Date)** | `2025/12/21` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

建立 `lib/multiplayer/big_two_ai/big_two_play_cards_ai.dart`。
目前的 AI 實作僅是一個只會 Pass 或出第一張牌的 Dummy。
目標是建立一個能夠利用 `BigTwoDelegate` 提供的規則運算能力，根據當前牌局狀態 (Free Turn 或 Locked Turn) 計算出合法且最佳的出牌組合的 AI。

### 2. 需求規格 (Requirements)

#### 2.1. 引入 BigTwoDelegate
*   在 `BigTwoPlayCardsAI` 類別中，實例化一個 `BigTwoDelegate` 物件作為私有成員，用於輔助運算（例如檢查合法性、比大小、尋找牌型）。
    ```dart
    final BigTwoDelegate _delegate = BigTwoDelegate();
    ```
*   **注意**: 原本傳給 `FirestoreTurnBasedGameController` 的 `delegate` 參數若為 `BigTwoAIDelegate` (Dummy)，建議改為功能完整的 `BigTwoDelegate`，以確保 Controller 內部的狀態預測與邏輯一致。

#### 2.2. 重構 `_performTurnAction`
*   移除原有的寫死邏輯 (Dummy logic)。
*   流程改為：
    1.  解析手牌：將 `myPlayer.cards` (String List) 轉換為 `List<PlayingCard>`。
    2.  計算出牌：呼叫新方法 `_findBestMove(state, handCards)`。
    3.  執行動作：
        *   若回傳 `List<String>` (不為空)，則發送 `play_cards`，payload 包含該列表。
        *   若回傳 `null`，則發送 `pass_turn`。

#### 2.3. 實作 `_findBestMove` 核心邏輯
建立 `List<String>? _findBestMove(BigTwoState state, List<PlayingCard> hand)` 方法，回傳建議出的牌 (字串列表)，若無牌可出則回傳 `null`。

邏輯判斷流程：
1.  **判斷是否為首局首手 (First Turn)**:
    *   條件：`state.lastPlayedHand` 為空 且 `state.lastPlayedById` 為空。
    *   限制：出的牌組合中**必須包含梅花 3 (C3)**。

2.  **判斷牌局狀態**:
    *   **Case A: 自由出牌 (Free Turn)** (自己是上一手出牌者 或 沒人出過牌)
        *   依序嘗試尋找以下牌型組合，一旦找到合法組合即選用 (Greedy Strategy: 優先出大牌型或是多張牌型以減少手牌數)：
            1.  **Straight Flush** (呼叫 `_delegate.findStraightFlushes`)
            2.  **Four of a Kind** (呼叫 `_delegate.findFourOfAKinds`)
            3.  **Full House** (呼叫 `_delegate.findFullHouses`)
            4.  **Straight** (呼叫 `_delegate.findStraights`)
            5.  **Pair** (呼叫 `_delegate.findPairs`)
            6.  **Single** (呼叫 `_delegate.findSingles`)
        *   **策略**: 在該牌型找到的所有組合中，選擇**數字最小**的一組打出 (保留大牌)。
        *   *C3 限制*: 若為首手，過濾掉不含 C3 的組合。

    *   **Case B: 跟牌/壓牌 (Restricted Turn)**
        *   取得 `state.lockedHandType`。
        *   根據 `lockedHandType` 呼叫對應的 `finder` (例如 Locked='Pair' -> `findPairs`)。
        *   **過濾**: 使用 `_delegate.isBeating` 檢查候選組合是否大於 `state.lastPlayedHand`。
        *   **策略**: 在可贏的組合中，選擇**數字最小**的一組。
        *   **Bomb 邏輯**: 暫不實作複雜的 Bomb 搜尋 (如用鐵支壓順子)，除非 `lockedHandType` 本身就是 `FourOfAKind` 或 `StraightFlush` 則需比大小。本次實作專注於「同牌型壓制」。

#### 2.4. 實作細節與 helper 方法
*   需確保使用 `BigTwoDeckUtilsMixin` (透過 `_delegate` 存取) 的 `find...` 方法。
*   轉換：`PlayingCard` 轉回 `String` 時需使用 `card.toString()` (假設格式為 `C3`, `D10` 等，需確認 `PlayingCard` 實作)。

### 3. 程式碼邏輯範例 (Pseudo Code)

```dart
List<String>? _findBestMove(BigTwoState state, List<PlayingCard> hand) {
  final isFreeTurn = state.lastPlayedById == _aiUserId || (state.lastPlayedHand.isEmpty && state.lastPlayedById.isEmpty);
  // 檢查是否為遊戲開始的第一手 (需出梅花3)
  final isFirstTurnOfGame = state.lastPlayedHand.isEmpty && state.lastPlayedById.isEmpty;
  final mustContainC3 = isFirstTurnOfGame;

  if (isFreeTurn) {
    // 定義優先順序
    final finders = [
      _delegate.findStraightFlushes,
      _delegate.findFourOfAKinds,
      _delegate.findFullHouses,
      _delegate.findStraights,
      _delegate.findPairs,
      _delegate.findSingles,
    ];

    for (final finder in finders) {
      var candidates = finder(hand);
      
      // 若需包含 C3
      if (mustContainC3) {
        candidates = candidates.where((c) => c.any((card) => card.suit == CardSuit.clubs && card.value == 3)).toList();
      }

      if (candidates.isNotEmpty) {
        // 選擇最小的一組 (假設 finder 回傳已排序，或在此排序)
        // 這裡簡單取第一個 (通常是最小的，視 find 實作而定)
        return candidates.first.map((c) => c.toString()).toList();
      }
    }
  } else {
    // Locked Turn
    if (state.lockedHandType.isEmpty) return null; // Should not happen if not free turn

    final lockedType = BigTwoCardPattern.fromJson(state.lockedHandType);
    List<List<PlayingCard>> candidates = [];

    switch (lockedType) {
      case BigTwoCardPattern.single:
        candidates = _delegate.findSingles(hand);
        break;
      case BigTwoCardPattern.pair:
        candidates = _delegate.findPairs(hand);
        break;
      case BigTwoCardPattern.straight:
        candidates = _delegate.findStraights(hand);
        break;
      case BigTwoCardPattern.fullHouse:
        candidates = _delegate.findFullHouses(hand);
        break;
      case BigTwoCardPattern.fourOfAKind:
        candidates = _delegate.findFourOfAKinds(hand);
        break;
      case BigTwoCardPattern.straightFlush:
        candidates = _delegate.findStraightFlushes(hand);
        break;
    }
    
    // 過濾出能贏的牌
    final validMoves = candidates.where((cards) {
       return _delegate.isBeating(
         cards.map((c) => c.toString()).toList(), 
         state.lastPlayedHand, 
         lockedType
       );
    }).toList();

    if (validMoves.isNotEmpty) {
      return validMoves.first.map((c) => c.toString()).toList();
    }
  }
  
  return null; // Pass
}
```

### 4. 驗證計畫
*   觀察 Log: AI 應印出 `AI {uid} playing: [cards...]` 而非總是 Pass。
*   情境測試:
    1.  AI 持有 C3，開局應出包含 C3 的牌。
    2.  Free Turn 時，若手牌有 順子 與 單張，應優先出 順子。
    3.  Locked Turn (Pair)，應出比上家大的 Pair。
    4.  Locked Turn (Pair)，若無大牌則 Pass。

### 邏輯檢查與建議
1.  **C3 規則**: 必須嚴格檢查 `mustContainC3` 邏輯。
2.  **牌型轉換**: 確認 `PlayingCard.toString()` 格式與 Server 一致。
3.  **Delegate**: 建議直接替換 `BigTwoAIDelegate` 為 `BigTwoDelegate`，減少維護兩個 Delegate 的成本。
