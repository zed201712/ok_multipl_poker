// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import '../app_lifecycle/app_lifecycle.dart';
import '../settings/settings.dart';
import 'songs.dart';
import 'sounds.dart';

/// 負責播放音樂和音效。這是對 `package:audioplayers` 的一個外觀封裝(Facade)。
class AudioController {
  static final _log = Logger('AudioController');

  final AudioPlayer _musicPlayer;

  /// 一個 [AudioPlayer] 實體的列表，用於輪流播放音效，以實現多個音效同時播放的效果。
  final List<AudioPlayer> _sfxPlayers;

  /// 指向當前使用的音效播放器索引。
  int _currentSfxPlayer = 0;

  /// 背景音樂的播放列表。
  final Queue<Song> _playlist;

  final Random _random = Random();

  /// 設定控制器的實例，用來監聽音訊相關設定的變更。
  SettingsController? _settings;

  /// APP 生命週期狀態的通知器，用來監聽 App 的狀態（例如：進入背景、回到前景）。
  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  /// 建立一個播放音樂和音效的實例。
  ///
  /// 使用 [polyphony] 參數來設定可以同時播放的音效（SFX）數量。
  /// [polyphony] 為 `1` 表示一次只能播放一個音效（新的音效會打斷前一個）。
  ///
  /// 背景音樂不計入 [polyphony] 的限制。音樂永遠不會被音效覆蓋。
  AudioController({int polyphony = 2})
      : assert(polyphony >= 1),
        _musicPlayer = AudioPlayer(playerId: 'musicPlayer'),
        _sfxPlayers = Iterable.generate(
          polyphony,
          (i) => AudioPlayer(playerId: 'sfxPlayer#$i'),
        ).toList(growable: false),
        _playlist = Queue.of(List<Song>.of(songs)..shuffle()) {
    _musicPlayer.onPlayerComplete.listen(_handleSongFinished);
    unawaited(_preloadSfx());
  }

  /// 確保音訊控制器能夠監聽 App 生命週期（例如 App 暫停）和設定變更（例如靜音）。
  void attachDependencies(
    AppLifecycleStateNotifier lifecycleNotifier,
    SettingsController settingsController,
  ) {
    _attachLifecycleNotifier(lifecycleNotifier);
    _attachSettings(settingsController);
  }

  /// 釋放資源。
  void dispose() {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    _stopAllSound();
    _musicPlayer.dispose();
    for (final player in _sfxPlayers) {
      player.dispose();
    }
  }

  /// 播放由 [type] 定義的單一音效。
  ///
  /// 如果設定中的 [SettingsController.audioOn] 為 `false` 或
  /// [SettingsController.soundsOn] 為 `false`，則此呼叫將被忽略。
  void playSfx(SfxType type) {
    final audioOn = _settings?.audioOn.value ?? false;
    if (!audioOn) {
      _log.fine(() => '由於音訊被靜音，忽略播放音效 ($type)');
      return;
    }
    final soundsOn = _settings?.soundsOn.value ?? false;
    if (!soundsOn) {
      _log.fine(
        () => 'Ignoring playing sound ($type) because sounds are turned off.',
      );
      return;
    }

    _log.fine(() => 'Playing sound: $type');
    final options = soundTypeToFilename(type);
    final filename = options[_random.nextInt(options.length)];
    _log.fine(() => '- Chosen filename: $filename');

    final currentPlayer = _sfxPlayers[_currentSfxPlayer];
    currentPlayer.play(
      AssetSource('sfx/$filename'),
      volume: soundTypeToVolume(type),
    );
    // 使用輪詢方式(round-robin)選擇下一個播放器。
    _currentSfxPlayer = (_currentSfxPlayer + 1) % _sfxPlayers.length;
  }

  /// 讓音訊控制器能夠監聽 [AppLifecycleState] 事件，
  /// 從而在遊戲進入背景時停止播放等。
  void _attachLifecycleNotifier(AppLifecycleStateNotifier lifecycleNotifier) {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);

