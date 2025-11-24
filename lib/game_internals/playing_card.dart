import 'dart:math';

import 'package:flutter/foundation.dart';

import 'card_suit.dart';

/// 代表一張撲克牌。
///
/// 一旦建立，撲克牌就是不可變的。
@immutable
class PlayingCard {
  static final _random = Random();

  /// 這張牌的花色。
  final CardSuit suit;

  /// 這張牌的數字 (例如，A, 2, 3, ..., 10, J, Q, K)。
  ///
  /// 在這個遊戲中，我們只關心 2 到 10。
  final int value;

  /// 建立一張給定花色和數字的撲克牌。
  const PlayingCard(this.suit, this.value);

  /// 從 JSON 格式的資料建立一張撲克牌。
  factory PlayingCard.fromJson(Map<String, dynamic> json) {
    return PlayingCard(
      CardSuit.values.singleWhere(
        (e) => e.internalRepresentation == json['suit'],
      ),
      json['value'] as int,
    );
  }

  /// 建立一張隨機的撲克牌。主要用於測試。
  factory PlayingCard.random([Random? random]) {
    random ??= _random;
    return PlayingCard(
      CardSuit.values[random.nextInt(CardSuit.values.length)],
      // 在這個遊戲中，我們只關心 2 到 10 的牌。
      2 + random.nextInt(9),
    );
  }

  @override
  int get hashCode => Object.hash(suit, value);

  @override
  bool operator ==(Object other) {
    return other is PlayingCard && other.suit == suit && other.value == value;
  }

  /// 將此物件轉換為可被 `json.encode()` 編碼的格式。
  Map<String, dynamic> toJson() => {
        'suit': suit.internalRepresentation,
        'value': value,
      };

  @override
  String toString() {
    return '$suit$value';
  }
}
