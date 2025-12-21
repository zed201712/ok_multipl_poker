| **任務 ID (Task ID)** | `FEAT-BIG-TWO-BOARD-WIDGET-BIGTWO-007` |
| **創建日期 (Date)** | `2025/12/21` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

修改 `lib/play_session/big_two_board_widget.dart` 以增強遊戲狀態的視覺提示，包括標示當前回合玩家以及分開顯示「上一次出的牌 (Last Played Hand)」與「桌面牌堆 (Deck/Table Cards)」。

### 2. 設計思路 (Design Approach)

1.  **標示對手當前回合**:
    *   修改 `_otherPlayerWidgets` 方法。
    *   在生成對手 Widget 時，判斷該對手 (`uid`) 是否為 `BigTwoState` 中的 `currentPlayerId`。
    *   如果是當前回合玩家，將其名字 (`playerName`) 的顏色改為醒目顏色 (例如 `Colors.amber` 或 `Colors.red`)，否則保持預設顏色。

2.  **標示自己當前回合**:
    *   在 `// --- 玩家手牌區域 ---` (即 `SelectablePlayerHandWidget` 上方)。
    *   增加一個條件式 Widget (例如 `Text` 或 `Container` 標籤)，當 `_userId == bigTwoState.currentPlayerId` 時顯示 "Your Turn" 或類似提示，讓玩家明確知道輪到自己。

3.  **桌面區域調整 (Last Played Hand vs Deck)**:
    *   修改 `// --- 桌面區域 (Last Played Hand) ---` 的佈局。
    *   目前該區域僅有一個 `ShowOnlyCardAreaWidget` 顯示 `bigTwoState.deckCards`。
    *   改為使用 `Column` 或 `Row` (視版面而定，建議 `Column` 垂直排列或重疊) 來容納兩個區域：
        1.  **桌面牌堆**: `ShowOnlyCardAreaWidget`，繼續顯示 `bigTwoState.deckCards` (如原設計)。
        2.  **上一次出的牌**: 新增一個 `ShowOnlyCardAreaWidget` (或其他適合顯示牌的 Widget)，顯示 `bigTwoState.lastPlayedHand`。
    *   確保兩者在視覺上有區隔，例如 `lastPlayedHand` 顯示在較顯眼的位置 (例如正中央)，而 `deckCards` 顯示在旁邊或下方作為背景/歷史堆疊。

### 3. 核心實作 (`big_two_board_widget.dart`)

```dart
// ... existing imports

class BigTwoBoardWidget extends StatefulWidget {
  // ... existing code
}

class _BigTwoBoardWidgetState extends State<BigTwoBoardWidget> {
  // ... existing code

  @override
  Widget build(BuildContext context) {
    return Provider<CardPlayer>(
      create: (_) => _player,
      child: StreamBuilder<TurnBasedGameState<BigTwoState>?>(
        stream: _gameController.gameStateStream,
        builder: (context, snapshot) {
          // ... (Pre-game checks)

          final bigTwoState = gameState.customState;
          
          // ... (Player data update)
          
          // ... (HandType Buttons generation)

          // Pass `bigTwoState.currentPlayerId` to helper methods if needed, or access directly
          final otherPlayers = _bigTwoManager.otherPlayers(_userId, bigTwoState);
          final edgeSize = 50.0;
          final isMyTurn = gameState.currentPlayerId == _userId;

          return Scaffold(
            body: Stack(
              children: [
                // --- 桌面區域 (Last Played Hand & Deck) ---
                Positioned.fromRelativeRect(
                  rect: RelativeRect.fromLTRB(edgeSize, edgeSize, edgeSize, edgeSize),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 上一次出的牌 (Last Played Hand) - 顯示在上方或顯眼處
                        if (bigTwoState.lastPlayedHand.isNotEmpty) ...[
                          const Text('Last Played:'),
                          ShowOnlyCardAreaWidget(
                            cards: bigTwoState.lastPlayedHand
                                .map((c) => PlayingCard.fromString(c))
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        // 桌面牌堆 (Deck Cards) - 依照需求顯示
                        // 使用者需求: "傳入 ShowOnlyCardAreaWidget的cards, 不顯示astPlayedHand"
                        // 這裡維持原有的 deckCards 顯示
                         const Text('Table/Deck:'),
                         ShowOnlyCardAreaWidget(
                           cards: bigTwoState.deckCards
                               .map((c) => PlayingCard.fromString(c))
                               .toList(),
                         ),
                      ],
                    ),
                  ),
                ),

                // --- 對手區域 ---
                // 傳入 currentPlayerId 以便在內部判斷高亮
                ..._otherPlayerWidgets(otherPlayers, bigTwoState.currentPlayerId),

                // --- 玩家手牌區域 ---
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 標示自己是否為 Current Player
                        if (isMyTurn)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "YOUR TURN",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ),
                        ChangeNotifierProvider.value(
                          value: _player,
                          child: SelectablePlayerHandWidget(
                            buttonWidgets: handTypeButtons,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ... (Function buttons and other widgets)
              ],
            ),
          );
        },
      ),
    );
  }

  // --- 對手區域 ---
  List<Widget> _otherPlayerWidgets(List<BigTwoPlayer> otherPlayers, String currentPlayerId) {
    return [
      if (otherPlayers.isNotEmpty)
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 40.0),
            child: _OpponentHand(
              cardCount: otherPlayers[0].cards.length,
              playerName: otherPlayers[0].name,
              isCurrentTurn: otherPlayers[0].uid == currentPlayerId,
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
                isCurrentTurn: otherPlayers[1].uid == currentPlayerId,
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
                isCurrentTurn: otherPlayers[2].uid == currentPlayerId,
              ),
            ),
          ),
        ),
    ];
  }
}

class _OpponentHand extends StatelessWidget {
  final int cardCount;
  final String playerName;
  final bool isCurrentTurn;

  const _OpponentHand({
    required this.cardCount,
    required this.playerName,
    this.isCurrentTurn = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
            playerName, 
            style: theme.textTheme.titleMedium?.copyWith(
                color: isCurrentTurn ? Colors.amber : null,
                fontWeight: isCurrentTurn ? FontWeight.bold : null,
            )
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.style, color: Colors.blueGrey, size: 30),
            const SizedBox(width: 8),
            Text(
              '$cardCount',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

### 4. 驗收標準 (Acceptance Criteria)

1.  **對手名稱變色**:
    *   當輪到某位對手時，該對手的名字應顯示為特殊顏色 (如琥珀色/紅色)。
    *   非該對手回合時，顯示預設顏色。
2.  **自己回合提示**:
    *   當輪到自己時，手牌區上方應出現明顯的 "YOUR TURN" 標示。
3.  **桌面顯示分離**:
    *   桌面中央應能同時看到 (或區分) `lastPlayedHand` (最近打出的牌) 與 `deckCards` (其他桌面牌/堆疊)。
    *   `lastPlayedHand` 應正確顯示 `BigTwoState` 中的 `lastPlayedHand` 內容。
