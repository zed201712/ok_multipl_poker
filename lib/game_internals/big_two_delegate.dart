import 'package:ok_multipl_poker/entities/big_two_player.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';

class BigTwoDelegate extends TurnBasedGameDelegate<BigTwoState> {
  @override
  BigTwoState initializeGame(Room room) {
    final deck = PlayingCard.createDeck();
    final players = <BigTwoPlayer>[];
    final seats = room.seats;

    // Distribute cards to players
    final cardsPerPlayer = (deck.length / seats.length).floor();
    for (int i = 0; i < seats.length; i++) {
      final hand = deck.sublist(i * cardsPerPlayer, (i + 1) * cardsPerPlayer);
      players.add(BigTwoPlayer(
        uid: seats[i],
        name: room.participants.firstWhere((p) => p.id == seats[i]).name,
        cards: hand.map(PlayingCard.cardToString).toList(),
      ));
    }

    // Find who has the 3 of clubs to start
    String? startingPlayerId;
    for (var player in players) {
      if (player.cards.contains('C3')) {
        startingPlayerId = player.uid;
        break;
      }
    }

    return BigTwoState(
      participants: players,
      seats: seats,
      currentPlayerId: startingPlayerId ?? seats.first,
    );
  }

  BigTwoPlayer myPlayer(String myUserId, BigTwoState bigTwoState) => bigTwoState.participants.firstWhere((p) => p.uid == myUserId);

  List<BigTwoPlayer> otherPlayers(String myUserId, BigTwoState bigTwoState) => bigTwoState.participants.where((p) => p.uid != myUserId).toList();

  @override
  BigTwoState processAction(
      BigTwoState currentState, String action, String playerId, Map<String, dynamic> payload) {
    if (action == 'play_hand') {
      // TODO: Implement hand validation and game logic
      return currentState; // Placeholder
    } else if (action == 'pass') {
      // TODO: Implement pass logic
      return currentState; // Placeholder
    }
    return currentState;
  }

  @override
  String? getCurrentPlayer(BigTwoState state) {
    return state.currentPlayerId;
  }

  @override
  String? getWinner(BigTwoState state) {
    return state.winner;
  }

  @override
  BigTwoState stateFromJson(Map<String, dynamic> json) {
    return BigTwoState.fromJson(json);
  }

  @override
  Map<String, dynamic> stateToJson(BigTwoState state) {
    return state.toJson();
  }
}
