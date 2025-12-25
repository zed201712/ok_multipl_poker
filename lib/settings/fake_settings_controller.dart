import 'package:flutter/foundation.dart';

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
  ValueNotifier<String> playerAvatarNumber = ValueNotifier('1');

  /// 是否已完成初次使用者引導 (Onboarding)。
  @override
  ValueNotifier<bool> hasCompletedOnboarding = ValueNotifier(false);

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
  void setPlayerAvatarNumber(String number) {
    playerAvatarNumber.value = number;
    // No persistence.
  }
  
  @override
  String get currentAvatarPath => 
      'assets/images/goblin_cards/goblin_1_${playerAvatarNumber.value.padLeft(3, '0')}.png';
}
