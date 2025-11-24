import 'dart:async';

import 'package:async/async.dart';

import 'playing_card.dart';

/// 代表遊戲中可以放置卡牌的區域。
class PlayingArea {
  /// 此遊戲區域中卡牌的最大數量。
  static const int maxCards = 6;

  /// 此區域中目前的卡牌。
  final List<PlayingCard> cards = [];

  final StreamController<void> _playerChanges =
      StreamController<void>.broadcast();

  final StreamController<void> _remoteChanges =
      StreamController<void>.broadcast();

  PlayingArea();

  /// 一個 [Stream]，每當此區域發生任何變更時，就會觸發一個事件。
  Stream<void> get allChanges =>
      StreamGroup.mergeBroadcast([remoteChanges, playerChanges]);

  /// 一個 [Stream]，每當玩家在_本地_進行變更時，就會觸發一個事件。
  Stream<void> get playerChanges => _playerChanges.stream;

  /// 一個 [Stream]，每當其他玩家在_遠端_進行變更時，就會觸發一個事件。
  Stream<void> get remoteChanges => _remoteChanges.stream;

  /// 將 [card] 接收到此區域中。
  void acceptCard(PlayingCard card) {
    cards.add(card);
    _maybeTrim();
    _playerChanges.add(null);
  }

  void dispose() {
    _remoteChanges.close();
    _playerChanges.close();
  }

  /// 移除區域中的第一張卡牌（如果有的話）。
  void removeFirstCard() {
    if (cards.isEmpty) return;
    cards.removeAt(0);
    _playerChanges.add(null);
  }

  /// 將區域中的卡牌替換為 [cards]。
  ///
  /// 這個方法適用於從伺服器更新卡牌時呼叫。
  void replaceWith(List<PlayingCard> cards) {
    this.cards.clear();
    this.cards.addAll(cards);
    _maybeTrim();
    _remoteChanges.add(null);
  }

  void _maybeTrim() {
    if (cards.length > maxCards) {
      cards.removeRange(0, cards.length - maxCards);
    }
  }
}
