| **任務 ID (Task ID)** | `FEAT-BIG-TWO-BOARD-WIDGET-BIGTWO-006` |
| **創建日期 (Date)** | `2025/12/19` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

修改 `lib/play_session/big_two_board_widget.dart`，將原本直接使用的 `FirestoreTurnBasedGameController<BigTwoState>` 替換為專用的 `FirestoreBigTwoController` (定義於 `lib/multiplayer/firestore_big_two_controller.dart`)。
這將統一遊戲邏輯的入口，並利用 `FirestoreBigTwoController` 提供的封裝方法（如 `matchRoom`, `playCards`）來操作遊戲，而非直接發送原始的 Action 字串。

### 2. 設計思路 (Design Approach)

1.  **控制器替換**:
    *   將 `BigTwoBoardWidget` 中的 `_gameController` 型別改為 `FirestoreBigTwoController`。
    *   在 `initState` 中初始化 `FirestoreBigTwoController`，注入 `FirebaseFirestore`, `FirebaseAuth` 和 `SettingsController`。
2.  **UI 邏輯適配**:
    *   **配對 (Match)**: 當 `gameStateStream` 為 `null` 或不在遊戲中時，顯示 "Match Room" 按鈕，點擊後呼叫 `_controller.matchRoom()`。
    *   **出牌 (Play)**: 將 "Play" 按鈕的點擊事件改為呼叫 `_controller.playCards(_player.selectedCards)`。
    *   **Pass**: 雖然目前的 UI 可能沒有 Pass 按鈕，但若有，應使用 `_controller.passTurn()`。
3.  **依賴維持**:
    *   `BigTwoBoardWidget` 目前使用本地的 `BigTwoDelegate` (`_bigTwoManager`) 來解析 `BigTwoState` 並獲取 `myPlayer` 和 `otherPlayers` 的資訊。由於 `FirestoreBigTwoController` 未公開這些 UI 輔助方法，此本地 Delegate 實例應保留，僅用於 UI 渲染，不參與遊戲控制。

### 3. 核心實作 (`big_two_board_widget.dart`)

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/game_internals/big_two_delegate.dart';
import 'package:ok_multipl_poker/game_internals/card_player.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_big_two_controller.dart'; // Import FirestoreBigTwoController
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';
import 'package:ok_multipl_poker/play_session/show_only_card_area_widget.dart';
import 'package:ok_multipl_poker/style/my_button.dart';
import 'package:ok_multipl_poker/play_session/selectable_player_hand_widget.dart';
import '../settings/settings.dart';

class BigTwoBoardWidget extends StatefulWidget {
  const BigTwoBoardWidget({super.key});

  @override
  State<BigTwoBoardWidget> createState() => _BigTwoBoardWidgetState();
}

class _BigTwoBoardWidgetState extends State<BigTwoBoardWidget> {
  // 使用 FirestoreBigTwoController
  late final FirestoreBigTwoController _gameController;
  final CardPlayer _player = CardPlayer();
  // 保留本地 Delegate 用於 UI 解析 (myPlayer, otherPlayers)
  final _bigTwoManager = BigTwoDelegate(); 
  late final String _userId;

  bool _isMatching = false;

  @override
  void initState() {
    super.initState();

    final auth = context.read<FirebaseAuth>();
    final store = context.read<FirebaseFirestore>();
    final settings = context.read<SettingsController>();
    
    _userId = auth.currentUser!.uid;
    
    // 初始化 FirestoreBigTwoController
    _gameController = FirestoreBigTwoController(
      firestore: store,
      auth: auth,
      settingsController: settings,
    );
  }

  @override
  void dispose() {
    _gameController.dispose();
    _player.dispose();
    super.dispose();
  }
  
