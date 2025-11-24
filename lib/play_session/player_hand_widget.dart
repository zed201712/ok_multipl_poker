import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_internals/board_state.dart';
import 'playing_card_widget.dart';

/// 這個 Widget 負責顯示玩家的手牌區域。
///
/// 它會監聽 [BoardState.player] 的變更，並在玩家手牌有任何更新時自動重建 UI。
/// 透過使用 [Wrap]，它可以根據螢幕寬度自動排列手牌，確保手牌在不同尺寸的裝置上都能良好地顯示。
class PlayerHandWidget extends StatelessWidget {
  const PlayerHandWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final boardState = context.watch<BoardState>();

    return Padding(
      padding: const EdgeInsets.all(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: PlayingCardWidget.height),
        child: ListenableBuilder(
          // Make sure we rebuild every time there's an update
          // to the player's hand.
          listenable: boardState.player,
          builder: (context, child) {
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                ...boardState.player.hand.map(
                  (card) => PlayingCardWidget(card, player: boardState.player),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
