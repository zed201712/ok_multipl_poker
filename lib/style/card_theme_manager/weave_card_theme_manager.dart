import 'package:ok_multipl_poker/style/card_theme_manager/avatar_entity.dart';
import '../../game_internals/playing_card.dart';
import 'card_theme_manager.dart';

class WeaveCardThemeManager implements CardThemeManager {
  @override
  // TODO: Update when new assets are available
  String get mainBackgroundImagePath => 'assets/images/goblin_cards/goblin_bg_001.png';

  @override
  // TODO: Update when new assets are available
  String get gameBackgroundImagePath => 'assets/images/goblin_cards/goblin_bg_002.png';

  @override
  String get cardBackImagePath => 'assets/images/weave_cards/weave_cards_back_001.png';
  
  @override
  String get themePreviewImagePath => 'assets/images/weave_cards/weave_cards_001.png';

  @override
  String getCardImagePath(PlayingCard card) {
    if (card.value < 1 || card.value > 13) {
      throw ArgumentError('Invalid card value: ${card.value}');
    }
    return 'assets/images/weave_cards/weave_cards_${card.value.toString().padLeft(3, '0')}.png';
  }

  @override
  List<AvatarEntity> get avatars => _avatars;

  late final List<AvatarEntity> _avatars;

  WeaveCardThemeManager() {
    final avatarList = List.generate(15, (index) {
      final number = (index + 1).toString().padLeft(3, '0');
      // TODO: Add specific descriptions for weave theme avatars
      final description = '';
      return AvatarEntity('assets/images/weave_cards/weave_cards_$number.png', description);
    });
    this._avatars = avatarList;
  }
}
