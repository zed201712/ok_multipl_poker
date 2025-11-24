// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'persistence/local_storage_settings_persistence.dart';
import 'persistence/settings_persistence.dart';

/// 一個用於保存設定（例如 [playerName] 或 [musicOn]）的類別，
/// 並將其儲存到注入的持久化儲存中。
class SettingsController {
  static final _log = Logger('SettingsController');

  /// 用於儲存設定的持久化儲存區。
  final SettingsPersistence _store;

  /// 整體音訊是否開啟。這會覆蓋音樂和音效（sfx）的設定。
  ///
  /// 這是一個特別重要的功能，尤其是在手機上，玩家希望能快速將所有音訊靜音。
  /// 將其作為一個獨立的旗標（而不是像 {關閉, 音效, 全部} 這樣的列舉），
  /// 意味著玩家在暫時將遊戲靜音時，不會失去他們原有的 [soundsOn] 和
  /// [musicOn] 偏好設定。
  ValueNotifier<bool> audioOn = ValueNotifier(true);

  /// 玩家的名稱。用於最高分列表等地方。
  ValueNotifier<String> playerName = ValueNotifier('Player');

  /// 音效（sfx）是否開啟。
  ValueNotifier<bool> soundsOn = ValueNotifier(true);

  /// 音樂是否開啟。
  ValueNotifier<bool> musicOn = ValueNotifier(true);

  /// 建立一個由 [store] 支援的 [SettingsController] 新實例。
  ///
  /// 預設情況下，設定會使用 [LocalStorageSettingsPersistence] 進行持久化
  ///（即 iOS 上的 NSUserDefaults，Android 上的 SharedPreferences，或網頁上的 local storage）。
  SettingsController({SettingsPersistence? store})
      : _store = store ?? LocalStorageSettingsPersistence() {
    _loadStateFromPersistence();
  }

  void setPlayerName(String name) {
    playerName.value = name;
    _store.savePlayerName(playerName.value);
  }

  void toggleAudioOn() {
    audioOn.value = !audioOn.value;
    _store.saveAudioOn(audioOn.value);
  }

  void toggleMusicOn() {
    musicOn.value = !musicOn.value;
    _store.saveMusicOn(musicOn.value);
  }

  void toggleSoundsOn() {
    soundsOn.value = !soundsOn.value;
    _store.saveSoundsOn(soundsOn.value);
  }

  /// 從注入的持久化儲存中非同步載入數值。
  Future<void> _loadStateFromPersistence() async {
    final loadedValues = await Future.wait([
      _store.getAudioOn(defaultValue: true).then((value) {
        if (kIsWeb) {
          // 在網頁上，音訊只能在用戶互動後才能開始，
          // 所以我們在每次遊戲開始時都將其預設為靜音。
          return audioOn.value = false;
        }
        // 在其他平台上，我們可以使用持久化的數值。
        return audioOn.value = value;
      }),
      _store
          .getSoundsOn(defaultValue: true)
          .then((value) => soundsOn.value = value),
      _store
          .getMusicOn(defaultValue: true)
          .then((value) => musicOn.value = value),
      _store.getPlayerName().then((value) => playerName.value = value),
    ]);

    _log.fine(() => 'Loaded settings: $loadedValues');
  }
}
