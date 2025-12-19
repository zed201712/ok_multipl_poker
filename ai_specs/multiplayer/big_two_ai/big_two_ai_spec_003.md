| **任務 ID (Task ID)** | `FEAT-BIG-TWO-AI-003` |
| **創建日期 (Date)** | `2025/12/19` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

本任務旨在修正 `BigTwoAI` 重複發送請求的問題。
目前 AI 在每次收到 `gameState` 更新且輪到自己時，都會無條件觸發 `_performTurnAction`。
如果發送請求後，狀態尚未更新（或更新後仍是 AI 回合，雖然這在大老二不太可能發生，除非發球權未轉移），AI 可能會因為 `gameStateStream` 的多次推送（例如因為其他欄位變動）而再次觸發動作。
此外，`await Future.delayed` 之後沒有再次檢查狀態是否已改變，可能導致重複提交。

### 2. 問題分析 (Analysis)

1.  **Stream 觸發頻率**: `_onGameStateUpdate` 在每次 `gameStateStream` 更新時都會被呼叫。即使狀態看似相同，Stream 也可能推送新的事件。
2.  **非同步間隙**: `_performTurnAction` 內有一個 `1000ms` 的延遲。在這個延遲期間，如果 Stream 又推送了一次（例如因為其他玩家斷線、聊天訊息等導致 Room 更新，進而觸發 Controller 的 Stream），`_performTurnAction` 會被再次呼叫。
3.  **狀態檢查不足**: AI 只檢查 `currentPlayerId == _aiUserId`。如果 AI 發送了 Pass，但在 Server 處理完畢前，狀態仍顯示 AI 是當前玩家，AI 會再次發送 Pass。

### 3. 設計思路 (Design Approach)

1.  **引入 `_isProcessingTurn` 旗標**:
    *   在 `_performTurnAction` 開始時設為 `true`。
    *   在動作完成（或失敗）後設為 `false`。
    *   在進入 `_performTurnAction` 前，若 `_isProcessingTurn` 為 `true`，則直接忽略。

2.  **動作執行後檢查**:
    *   在 `await Future.delayed` 之後，再次檢查 `gameState` 是否仍然輪到自己（雖然 `_isProcessingTurn` 能防止重入，但若有新的狀態更新進來，仍需確認當前狀態是否依然有效）。
    *   不過，更簡單且有效的方式是依賴 `_isProcessingTurn` 來鎖定「思考與行動」這個原子操作。只要 AI 正在「思考」或「提交」，就不應啟動新的思考流程。

3.  **防止重複重啟請求**:
    *   雖然現有代碼已有檢查 `alreadyRequested`，但為了保險，也可對重啟請求加入類似的防重入機制，或簡單地依賴狀態判斷。

### 4. 核心實作 (`big_two_ai.dart`)

