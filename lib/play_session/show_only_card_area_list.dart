import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:provider/provider.dart';

import '../settings/settings.dart';
import 'playing_card_image_widget.dart';

class ShowOnlyCardAreaList extends StatelessWidget {
  final List<PlayingCard> cards;

  const ShowOnlyCardAreaList({
    required this.cards,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();

    return ConstrainedBox(
      // 保留原本的最小高度限制
      constraints: BoxConstraints(minHeight: PlayingCardImageWidget.smallHeight + 10),
      child: GridView.builder(
        // shrinkWrap: true 讓 GridView 只占用內容所需的高度（如果父層是 Column 或 ListView 則很有用）
        shrinkWrap: true,
        // 增加一點內邊距，避免邊緣太擠
        padding: const EdgeInsets.all(10),
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: PlayingCardImageWidget.smallWidth,
          mainAxisSpacing: 10, // 垂直間距
          crossAxisSpacing: 10, // 水平間距
          // 這裡非常重要：必須符合卡片的寬高比例，否則卡片會被拉伸或切掉
          childAspectRatio: PlayingCardImageWidget.smallWidth / PlayingCardImageWidget.smallHeight,
        ),
        itemBuilder: (context, index) {
          final card = cards[index];
          return PlayingCardImageWidget(
            card,
            AssetImage(
              settingsController.currentCardThemeManager.getCardImagePath(card),
            ),
            width: PlayingCardImageWidget.smallWidth,
            height: PlayingCardImageWidget.smallHeight,
          );
        },
      ),
    );
  }
}
