import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_internals/big_two_board_state.dart';
import './player_hand_widget.dart';
import './playing_area_widget.dart';
import '../style/my_button.dart';

/// A widget that displays the main game board for a 4-player Big Two game.
///
/// It lays out the playing area, the local player's hand, controls, and a
/// representation of the opponents' hands.
class BigTwoBoardWidget extends StatefulWidget {
  const BigTwoBoardWidget({super.key});

  @override
  State<BigTwoBoardWidget> createState() => _BigTwoBoardWidgetState();
}

class _BigTwoBoardWidgetState extends State<BigTwoBoardWidget> {
  @override
  Widget build(BuildContext context) {
    final boardState = context.watch<BigTwoBoardState>();

    // Placeholder values until the state object is fully integrated.
    const int opponentCardCount = 13;
    const String player2Name = 'Player 2';
    const String player3Name = 'Player 3';
    const String player4Name = 'Player 4';

    return Scaffold(
      body: Stack(
        children: [
          // 1. Central playing area for cards that have been played.
          Align(
            alignment: Alignment.center,
            child: PlayingAreaWidget(boardState.centerPlayingArea),
          ),

          // 2. Opponent players' hands (top, left, right).
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: _OpponentHand(
                cardCount: opponentCardCount, // state.topPlayer.cardCount
                playerName: player3Name,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: RotatedBox(
                quarterTurns: 1,
                child: _OpponentHand(
                  cardCount: opponentCardCount, // state.leftPlayer.cardCount
                  playerName: player4Name,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: RotatedBox(
                quarterTurns: -1,
                child: _OpponentHand(
                  cardCount: opponentCardCount, // state.rightPlayer.cardCount
                  playerName: player2Name,
                ),
              ),
            ),
          ),

          // 3. Local player's area (bottom).
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row of buttons to select the hand type.
                  _buildHandTypeSelector(),
                  const SizedBox(height: 10),
                  // The local player's interactive hand.
                  const PlayerHandWidget(/* cards: state.localPlayer.hand */),
                ],
              ),
            ),
          ),

          // 4. 'Play' button for the local player.
          Positioned(
            bottom: 40,
            right: 40,
            child: MyButton(
              onPressed: () {
                // TODO: Wire up to a controller to play the selected cards.
                // final selectedCards = state.localPlayer.selectedCards;
                // context.read<BigTwoController>().play(selectedCards);
              },
              child: const Text('Play'),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a row of buttons for selecting the current hand combination type.
  Widget _buildHandTypeSelector() {
    // The types of hands that can be played, based on the spec.
    const handTypes = ['Single', 'Pair', 'Full House', 'Straight', 'Straight Flush'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: handTypes
          .map((type) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Handle hand type selection logic.
                    // This might filter the player's hand or set a mode.
                  },
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(type),
                ),
              ))
          .toList(),
    );
  }
}

/// A widget to represent an opponent's hand, showing a card back icon
/// and the number of cards remaining.
class _OpponentHand extends StatelessWidget {
  final int cardCount;
  final String playerName;

  const _OpponentHand({
    required this.cardCount,
    required this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(playerName, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Using a standard icon to represent the back of a card.
            const Icon(Icons.style, color: Colors.blueGrey, size: 30),
            const SizedBox(width: 8),
            Text(
              '$cardCount',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
