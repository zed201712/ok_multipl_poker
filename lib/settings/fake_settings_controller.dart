import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/style/card_theme_manager/avatar_entity.dart';
import 'package:ok_multipl_poker/style/card_theme_manager/card_theme_manager.dart';

import '../style/card_theme_manager/big_two_card_theme.dart';
import '../style/card_theme_manager/goblin_card_theme_manager.dart';
import 'settings.dart';

/// A fake implementation of [SettingsController] for testing purposes.
///
/// This class provides the same interface as [SettingsController] but does not
/// persist any settings. All values are stored in-memory.
class FakeSettingsController implements SettingsController {
  @override
  ValueNotifier<bool> audioOn = ValueNotifier(true);

  @override
  ValueNotifier<bool> testModeOn = ValueNotifier(false);

  @override
  ValueNotifier<bool> musicOn = ValueNotifier(true);

  @override
  ValueNotifier<String> playerName = ValueNotifier('Player');

  @override
  ValueNotifier<bool> soundsOn = ValueNotifier(true);

  /// 玩家的頭像編號。
  @override
  ValueNotifier<int> playerAvatarNumber = ValueNotifier(0);

  /// 是否已完成初次使用者引導 (Onboarding)。
  @override
  ValueNotifier<bool> hasCompletedOnboarding = ValueNotifier(false);

  @override
  ValueNotifier<Locale> currentLocale = ValueNotifier(const Locale('en'));

  // The original `_store` is private and not part of the public interface,
  // so we don't need to (and can't) implement it here.
  // The same applies to private methods like `_loadStateFromPersistence`.

  //FakeSettingsController();

  @override
  void setPlayerName(String name) {
    playerName.value = name;
    // No persistence.
  }

  @override
  void toggleAudioOn() {
    audioOn.value = !audioOn.value;
    // No persistence.
  }

  @override
  void toggleMusicOn() {
    musicOn.value = !musicOn.value;
    // No persistence.
  }

  @override
  void toggleSoundsOn() {
    soundsOn.value = !soundsOn.value;
    // No persistence.
  }

  @override
  void setHasCompletedOnboarding(bool value) {
  }

  @override
  void setPlayerAvatarNumber(int number) {
    playerAvatarNumber.value = number;
    // No persistence.
  }

  @override
  void cycleLanguage(BuildContext context) {
    int currentIndex = SettingsController.supportedLocales.indexWhere(
            (element) => element.languageCode == currentLocale.value.languageCode);

    if (currentIndex == -1) currentIndex = 0;

    int nextIndex = (currentIndex + 1) % SettingsController.supportedLocales.length;
    final nextLocale = SettingsController.supportedLocales[nextIndex];

    currentLocale.value = nextLocale;
  }
  
  @override
  String get currentAvatarPath => 
      'assets/images/goblin_cards/goblin_1_${playerAvatarNumber.value.toString().padLeft(3, '0')}.png';

  @override
  ValueNotifier<BigTwoCardTheme> currentCardTheme = ValueNotifier(BigTwoCardTheme.weaveZoo);

  @override
  List<AvatarEntity> avatarList = [];

  @override
  CardThemeManager get currentCardThemeManager => currentCardTheme.value.cardManager;

  @override
  void setCardTheme(BigTwoCardTheme theme) {
    currentCardTheme.value = theme;
    // Ensure avatar number is valid for the new theme
    if (playerAvatarNumber.value >= avatarList.length) {
      setPlayerAvatarNumber(0);
    }
  }
}
