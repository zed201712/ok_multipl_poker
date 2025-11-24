import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/card_suit.dart';
import '../game_internals/player.dart';
import '../game_internals/playing_card.dart';
import '../style/palette.dart';

/// 這個 Widget 負責顯示一張撲克牌的視覺樣式。
///
/// 它會根據撲克牌的花色（紅或黑）來決定文字顏色，並顯示花色符號和數字。
///
/// 如果這張牌屬於某個玩家（即 [player] 參數不是 null），
/// 它會被包裹在一個 [Draggable] Widget 中，讓玩家可以將其拖曳到出牌區。
/// 當拖曳開始和結束時，會播放對應的音效。
class PlayingCardWidget extends StatelessWidget {
  // 標準撲克牌的尺寸約為 57.1mm x 88.9mm。
  static const double width = 57.1;

  static const double height = 88.9;

  final PlayingCard card;

  final Player? player;

  const PlayingCardWidget(this.card, {this.player, super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final textColor = card.suit.color == CardSuitColor.red
        ? palette.redPen
        : palette.ink;

    final cardWidget = DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium!.apply(color: textColor),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: palette.trueWhite,
          border: Border.all(color: palette.ink),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(
          child: Text(
            '${card.suit.asCharacter}\n${card.value}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );

    // 不在玩家手中的牌是不可拖曳的。
    if (player == null) return cardWidget;

    return Draggable(
      feedback: Transform.rotate(angle: 0.1, child: cardWidget),
      data: PlayingCardDragData(card, player!),
      childWhenDragging: Opacity(opacity: 0.5, child: cardWidget),
      onDragStarted: () {
        final audioController = context.read<AudioController>();
        audioController.playSfx(SfxType.huhsh);
      },
      onDragEnd: (details) {
        final audioController = context.read<AudioController>();
        audioController.playSfx(SfxType.wssh);
      },
      child: cardWidget,
    );
  }
}

/// 在拖曳撲克牌時，用於傳遞資料的不可變類別。
@immutable
class PlayingCardDragData {
  /// 被拖曳的撲克牌。
  final PlayingCard card;

  /// 持有這張牌的玩家。
  final Player holder;

  const PlayingCardDragData(this.card, this.holder);
}
