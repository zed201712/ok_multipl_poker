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
  ValueNotifier<bool> musicOn = ValueNotifier(true);

  @override
  ValueNotifier<String> playerName = ValueNotifier('Player');

  @override
  ValueNotifier<bool> soundsOn = ValueNotifier(true);

  // The original `_store` is private and not part of the public interface,
  // so we don't need to (and can't) implement it here.
  // The same applies to private methods like `_loadStateFromPersistence`.

  FakeSettingsController();

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
}
