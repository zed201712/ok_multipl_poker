// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:shared_preferences/shared_preferences.dart';

import 'settings_persistence.dart';

/// [SettingsPersistence] 的一個實作，使用 `shared_preferences` 套件。
///
/// 這會在 Android 上使用 SharedPreferences，在 iOS 上使用 NSUserDefaults，
/// 並在網頁上使用 local storage 來儲存設定。
class LocalStorageSettingsPersistence extends SettingsPersistence {
  final Future<SharedPreferences> instanceFuture =
      SharedPreferences.getInstance();

  @override
  Future<bool> getAudioOn({required bool defaultValue}) async {
    final prefs = await instanceFuture;
    return prefs.getBool('audioOn') ?? defaultValue;
  }

  @override
  Future<bool> getMusicOn({required bool defaultValue}) async {
    final prefs = await instanceFuture;
    return prefs.getBool('musicOn') ?? defaultValue;
  }

  @override
  Future<String> getPlayerName() async {
    final prefs = await instanceFuture;
    return prefs.getString('playerName') ?? 'Player';
  }

  @override
  Future<String> getPlayerAvatarNumber() async {
    final prefs = await instanceFuture;
    return prefs.getString('playerAvatarNumber') ?? '1';
  }

  @override
  Future<bool> getHasCompletedOnboarding() async {
    final prefs = await instanceFuture;
    return prefs.getBool('hasCompletedOnboarding') ?? false;
  }

  @override
  Future<bool> getSoundsOn({required bool defaultValue}) async {
    final prefs = await instanceFuture;
    return prefs.getBool('soundsOn') ?? defaultValue;
  }

  @override
  Future<void> saveAudioOn(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('audioOn', value);
  }

  @override
  Future<void> saveMusicOn(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('musicOn', value);
  }

  @override
  Future<void> savePlayerName(String value) async {
    final prefs = await instanceFuture;
    await prefs.setString('playerName', value);
  }

  @override
  Future<void> savePlayerAvatarNumber(String value) async {
    final prefs = await instanceFuture;
    await prefs.setString('playerAvatarNumber', value);
  }

  @override
  Future<void> saveHasCompletedOnboarding(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('hasCompletedOnboarding', value);
  }

  @override
  Future<void> saveSoundsOn(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('soundsOn', value);
  }
}
