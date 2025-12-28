import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'avatar_entity.dart';

abstract class CardThemeManager {
  List<AvatarEntity> get avatars;
  String get mainBackgroundImagePath;
  String get gameBackgroundImagePath;
  String get cardBackImagePath;
  String get themePreviewImagePath;
  String getCardImagePath(PlayingCard card);
}
