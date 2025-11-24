import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/playing_area.dart';
import '../game_internals/playing_card.dart';
import '../style/palette.dart';
import 'playing_card_widget.dart';

/// 這個 Widget 代表遊戲板上的一個圓形出牌區。
///
/// 它是一個 `DragTarget`，可以接收從玩家手中拖曳過來的撲克牌 (`PlayingCardWidget`)。
/// 當一張牌被拖曳到此區域上方時，它會顯示高亮效果。當牌被成功放置時，
/// 它會更新對應的 `PlayingArea` 狀態。
///
/// 此外，點擊此區域會移除最上面的一張牌。它內部使用 `_CardStack` 來堆疊顯示區域內的卡牌。
class PlayingAreaWidget extends StatefulWidget {
  final PlayingArea area;

  const PlayingAreaWidget(this.area, {super.key});

  @override
  State<PlayingAreaWidget> createState() => _PlayingAreaWidgetState();
}

class _PlayingAreaWidgetState extends State<PlayingAreaWidget> {
  bool isHighlighted = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return LimitedBox(
      maxHeight: 200,
      child: AspectRatio(
        aspectRatio: 1 / 1,
        child: DragTarget<PlayingCardDragData>(
          builder: (context, candidateData, rejectedData) => Material(
            color: isHighlighted ? palette.accept : palette.trueWhite,
            shape: const CircleBorder(),
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              splashColor: palette.redPen,
              onTap: _onAreaTap,
              child: StreamBuilder(
                // Rebuild the card stack whenever the area changes
                // (either by a player action, or remotely).
                stream: widget.area.allChanges,
                builder: (context, child) => _CardStack(widget.area.cards),
              ),
            ),
          ),
          onWillAcceptWithDetails: _onDragWillAccept,
          onLeave: _onDragLeave,
          onAcceptWithDetails: _onDragAccept,
        ),
      ),
    );
  }

  void _onAreaTap() {
    widget.area.removeFirstCard();

    final audioController = context.read<AudioController>();
    audioController.playSfx(SfxType.huhsh);
  }

  void _onDragAccept(DragTargetDetails<PlayingCardDragData> details) {
    widget.area.acceptCard(details.data.card);
    details.data.holder.removeCard(details.data.card);
    setState(() => isHighlighted = false);
  }

  void _onDragLeave(PlayingCardDragData? data) {
    setState(() => isHighlighted = false);
  }

  bool _onDragWillAccept(DragTargetDetails<PlayingCardDragData> details) {
    setState(() => isHighlighted = true);
    return true;
  }
}

class _CardStack extends StatelessWidget {
  static const int _maxCards = 6;

  static const _leftOffset = 10.0;

  static const _topOffset = 5.0;

  static const double _maxWidth =
      _maxCards * _leftOffset + PlayingCardWidget.width;

  static const _maxHeight = _maxCards * _topOffset + PlayingCardWidget.height;

  final List<PlayingCard> cards;

  const _CardStack(this.cards);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: _maxWidth,
        height: _maxHeight,
        child: Stack(
          children: [
            for (
              var i = max(0, cards.length - _maxCards);
              i < cards.length;
              i++
            )
              Positioned(
                top: i * _topOffset,
                left: i * _leftOffset,
                child: PlayingCardWidget(cards[i]),
              ),
          ],
        ),
      ),
    );
  }
}
