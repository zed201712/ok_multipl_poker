import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/play_session/playing_card_image_widget.dart';
import 'package:ok_multipl_poker/play_session/show_only_card_area_widget.dart';
import 'package:ok_multipl_poker/widgets/card_container.dart';
import 'package:provider/provider.dart';

import '../entities/big_two_state.dart';
import '../game_internals/big_two_card_pattern.dart';
import '../game_internals/playing_card.dart';
import '../settings/settings.dart';

class BigTwoBoardCardArea extends StatelessWidget {
  //final VoidCallback? onDiscardPileTap;

  const BigTwoBoardCardArea({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    // 透過 Provider 取得 BigTwoState
    // 使用 watch 以便在狀態變更時重繪
    final bigTwoState = context.watch<BigTwoState>();
    final settingsController = context.watch<SettingsController>();

    // final deckCards = bigTwoState.deckCards
    //     .map((c) => PlayingCard.fromString(c))
    //     .toList();
    final deckCards = <PlayingCard>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 上層: Last Played Cards | Discard Pile
        _firstLine(bigTwoState, context, settingsController),

        // 下層: Deck Cards
        if (deckCards.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 5,
            runSpacing: 5,
            children: deckCards.map((e) => _buildCard(e, settingsController)).toList(),
          ),
      ],
    );

  }

  Widget _firstLine(BigTwoState bigTwoState, BuildContext context, SettingsController settingsController) {
    // 解析 lastPlayedTitle (lockedHandType display name)
    String lastPlayedTitle = "";
    if (bigTwoState.lockedHandType.isNotEmpty) {
      try {
        final pattern = BigTwoCardPattern.fromJson(bigTwoState.lockedHandType);
        lastPlayedTitle = "(${pattern.displayName})";
      } catch (_) {}
    }

    final lastPlayedCards = bigTwoState.lastPlayedHand
        .map((c) => PlayingCard.fromString(c))
        .toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Last Played Cards
        if (lastPlayedCards.isNotEmpty)
          CardContainer(
            title: 'Last Played $lastPlayedTitle',
            child: ShowOnlyCardAreaWidget(cards: lastPlayedCards),
          ),

        const Expanded(child: SizedBox.shrink()),

        // Right: Discard Pile
        // 只有當有棄牌時才顯示，或者始終顯示但若是空的就無法點擊?
        // Spec 說: 顯示一張代表棄牌堆的圖片 (Asset Image)
        // 且綁定 onTap 事件
        if (bigTwoState.uselessCards.isNotEmpty)
          InkWell(
            //onTap: onDiscardPileTap,
            onTap: () {
              if (bigTwoState.uselessCards.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return _discardDialog(bigTwoState, context);
                  },
                );
              }
            },
            child: CardContainer(
              title: 'Discard Pile',
              child: SizedBox(
                width: PlayingCardImageWidget.smallWidth + 10,   // PlayingCardWidget.width 大約是 60 左右，可調整
                height: PlayingCardImageWidget.smallHeight + 10, // PlayingCardWidget.height 大約是 90 左右
                child: Image.asset(
                  settingsController.currentCardTheme.cardBackImagePath,
                  // 暫時使用一張現有圖片作為背面或代表
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCard(PlayingCard card, SettingsController settingsController) {
    // 這裡復用 PlayingCardImageWidget，與 TableCardWrapWidget 邏輯一致
    return PlayingCardImageWidget(
      card,
      AssetImage(
          settingsController.currentCardTheme.getCardImagePath(card),
      ),
      width: PlayingCardImageWidget.smallWidth,
      height: PlayingCardImageWidget.smallHeight,
    );
  }

  Widget _discardDialog(BigTwoState bigTwoState, BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //const Text('自訂 Dialog', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
            const SizedBox(height: 12),
            CardContainer(
                title: 'Discard Pile',
                child: ShowOnlyCardAreaWidget(
                    cards: bigTwoState.uselessCards.toPlayingCards())
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

}