  Future<void> _onMatchRoom() async {
    setState(() {
      _isMatching = true;
    });
    await _gameController.matchRoom();
    // matchRoom 完成後，Stream 應會更新狀態
    if (mounted) {
      setState(() {
        _isMatching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TurnBasedGameState<BigTwoState>?>(
      stream: _gameController.gameStateStream,
      builder: (context, snapshot) {
        final gameState = snapshot.data;

        // 若無狀態或不在遊戲中，顯示配對介面
        if (gameState == null || gameState.gameStatus == GameStatus.matching) {
           return Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 if (_isMatching || (gameState?.gameStatus == GameStatus.matching))
                   const Text('配對中 / 等待玩家...')
                 else
                   const Text('準備開始大老二'),
                 const SizedBox(height: 20),
                 if (!_isMatching && gameState == null)
                   ElevatedButton(
                     onPressed: _onMatchRoom, 
                     child: const Text('開始配對 (Match Room)'),
                   ),
                 if (gameState != null && gameState.gameStatus == GameStatus.matching)
                   const CircularProgressIndicator(),
               ],
             ),
           );
        }

        // 遊戲進行中 (Playing) 或 結束 (Finished)
        final bigTwoState = gameState.customState;

        // 更新本地玩家手牌 UI 狀態
        // 注意：需確保 _bigTwoManager 的邏輯與後端一致
        final myPlayerState = _bigTwoManager.myPlayer(_userId, bigTwoState);
        _player.name = myPlayerState.name;
        // 將 String 轉回 PlayingCard 供 CardPlayer 使用
        _player.replaceWith(myPlayerState.cards.map((c) => PlayingCard.fromString(c)).toList());

        // ... (HandType Buttons 邏輯保持不變) ...
        const handTypes = ['Single', 'Pair', 'Full House', 'Straight', 'Straight Flush'];
        final handTypeButtons = handTypes
            .map((type) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: OutlinedButton(
                    onPressed: () { /* TODO: Implement filters or hints */ },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(type),
                  ),
                ))
            .toList();

        final otherPlayers = _bigTwoManager.otherPlayers(_userId, bigTwoState);
        final edgeSize = 50.0;
        
        // 判斷是否輪到我
        final isMyTurn = gameState.currentPlayerId == _userId;

        return Scaffold(
          body: Stack(
            children: [
              // --- 桌面區域 (Last Played Hand) ---
              Positioned.fromRelativeRect(
                rect: RelativeRect.fromLTRB(edgeSize, edgeSize, edgeSize, edgeSize),
                child: Align(
                  alignment: Alignment.center,
                  child: ShowOnlyCardAreaWidget(
                    cards: bigTwoState.lastPlayedHand.map((c) => PlayingCard.fromString(c)).toList(),
                  ),
                ),
              ),
              
              // --- 對手區域 ---
              if (otherPlayers.isNotEmpty)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: _OpponentHand(
                      cardCount: otherPlayers[0].cards.length,
                      playerName: otherPlayers[0].name,
                    ),
                  ),
                ),
              if (otherPlayers.length > 1)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: _OpponentHand(
                        cardCount: otherPlayers[1].cards.length,
                        playerName: otherPlayers[1].name,
                      ),
                    ),
                  ),
                ),
              if (otherPlayers.length > 2)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: _OpponentHand(
                        cardCount: otherPlayers[2].cards.length,
                        playerName: otherPlayers[2].name,
                      ),
                    ),
                  ),
                ),

              // --- 玩家手牌區域 ---
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: ChangeNotifierProvider.value(
                    value: _player,
                    child: SelectablePlayerHandWidget(
                      buttonWidgets: handTypeButtons,
                    ),
                  ),
                ),
              ),

              // --- 操作按鈕區域 (Play / Pass) ---
              Positioned(
                bottom: 40,
                right: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pass 按鈕
                    if (isMyTurn)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                          onPressed: () {
                            _gameController.passTurn();
                          },
                          child: const Text('Pass'),
                        ),
                      ),
                    // Play 按鈕
                    MyButton(
                      onPressed: isMyTurn ? () {
                        final selectedCards = _player.selectedCards;
                        if (selectedCards.isNotEmpty) {
                          // 使用 FirestoreBigTwoController 直接出牌
                          _gameController.playCards(selectedCards);
                          // 出牌後清除選擇
                          _player.clearSelection();
                        }
                      } : null, // 非回合時禁用
                      child: const Text('Play'),
                    ),
                  ],
                ),
              ),
              
              // --- 狀態提示 ---
              if (gameState.gameStatus == GameStatus.finished)
                Center(
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Winner: ${gameState.winner}',
                          style: const TextStyle(color: Colors.white, fontSize: 24),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _gameController.restart();
                          },
                          child: const Text('Restart'),
                        ),
                        TextButton(
                           onPressed: () {
                             _gameController.leaveRoom();
                           },
                           child: const Text('Leave', style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// _OpponentHand 類別保持不變
// ...
```

### 4. 邏輯檢查與改善建議 (Logic Analysis & Recommendations)

#### 4.1. `BigTwoDelegate` 的一致性
*   `BigTwoBoardWidget` 內部實例化的 `BigTwoDelegate` (`package:ok_multipl_poker/game_internals/big_two_delegate.dart`) 必須與 `FirestoreBigTwoController` 內部使用的 Delegate 邏輯保持一致（特別是 `myPlayer` 等資料解析邏輯）。如果 `FirestoreBigTwoController` 內部使用的是另一個定義在該文件中的 `BigTwoDelegate`，請確保兩者行為一致，或者考慮重構讓 Controller 公開其 Delegate 或 State 解析器。
*   **建議**: 長期而言，應將 `BigTwoDelegate` 統一為一個類別檔案。

#### 4.2. Action Name 修正
*   原程式碼使用 `play_hand`，但 `FirestoreBigTwoController` 實作的方法是發送 `play_cards`。本次修改已修正為呼叫 `_gameController.playCards()`，這將確保 Action Name 與後端/Controller 一致。

#### 4.3. 房間 ID 處理
*   `FirestoreBigTwoController` 目前僅提供 `matchRoom()` (自動配對)。若此 Widget 需要支援「加入特定房間」或「重連」，控制器需要擴充 `setRoomId` 方法。目前的 Spec 假設 Widget 是用於配對後遊玩，因此使用 `matchRoom` 流程是合理的。
