// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// 封裝分數及其計算方式。
class Score {
  final int score;

  final Duration duration;

  final int level;

  factory Score(int level, int difficulty, Duration duration) {
    // 難度越高，分數越高。
    var score = difficulty;
    // 完成關卡的時間越短，分數越高。
    score *= 10000 ~/ (duration.inSeconds.abs() + 1);
    return Score._(score, duration, level);
  }

  const Score._(this.score, this.duration, this.level);

  /// 將遊戲時間格式化為 `HH:MM:SS` 或 `MM:SS` 的字串。
  String get formattedTime {
    final buf = StringBuffer();
    if (duration.inHours > 0) {
      buf.write('${duration.inHours}');
      buf.write(':');
    }
    final minutes = duration.inMinutes % Duration.minutesPerHour;
    if (minutes > 9) {
      buf.write('$minutes');
    } else {
      buf.write('0');
      buf.write('$minutes');
    }
    buf.write(':');
    buf.write(
      (duration.inSeconds % Duration.secondsPerMinute).toString().padLeft(
        2,
        '0',
      ),
    );
    return buf.toString();
  }

  @override
  String toString() => 'Score<$score,$formattedTime,$level>';
}
