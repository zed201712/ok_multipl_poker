import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/game_internals/big_two_delegate.dart';
import 'package:ok_multipl_poker/game_internals/card_player.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/play_session/show_only_card_area_widget.dart';
import 'package:ok_multipl_poker/style/my_button.dart';
import 'package:ok_multipl_poker/play_session/selectable_player_hand_widget.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../settings/settings.dart';

class BigTwoBoardWidget extends StatefulWidget {
  const BigTwoBoardWidget({super.key});

  @override
  State<BigTwoBoardWidget> createState() => _BigTwoBoardWidgetState();
}

class _BigTwoBoardWidgetState extends State<BigTwoBoardWidget> {
  late final FirestoreTurnBasedGameController<BigTwoState> _gameController;
  final CardPlayer _player = CardPlayer();
  final _bigTwoManager = BigTwoDelegate();
  late final String _userId;

  @override
  void initState() {
    super.initState();

    final auth = context.read<FirebaseAuth>();
    final store = context.read<FirebaseFirestore>();
    _userId = auth.currentUser!.uid;
    _gameController = FirestoreTurnBasedGameController<BigTwoState>(
      auth: auth,
      store: store,
      delegate: _bigTwoManager,
      collectionName: 'big_two_rooms',
      settingsController: context.read<SettingsController>(),
    );
    // You might need to set the room ID for the controller, for example:
    // _gameController.setRoomId('your_room_id');
    // This part depends on how you manage rooms in your app.
  }

  @override
  void dispose() {
    _gameController.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TurnBasedGameState<BigTwoState>?>(
      stream: _gameController.gameStateStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final gameState = snapshot.data!;
        final bigTwoState = gameState.customState;

        // Update local player's hand
        final myPlayerState = _bigTwoManager.myPlayer(_userId, bigTwoState);
        _player.name = myPlayerState.name;
        _player.replaceWith(myPlayerState.cards.map((c) => PlayingCard.fromString(c)).toList());

        // The types of hands that can be played.
        const handTypes = ['Single', 'Pair', 'Full House', 'Straight', 'Straight Flush'];
        final handTypeButtons = handTypes
            .map((type) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: OutlinedButton(
                    onPressed: () { /* TODO */ },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(type),
                  ),
                ))
            .toList();

        final otherPlayers = _bigTwoManager.otherPlayers(_userId, bigTwoState);

        final edgeSize = 50.0;
        return Scaffold(
          body: Stack(
            children: [
              Positioned.fromRelativeRect(
                rect: RelativeRect.fromLTRB(edgeSize, edgeSize, edgeSize, edgeSize),
                child: Align(
                  alignment: Alignment.center,
                  child: ShowOnlyCardAreaWidget(
                    cards: bigTwoState.lastPlayedHand.map((c) => PlayingCard.fromString(c)).toList(),
                  ),
                ),
              ),
              if (otherPlayers.isNotEmpty)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: _OpponentHand(
                      cardCount: otherPlayers[0].cards.length,
                      playerName: otherPlayers[0].name,
                    ),
                  ),
                ),
              if (otherPlayers.length > 1)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: _OpponentHand(
                        cardCount: otherPlayers[1].cards.length,
                        playerName: otherPlayers[1].name,
                      ),
                    ),
                  ),
                ),
              if (otherPlayers.length > 2)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: _OpponentHand(
                        cardCount: otherPlayers[2].cards.length,
                        playerName: otherPlayers[2].name,
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: ChangeNotifierProvider.value(
                    value: _player,
                    child: SelectablePlayerHandWidget(
                      buttonWidgets: handTypeButtons,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                right: 40,
                child: MyButton(
                  onPressed: () {
                    final selectedCards = _player.selectedCards;
                    if (selectedCards.isNotEmpty) {
                      _gameController.sendGameAction('play_hand', payload: {
                        'cards': selectedCards.map(PlayingCard.cardToString).toList(),
                      });
                    }
                  },
                  child: const Text('Play'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
