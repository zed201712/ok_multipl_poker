import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/play_session/playing_card_image_widget.dart';
import 'package:ok_multipl_poker/play_session/playing_card_widget.dart';
import 'package:ok_multipl_poker/play_session/show_only_card_area_widget.dart';
import 'package:ok_multipl_poker/widgets/card_container.dart';

import '../game_internals/playing_card.dart';

@Deprecated('Use BigTwoBoardCardArea instead')
class TableCardWrapWidget extends StatelessWidget {
  final List<PlayingCard> lastPlayedCards;
  final String lastPlayedTitle;
  final List<PlayingCard> deckCards;

  const TableCardWrapWidget({
    required this.lastPlayedCards,
    required this.lastPlayedTitle,
    required this.deckCards,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: PlayingCardWidget.height + 10,
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            // ===== Last Played 標示（Wrap 的第一個 child）=====

            // if (lastPlayedCards.isNotEmpty)
            //   _LastPlayedLabel(title: lastPlayedTitle),
            //
            // // ===== Last Played Cards =====
            // ...lastPlayedCards.map(_buildCard),
            if (lastPlayedCards.isNotEmpty)
              _LastPlayedWidget(
                title: lastPlayedTitle,
                lastPlayedCards: lastPlayedCards,
              ),

            // ===== Deck Cards =====
            ...deckCards.map(_buildCard),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(PlayingCard card) {
    return PlayingCardImageWidget(
      card,
      AssetImage(
        'assets/images/goblin_cards/goblin_1_${card.value.toString().padLeft(3, '0')}.png',
      ),
    );
  }
}


class _LastPlayedWidget extends StatelessWidget {
  final String title;
  final List<PlayingCard> lastPlayedCards;

  const _LastPlayedWidget({required this.title, required this.lastPlayedCards});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 上一次出的牌 (Last Played Hand) - 顯示在上方或顯眼處
        CardContainer(
          title: 'Last Played: $title',
          child: ShowOnlyCardAreaWidget(cards: lastPlayedCards),
        ),
      ],
    );
  }
}