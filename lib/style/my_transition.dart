// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 為 `go_router` 建立一個自訂的頁面轉場動畫。
///
/// 這個轉場動畫會建立一個「揭示」效果，其中一個有顏色的方塊會從上往下滑動，
/// 同時新頁面的內容會淡入。
CustomTransitionPage<T> buildMyTransition<T>({
  required Widget child,
  required Color color,
  String? name,
  Object? arguments,
  String? restorationId,
  LocalKey? key,
}) {
  return CustomTransitionPage<T>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return _MyReveal(animation: animation, color: color, child: child);
    },
    key: key,
    name: name,
    arguments: arguments,
    restorationId: restorationId,
    transitionDuration: const Duration(milliseconds: 700),
  );
}

/// 這個 Widget 實作了「揭示」轉場動畫。
///
/// 它使用一個 [Stack] 將兩個動畫層疊在一起：
/// 1. 一個 [SlideTransition]，讓一個有顏色的 [Container] 從頂部滑入。
/// 2. 一個 [FadeTransition]，讓新頁面的 [child] 內容淡入。
class _MyReveal extends StatelessWidget {
  final Widget child;

  final Animation<double> animation;

  final Color color;

  final _slideTween = Tween(begin: const Offset(0, -1), end: Offset.zero);

  final _fadeTween = TweenSequence([
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
  ]);

  _MyReveal({
    required this.child,
    required this.animation,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SlideTransition(
          position: _slideTween.animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeOutCubic,
            ),
          ),
          child: Container(color: color),
        ),
        FadeTransition(opacity: _fadeTween.animate(animation), child: child),
      ],
    );
  }
}
