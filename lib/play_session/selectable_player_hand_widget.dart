
import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/game_internals/card_player.dart';
import 'package:ok_multipl_poker/play_session/playing_card_image_widget.dart';
import 'package:provider/provider.dart';

import 'playing_card_widget.dart';

/// A widget that displays a player's hand and allows for card selection.
///
/// It also displays a customizable row of buttons above the hand.
class SelectablePlayerHandWidget extends StatelessWidget {
  final List<Widget> buttonWidgets;

  const SelectablePlayerHandWidget({
    required this.buttonWidgets,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.watch<CardPlayer>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row of buttons to select the hand type.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buttonWidgets,
        ),
        const SizedBox(height: 2),
        // The local player's interactive hand.
        Padding(
          padding: const EdgeInsets.all(2),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: PlayingCardImageWidget.defaultHeight2 + 10),
            child: ListenableBuilder(
              listenable: player,
              builder: (context, child) {
                return Row(
                  spacing: 6,
                  children: player.hand.map((card) {
                    final isSelected = player.selectedCards.contains(card);
                    return GestureDetector(
                      onTap: () {
                        player.toggleCardSelection(card);
                      },
                      child: Transform.translate(
                        offset: Offset(0, isSelected ? -10.0 : 0),
                        child: PlayingCardImageWidget(
                          card,
                          AssetImage(
                            // 'assets/images/goblin_cards/goblin_1_001.png',
                            'assets/images/goblin_cards/goblin_1_${card.value.toString().padLeft(3, '0')}.png',
                          ),
                          width: PlayingCardImageWidget.defaultWidth2,
                          height: PlayingCardImageWidget.defaultHeight2,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
