// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:ok_multipl_poker/style/card_theme_manager/card_theme_manager.dart';

import '../style/card_theme_manager/avatar_entity.dart';
import '../style/card_theme_manager/big_two_card_theme.dart';
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

  ValueNotifier<bool> testModeOn = ValueNotifier(false);

  /// 玩家的名稱。
  ValueNotifier<String> playerName = ValueNotifier('Player');

  /// 玩家的頭像編號。
  ValueNotifier<int> playerAvatarNumber = ValueNotifier(0);

  /// 當前選擇的卡片主題。
  ValueNotifier<BigTwoCardTheme> currentCardTheme = ValueNotifier(BigTwoCardTheme.weaveZoo);

  /// 是否已完成初次使用者引導 (Onboarding)。
  ValueNotifier<bool> hasCompletedOnboarding = ValueNotifier(false);

  /// 音效（sfx）是否開啟。
  ValueNotifier<bool> soundsOn = ValueNotifier(true);

  /// 音樂是否開啟。
  ValueNotifier<bool> musicOn = ValueNotifier(true);

  /// 當前語言。
  ValueNotifier<Locale> currentLocale = ValueNotifier(const Locale('en'));

  /// 支援的語言列表 (對應 main.dart 中的設定)
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('zh', 'TW'),
    Locale('ja'),
  ];

  /// 取得當前主題的 Manager 實體
  CardThemeManager get currentCardThemeManager => currentCardTheme.value.cardManager;

  /// 取得當前主題的頭像列表
  List<AvatarEntity> avatarList = [];

  /// 建立一個由 [store] 支援的 [SettingsController] 新實例。
  ///
  /// 預設情況下，設定會使用 [LocalStorageSettingsPersistence] 進行持久化
  ///（即 iOS 上的 NSUserDefaults，Android 上的 SharedPreferences，或網頁上的 local storage）。
  SettingsController({SettingsPersistence? store})
      : _store = store ?? LocalStorageSettingsPersistence() {
    _loadStateFromPersistence();

    avatarList = BigTwoCardTheme.values
        .expand((e)=>e.cardManager.avatars)
        .toList();
  }

  void setPlayerName(String name) {
    playerName.value = name;
    _store.savePlayerName(playerName.value);
  }

  void setPlayerAvatarNumber(int number) {
    playerAvatarNumber.value = number;
    _store.savePlayerAvatarNumber(playerAvatarNumber.value);
  }

  void setCardTheme(BigTwoCardTheme theme) {
    currentCardTheme.value = theme;
    _store.saveCardTheme(theme.name);
    // Ensure avatar number is valid for the new theme
    if (playerAvatarNumber.value >= avatarList.length) {
      setPlayerAvatarNumber(0);
    }
  }

  /// 取得當前頭像的完整路徑。
  String get currentAvatarPath {
    final list = avatarList;
    final index = playerAvatarNumber.value;
    if (index >= 0 && index < list.length) {
      return list[index].avatarImagePath;
    }
    return list.isNotEmpty ? list[0].avatarImagePath : '';
  }
  
  void setHasCompletedOnboarding(bool value) {
    hasCompletedOnboarding.value = value;
    _store.saveHasCompletedOnboarding(hasCompletedOnboarding.value);
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
  
  /// 切換到下一個語言
  void cycleLanguage(BuildContext context) {
    int currentIndex = supportedLocales.indexWhere(
            (element) => element.languageCode == context.locale.languageCode);
    
    // 如果找不到 (比如第一次執行)，預設從 0 開始
    if (currentIndex == -1) currentIndex = 0;

    int nextIndex = (currentIndex + 1) % supportedLocales.length;
    final nextLocale = supportedLocales[nextIndex];
    
    // 更新 ValueNotifier
    currentLocale.value = nextLocale;
    
    // 更新 Context (EasyLocalization)
    context.setLocale(nextLocale);
    
    // 儲存到 Persistence
    _store.saveLocale(nextLocale.toString());
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
      _store.getPlayerAvatarNumber().then((value) => playerAvatarNumber.value = value),
      _store.getHasCompletedOnboarding().then((value) => hasCompletedOnboarding.value = value),
      _store.getCardTheme().then((value) {
        final theme = BigTwoCardTheme.values.firstWhere(
          (e) => e.name == value,
          orElse: () => BigTwoCardTheme.weaveZoo,
        );
        currentCardTheme.value = theme;
      }),
      _store.getLocale(defaultValue: 'en').then((value) {
        // 解析 locale string, 簡單實作: 若包含 '_' 則拆分，否則視為 languageCode
        Locale locale;
        if (value.contains('_')) {
           final parts = value.split('_');
           locale = Locale(parts[0], parts[1]);
        } else {
           locale = Locale(value);
        }
        
        // 檢查是否為支援的語言，若否則退回預設
        if (!supportedLocales.any((element) => element.languageCode == locale.languageCode)) {
           locale = const Locale('en');
        }
        
        currentLocale.value = locale;
      }),
    ]);

    _log.fine(() => 'Loaded settings: $loadedValues');
  }
}
