// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

/// 一個可以輕鬆建立響應式畫面的 Widget，包含一個近乎方形的主要區域、
/// 一個較小的選單區域，以及頂部的一個小訊息區域。
/// 它能在手機和平板大小的螢幕上，支援直向和橫向兩種模式。
class ResponsiveScreen extends StatelessWidget {
  /// 這是畫面的「主角」。它或多或少是方形的，將被放置在畫面的視覺「中心」。
  final Widget squarishMainArea;

  /// 在 [squarishMainArea] 之後的第二大區域。它可以是窄的或寬的。
  final Widget rectangularMenuArea;

  /// 為靠近畫面頂部的一些靜態文本保留的區域。
  final Widget topMessageArea;

  const ResponsiveScreen({
    required this.squarishMainArea,
    required this.rectangularMenuArea,
    this.topMessageArea = const SizedBox.shrink(),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 這個 widget 希望填滿整個螢幕。
        final size = constraints.biggest;
        final padding = EdgeInsets.all(size.shortestSide / 30);

        if (size.height >= size.width) {
          // 「直向」/「手機」模式。
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(padding: padding, child: topMessageArea),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  bottom: false,
                  minimum: padding,
                  child: squarishMainArea,
                ),
              ),
              SafeArea(
                top: false,
                maintainBottomViewPadding: true,
                child: Padding(
                  padding: padding,
                  child: Center(child: rectangularMenuArea),
                ),
              ),
            ],
          );
        } else {
          // 「橫向」/「平板」模式。
          final isLarge = size.width > 900;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: isLarge ? 7 : 5,
                child: SafeArea(
                  right: false,
                  maintainBottomViewPadding: true,
                  minimum: padding,
                  child: squarishMainArea,
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      left: false,
                      maintainBottomViewPadding: true,
                      child: Padding(padding: padding, child: topMessageArea),
                    ),
                    Expanded(
                      child: SafeArea(
                        top: false,
                        left: false,
                        maintainBottomViewPadding: true,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: padding,
                            child: rectangularMenuArea,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
