import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:provider/provider.dart';

import '../settings/settings.dart';
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
    final settingsController = context.watch<SettingsController>();

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: PlayingCardImageWidget.smallHeight + 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: cards.map((card) =>
            PlayingCardImageWidget(
              card,
              AssetImage(
                settingsController.currentCardTheme.getCardImagePath(card)
              ),
              width: PlayingCardImageWidget.smallWidth,
              height: PlayingCardImageWidget.smallHeight,
            ),
        ).toList(),
      ),
    );
  }
}

