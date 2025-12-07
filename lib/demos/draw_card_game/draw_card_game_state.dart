import 'package:ok_multipl_poker/game_internals/playing_card.dart';

class DrawCardGameState {
  // Maps player IDs to the card they have drawn.
  final Map<String, PlayingCard?> playerCards;

  DrawCardGameState({required this.playerCards});

  factory DrawCardGameState.fromJson(Map<String, dynamic> json) {
    final playerCards = (json['playerCards'] as Map<String, dynamic>).map(
      (key, value) {
        if (value == null) {
          return MapEntry(key, null);
        }
        return MapEntry(
          key, 
          PlayingCard.fromJson(value as Map<String, dynamic>)
        );
      },
    );
    return DrawCardGameState(playerCards: playerCards);
  }

  Map<String, dynamic> toJson() {
    final playerCardsJson = playerCards.map(
      (key, value) => MapEntry(key, value?.toJson()),
    );
    return {
      'playerCards': playerCardsJson,
    };
  }
}
