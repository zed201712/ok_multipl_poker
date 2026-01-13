import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'card_suit.dart';

/// 代表一張撲克牌。
///
/// 一旦建立，撲克牌就是不可變的。
@immutable
class PlayingCard extends Equatable {
  static final _random = Random();

  /// 這張牌的花色。
  final CardSuit suit;

  /// 這張牌的數字 (例如，A, 2, 3, ..., 10, J, Q, K)。
  ///
  /// 在這個遊戲中，我們只關心 2 到 10。
  final int value;

  /// 建立一張給定花色和數字的撲克牌。
  const PlayingCard(this.suit, this.value);

  @override
  List<Object?> get props => [suit, value];

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
  
  factory PlayingCard.fromString(String cardStr) {
    final suitChar = cardStr.substring(0, 1);
    final value = int.parse(cardStr.substring(1));
    CardSuit suit;
    switch (suitChar) {
      case 'C': suit = CardSuit.clubs; break;
      case 'D': suit = CardSuit.diamonds; break;
      case 'H': suit = CardSuit.hearts; break;
      case 'S': suit = CardSuit.spades; break;
      default: throw ArgumentError('Invalid card string: $cardStr');
    }
    return PlayingCard(suit, value);
  }

  static PlayingCard joker1() {
    return PlayingCard(CardSuit.spades, 0);
  }

  static PlayingCard joker2() {
    return PlayingCard(CardSuit.hearts, 0);
  }

  /// Creates a full, shuffled deck of 52 cards.
  static List<PlayingCard> createDeck() {
    final List<PlayingCard> deck = [];
    for (final suit in CardSuit.values) {
      for (int value = 1; value <= 13; value++) {
        deck.add(PlayingCard(suit, value));
      }
    }
    deck.shuffle();
    return deck;
  }

  static List<PlayingCard> createDeck54() {
    final List<PlayingCard> deck = [];
    for (final suit in CardSuit.values) {
      for (int value = 1; value <= 13; value++) {
        deck.add(PlayingCard(suit, value));
      }
    }
    deck.add(PlayingCard.joker1());
    deck.add(PlayingCard.joker2());
    deck.shuffle();
    return deck;
  }
  
  static String cardToString(PlayingCard card) {
    String suitChar;
    switch (card.suit) {
      case CardSuit.clubs: suitChar = 'C'; break;
      case CardSuit.diamonds: suitChar = 'D'; break;
      case CardSuit.hearts: suitChar = 'H'; break;
      case CardSuit.spades: suitChar = 'S'; break;
    }
    return '$suitChar${card.value}';
  }

  bool isJoker() {
    return value == 0;
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
    // A simple string representation, e.g., '♠10' for the 10 of spades.
    return isJoker() ? 'Joker' : '$suit${_valueToString()}';
  }

  String _valueToString() {
    switch (value) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return value.toString();
    }
  }
}

extension StringCardArray on List<String> {
  List<PlayingCard> toPlayingCards() {
    return map(PlayingCard.fromString).toList();
  }
}

extension PlayingCardArray on List<PlayingCard> {
  List<String> toStringCards() {
    return map(PlayingCard.cardToString).toList();
  }
}