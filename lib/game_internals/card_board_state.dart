// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'card_player.dart';

/// 維護遊戲板的整體狀態。
class CardBoardState {
  /// 玩家獲勝時要呼叫的回呼函式。
  final VoidCallback onWin;

  final int localPlayerIndex;

  CardPlayer get player => allPlayers[localPlayerIndex];

  final List<CardPlayer> allPlayers;

  CardBoardState({
    required this.allPlayers,
    required this.localPlayerIndex,
    required this.onWin}) {
    player.addListener(_handlePlayerChange);
  }

  /// 釋放資源。
  void dispose() {
    player.removeListener(_handlePlayerChange);
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
