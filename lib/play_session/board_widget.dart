// Copyright 2023, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_internals/board_state.dart';
import 'player_hand_widget.dart';
import 'playing_area_widget.dart';

/// 這個 Widget 定義了遊戲本身的使用者介面，不包含設定按鈕或返回按鈕等外部元件。
/// 它負責排列遊戲中的主要視覺元素，例如兩個出牌區和玩家的手牌區。
class BoardWidget extends StatefulWidget {
  const BoardWidget({super.key});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  @override
  Widget build(BuildContext context) {
    final boardState = context.watch<BoardState>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(child: PlayingAreaWidget(boardState.areaOne)),
              const SizedBox(width: 20),
              Expanded(child: PlayingAreaWidget(boardState.areaTwo)),
            ],
          ),
        ),
        const PlayerHandWidget(),
      ],
    );
  }
}
