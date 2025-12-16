import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';

import 'playing_card_widget.dart';

class ShowOnlyCardAreaWidget extends StatelessWidget {
  final List<PlayingCard> cards;

  const ShowOnlyCardAreaWidget({
    required this.cards,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: PlayingCardWidget.height + 10),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: cards.map((card) => PlayingCardWidget(card)).toList(),
        ),
      ),
    );
  }
}
