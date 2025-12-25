import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/card_suit.dart';
import '../game_internals/player.dart';
import '../game_internals/playing_card.dart';
import '../style/palette.dart';
import 'playing_card_widget.dart';

/// 與 [PlayingCardWidget] 相似，但支援自定義背景圖片，並將卡牌文字資訊移動至左上角。
class PlayingCardImageWidget extends StatelessWidget {
  // 標準撲克牌的尺寸約為 57.1mm x 88.9mm。
  static const double defaultWidth = 40.0;
  static const double defaultHeight = 60.0;

  final PlayingCard card;
  final ImageProvider image;
  final Player? player;
  final double? width;
  final double? height;

  const PlayingCardImageWidget(
       this.card,
       this.image, {
    this.player,
    this.width,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final textColor = card.suit.color == CardSuitColor.red
        ? palette.redPen
        : palette.ink;

    final cardWidth = width ?? defaultWidth;
    final cardHeight = height ?? defaultHeight;

    final cardWidget = DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium!.apply(color: textColor),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: palette.trueWhite,
          image: DecorationImage(
            image: image,
            fit: BoxFit.fitWidth,
            alignment: Alignment.bottomCenter,
          ),
          border: Border.all(color: palette.ink),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(1, 0, 0, 0),
            child: Text(
              '${card.suit.asCharacter} ${card.value}',
              textAlign: TextAlign.center,
            ),
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
