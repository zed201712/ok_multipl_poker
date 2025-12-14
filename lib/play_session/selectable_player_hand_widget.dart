
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_internals/board_state.dart';
import '../game_internals/player.dart';
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
    final boardState = context.watch<BoardState>();
    final player = boardState.player;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row of buttons to select the hand type.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buttonWidgets,
        ),
        const SizedBox(height: 10),
        // The local player's interactive hand.
        Padding(
          padding: const EdgeInsets.all(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: PlayingCardWidget.height + 10),
            child: ListenableBuilder(
              listenable: player,
              builder: (context, child) {
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: player.hand.map((card) {
                    final isSelected = player.selectedCards.contains(card);
                    return GestureDetector(
                      onTap: () {
                        player.toggleCardSelection(card);
                      },
                      child: Transform.translate(
                        offset: Offset(0, isSelected ? -10.0 : 0),
                        child: PlayingCardWidget(card, player: player),
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