    lifecycleNotifier.addListener(_handleAppLifecycle);
    _lifecycleNotifier = lifecycleNotifier;
  }

  /// 讓音訊控制器能夠追蹤設定的變更。
  /// 當 [SettingsController.audioOn]、[SettingsController.musicOn] 或
  /// [SettingsController.soundsOn] 發生變化時，音訊控制器會採取相應的行動。
  void _attachSettings(SettingsController settingsController) {
    if (_settings == settingsController) {
      // 已經綁定到同一個實例，無需處理。
      return;
    }

    // 如果存在舊的設定控制器，則移除其監聽器。
    final oldSettings = _settings;
    if (oldSettings != null) {
      oldSettings.audioOn.removeListener(_audioOnHandler);
      oldSettings.musicOn.removeListener(_musicOnHandler);
      oldSettings.soundsOn.removeListener(_soundsOnHandler);
    }

    _settings = settingsController;

    // 為新的設定控制器添加監聽器。
    settingsController.audioOn.addListener(_audioOnHandler);
    settingsController.musicOn.addListener(_musicOnHandler);
    settingsController.soundsOn.addListener(_soundsOnHandler);

    if (settingsController.audioOn.value && settingsController.musicOn.value) {
      if (kIsWeb) {
        _log.info('On the web, music can only start after user interaction.');
      } else {
        _playCurrentSongInPlaylist();
      }
    }
  }

  /// `audioOn` 設定變更時的處理函式。
  void _audioOnHandler() {
    _log.fine('audioOn changed to ${_settings!.audioOn.value}');
    if (_settings!.audioOn.value) {
      // 整體音訊被取消靜音。
      if (_settings!.musicOn.value) {
        _startOrResumeMusic();
      }
    } else {
      // 整體音訊被靜音。
      _stopAllSound();
    }
  }

  /// App 生命週期變更時的處理函式。
  void _handleAppLifecycle() {
    switch (_lifecycleNotifier!.value) {
      case AppLifecycleState.paused: // App 暫停，例如切換到其他 App
      case AppLifecycleState.detached: // App 銷毀
      case AppLifecycleState.hidden: // App 最小化
        _stopAllSound();
      case AppLifecycleState.resumed: // App 回到前景
        if (_settings!.audioOn.value && _settings!.musicOn.value) {
          _startOrResumeMusic();
        }
      case AppLifecycleState.inactive:
        // App 處於非活動狀態，例如有來電或系統提示。
        // 此狀態下不需要特別反應。
        break;
    }
  }

  /// 目前歌曲播放完畢時的處理函式。
  void _handleSongFinished(void _) {
    _log.info('Last song finished playing.');
    // 將剛播放完的歌曲移到播放列表的末尾。
    _playlist.addLast(_playlist.removeFirst());
    // 播放播放列表中的下一首歌曲。
    _playCurrentSongInPlaylist();
  }

  /// `musicOn` 設定變更時的處理函式。
  void _musicOnHandler() {
    if (_settings!.musicOn.value) {
      // 音樂被開啟。
      if (_settings!.audioOn.value) {
        _startOrResumeMusic();
      }
    } else {
      // 音樂被關閉。
      _musicPlayer.pause();
    }
  }

  /// 播放目前播放列表中的第一首歌曲。
  Future<void> _playCurrentSongInPlaylist() async {
    _log.info(() => 'Playing ${_playlist.first} now.');
    try {
      await _musicPlayer.play(AssetSource('music/${_playlist.first.filename}'));
    } catch (e) {
      _log.severe('Could not play song ${_playlist.first}', e);
    }
  }

  /// 預先載入所有音效檔案。
  Future<void> _preloadSfx() async {
    _log.info('Preloading sound effects');
    // 這邊假設遊戲中的音效數量有限。
    // 如果有數百個很長的音效檔案，最好在預載入時更有選擇性。
    await AudioCache.instance.loadAll(
      SfxType.values
          .expand(soundTypeToFilename)
          .map((path) => 'sfx/$path')
          .toList(),
    );
  }

  /// `soundsOn` 設定變更時的處理函式。
  void _soundsOnHandler() {
    // 當音效設定被關閉時，停止所有正在播放的音效。
    for (final player in _sfxPlayers) {
      if (player.state == PlayerState.playing) {
        player.stop();
      }
    }
  }

  /// 開始或恢復播放音樂。
  void _startOrResumeMusic() async {
    if (_musicPlayer.source == null) {
      // 如果從未播放過音樂。
      _log.info(
        'No music source set. '
        'Start playing the current song in playlist.',
      );
      await _playCurrentSongInPlaylist();
      return;
    }

    _log.info('Resuming paused music.');
    try {
      // 嘗試恢復播放。
      _musicPlayer.resume();
    } catch (e) {
      // 有時，恢復播放會失敗並拋出 "Unexpected" 錯誤。
      _log.severe('Error resuming music', e);
      // 發生錯誤時，嘗試從頭開始播放歌曲。
      _playCurrentSongInPlaylist();
    }
  }

  /// 停止所有音訊播放。
  void _stopAllSound() {
    _log.info('Stopping all sound');
    _musicPlayer.pause();
    for (final player in _sfxPlayers) {
      player.stop();
    }
  }
}
