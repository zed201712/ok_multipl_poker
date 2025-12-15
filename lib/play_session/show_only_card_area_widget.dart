
import 'package:flutter/material.dart';

import '../game_internals/card_player.dart';
import 'playing_card_widget.dart';

/// A widget that displays a player's hand and allows for card selection.
///
/// It also displays a customizable row of buttons above the hand.
class ShowOnlyCardAreaWidget extends StatelessWidget {
  final CardPlayer cardPlayer;

  const ShowOnlyCardAreaWidget({
    required this.cardPlayer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: PlayingCardWidget.height + 10),
        child: ListenableBuilder(
          listenable: cardPlayer,
          builder: (context, child) {
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: cardPlayer.hand.map((card) {
                return PlayingCardWidget(card);
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
