import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';

import 'playing_card_image_widget.dart';
import 'playing_card_widget.dart';

class ShowOnlyCardAreaWidget extends StatelessWidget {
  final List<PlayingCard> cards;

  const ShowOnlyCardAreaWidget({
    required this.cards,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: PlayingCardImageWidget.defaultHeight2 + 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: cards.map((card) =>
            PlayingCardImageWidget(
              card,
              AssetImage(
                  'assets/images/goblin_cards/goblin_1_${card.value.toString().padLeft(3, '0')}.png'),
              width: PlayingCardImageWidget.defaultWidth2,
              height: PlayingCardImageWidget.defaultHeight2,
            ),
        ).toList(),
      ),
    );
  }
}

