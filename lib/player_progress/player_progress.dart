// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'persistence/local_storage_player_progress_persistence.dart';
import 'persistence/player_progress_persistence.dart';

/// 封裝玩家的遊戲進度。
class PlayerProgress extends ChangeNotifier {
  /// 每個玩家最多儲存 10 筆最高分記錄。
  static const maxHighestScoresPerPlayer = 10;

  /// 預設情況下，進度會使用 [LocalStoragePlayerProgressPersistence] 進行持久化儲存
  ///（在 iOS 上是 NSUserDefaults，在 Android 上是 SharedPreferences，在網頁上是 local storage）。
  final PlayerProgressPersistence _store;

  int _highestLevelReached = 0;

  /// 建立一個 [PlayerProgress] 的實例，並由注入的持久化儲存 [store] 支援。
  PlayerProgress({PlayerProgressPersistence? store})
      : _store = store ?? LocalStoragePlayerProgressPersistence() {
    _getLatestFromStore();
  }

  /// 玩家目前達到的最高關卡。
  int get highestLevelReached => _highestLevelReached;

  /// 重設玩家的進度，回復到首次遊玩遊戲的狀態。
  void reset() {
    _highestLevelReached = 0;
    notifyListeners();
    _store.saveHighestLevelReached(_highestLevelReached);
  }

  /// 標記 [level] 為已達成。
  ///
  /// 如果這個關卡高於 [highestLevelReached]，將會更新該值並儲存到注入的持久化儲存中。
  void setLevelReached(int level) {
    if (level > _highestLevelReached) {
      _highestLevelReached = level;
      notifyListeners();

      unawaited(_store.saveHighestLevelReached(level));
    }
  }

  /// 從後端的持久化儲存中取得最新的資料。
  Future<void> _getLatestFromStore() async {
    final level = await _store.getHighestLevelReached();
    if (level > _highestLevelReached) {
      _highestLevelReached = level;
      notifyListeners();
    } else if (level < _highestLevelReached) {
      await _store.saveHighestLevelReached(_highestLevelReached);
    }
  }
}