```dart
// 在 BigTwoAI 類別中新增狀態變數
bool _isProcessingTurn = false;

// 修改 _onGameStateUpdate
void _onGameStateUpdate(TurnBasedGameState<BigTwoState>? gameState) {
  if (_isDisposed || gameState == null) return;

  // 1. 處理出牌
  if (gameState.gameStatus == GameStatus.playing &&
      gameState.currentPlayerId == _aiUserId) {
    
    // 如果正在處理回合，則跳過，避免重複發送
    if (_isProcessingTurn) return;

    _performTurnAction(gameState.customState);
  }

  // 2. 處理遊戲結束 -> 請求重開
  if (gameState.gameStatus == GameStatus.finished) {
    final alreadyRequested = gameState.customState.restartRequesters.contains(_aiUserId);
    if (!alreadyRequested) {
      // 簡單防抖動或檢查
      // 這裡不一定需要 _isProcessingTurn，因為 finished 狀態下通常不涉及回合操作
      // 但為了避免多次 timer，可以加一個 flag 或 timer check
      // 由於這是一次性的，保持原樣或加上防重複調度即可。
      // 現有邏輯: Future.delayed 後檢查，但若多次觸發會有多個 Timer。
      // 簡單解法：這裡暫不變動，專注於 Turn Action。
      
      // 不過，為了嚴謹，我們可以檢查是否已有 Timer 在跑。
      // 為了簡化，本次任務專注解決 "重複傳送 Pass/Play" 的問題。
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!_isDisposed && !_controller.currentRoomState?.restartRequesters.contains(_aiUserId)) { 
           // 需注意: 這裡的 condition 需能取得最新狀態，但 _controller 未必 expose。
           // 保持原樣風險較低，因為後端通常冪等處理 restart request。
           _gameController.sendGameAction('request_restart');
        }
      });
    }
  }
}

Future<void> _performTurnAction(BigTwoState state) async {
  if (_isProcessingTurn) return;
  _isProcessingTurn = true;

  try {
    // 模擬思考時間
    await Future.delayed(const Duration(milliseconds: 1000));
    if (_isDisposed) return;

    // 再次檢查是否仍輪到自己 (防止在 delay 期間狀態改變，例如被踢出或遊戲強制結束)
    // 由於 state 是舊的，我們應該檢查最新的 controller state 嗎？
    // _gameController.gameStateStream.value 含有最新狀態
    final currentGameState = _gameController.gameStateStream.valueOrNull;
    if (currentGameState?.currentPlayerId != _aiUserId) {
       _log.info('AI $_aiUserId turn cancelled (state changed during think time)');
       return;
    }
    
    // 使用最新的 state 進行判斷
    final currentState = currentGameState!.customState;
    final isFreeTurn = currentState.lastPlayedPlayerId == _aiUserId || currentState.lastPlayedPlayerId.isEmpty;
    
    if (isFreeTurn) {
        // ... (原有的出牌邏輯)
        final myPlayer = currentState.participants.firstWhere((p) => p.uid == _aiUserId, orElse: () => BigTwoPlayer(uid: _aiUserId, name: '', cards: []));
         if (myPlayer.cards.isNotEmpty) {
           String cardToPlayStr = myPlayer.cards.first;
           
           final isGameStart = currentState.lastPlayedHand.isEmpty && currentState.lastPlayedById.isEmpty;
           if (isGameStart) {
             final c3 = myPlayer.cards.firstWhere((c) => c == 'C3', orElse: () => '');
             if (c3.isNotEmpty) cardToPlayStr = c3;
           }
           
           _log.info('AI $_aiUserId MUST play. Playing: $cardToPlayStr');
           await _gameController.sendGameAction('play_cards', payload: {'cards': [cardToPlayStr]});
         }
    } else {
       // Pass
       _log.info('AI $_aiUserId choosing to PASS');
       await _gameController.sendGameAction('pass_turn');
    }
  } catch (e) {
    _log.warning('AI failed to perform action', e);
  } finally {
    // 無論成功與否，都要釋放鎖，但建議加一點冷卻，以免 Server 回應慢導致 AI 以為沒反應又重試？
    // 不，一旦送出 request，狀態應該會變 (輪到別人)，所以下一次 update 來時 currentPlayerId 就不會是自己。
    // 除非 request 失敗。
    _isProcessingTurn = false;
  }
}
```

### 5. 改善建議

1.  **使用 `valueOrNull`**: `RxDart` 的 `ValueStream` 提供了 `valueOrNull` (或 `value`)，可以在 `Future.delayed` 後獲取最新狀態，這比使用傳入的舊 `state` 更安全。
2.  **`_isProcessingTurn` 鎖**: 這是防止重複請求的關鍵。
3.  **冪等性**: 雖然前端做了防護，後端邏輯也應具備冪等性（如果不是當前玩家，拒絕請求），這在 `BigTwoDelegate` 中已有檢查。但 AI 減少發送垃圾請求能減輕 Log 和網路負擔。

此修改將顯著減少 AI 的重複操作 Log。
