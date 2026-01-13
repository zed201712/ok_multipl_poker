// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An interface of persistence stores for settings.
///
/// Implementations can range from simple in-memory storage through
/// local preferences to cloud-based solutions.
abstract class SettingsPersistence {
  Future<bool> getAudioOn({required bool defaultValue});

  Future<bool> getMusicOn({required bool defaultValue});

  Future<String> getPlayerName();

  Future<int> getPlayerAvatarNumber();

  Future<String?> getPlayerAvatarCardTheme();
  
  Future<String> getCardTheme();
  
  Future<String> getLocale({required String defaultValue});

  Future<bool> getHasCompletedOnboarding();

  Future<bool> getSoundsOn({required bool defaultValue});

  Future<void> saveAudioOn(bool value);

  Future<void> saveMusicOn(bool value);

  Future<void> savePlayerName(String value);

  Future<void> savePlayerAvatarNumber(int value);

  Future<void> savePlayerAvatarCardTheme(String value);
  
  Future<void> saveCardTheme(String value);

  Future<void> saveLocale(String value);

  Future<void> saveHasCompletedOnboarding(bool value);

  Future<void> saveSoundsOn(bool value);
}
