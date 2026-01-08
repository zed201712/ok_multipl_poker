import 'package:ok_multipl_poker/style/card_theme_manager/avatar_entity.dart';
import '../../game_internals/playing_card.dart';
import 'card_theme_manager.dart';

class WeaveZooCardThemeManager implements CardThemeManager {
  @override
  String get mainBackgroundImagePath => 'assets/images/zoo_cards/zoo_bg_001.png';

  @override
  String get gameBackgroundImagePath => 'assets/images/zoo_cards/zoo_bg_002.png';

  @override
  String get cardBackImagePath => 'assets/images/zoo_cards/zoo_cards_back_001.png';

  @override
  String get themePreviewImagePath => 'assets/images/zoo_cards/zoo_cards_001.png';

  @override
  String getCardImagePath(PlayingCard card) {
    if (card.value < 0 || card.value > 13) {
      throw ArgumentError('Invalid card value: ${card.value}');
    }
    return 'assets/images/zoo_cards/zoo_cards_${card.value.toString().padLeft(3, '0')}.png';
  }

  @override
  List<AvatarEntity> get avatars => _avatars;

  late final List<AvatarEntity> _avatars;

  WeaveZooCardThemeManager() {
    final avatarList = List.generate(14, (index) {
      final number = (index + 0).toString().padLeft(3, '0');
      // TODO: Add specific descriptions for weave theme avatars
      final description = '';
      return AvatarEntity('assets/images/zoo_cards/zoo_cards_$number.png', description);
    });
    this._avatars = avatarList;
  }
}
