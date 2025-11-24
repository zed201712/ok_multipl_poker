// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'player.dart';
import 'playing_area.dart';

/// 維護遊戲板的整體狀態。
class BoardState {
  /// 玩家獲勝時要呼叫的回呼函式。
  final VoidCallback onWin;

  /// 第一個遊戲區域。
  final PlayingArea areaOne = PlayingArea();

  /// 第二個遊戲區域。
  final PlayingArea areaTwo = PlayingArea();

  /// 代表目前玩家的實例。
  final Player player = Player();

  BoardState({required this.onWin}) {
    player.addListener(_handlePlayerChange);
  }

  /// 取得所有遊戲區域的列表。
  List<PlayingArea> get areas => [areaOne, areaTwo];

  /// 釋放資源。
  void dispose() {
    player.removeListener(_handlePlayerChange);
    areaOne.dispose();
    areaTwo.dispose();
  }

  /// 處理玩家狀態的變更。
  ///
  /// 當玩家手牌為空時，觸發 `onWin` 回呼。
  void _handlePlayerChange() {
    if (player.hand.isEmpty) {
      onWin();
    }
  }
}
