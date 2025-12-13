import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ok_multipl_poker/multiplayer/game_status.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';
import 'dart:convert';
/// Represents the generic state of a turn-based game.
///
/// @param T The type of the custom game state object, managed by a delegate.
class TurnBasedGameState<T> {
  final GameStatus gameStatus; // e.g., 'waiting', 'playing', 'finished'
  final List<String> turnOrder;
  final String? currentPlayerId;
  final String? winner;
  final T customState;

  TurnBasedGameState({
    this.gameStatus = GameStatus.idle,
    required this.turnOrder,
    this.currentPlayerId,
    this.winner,
    required this.customState,
  });

  /// Creates a copy of the state with new values.
  TurnBasedGameState<T> copyWith({
    GameStatus? gameStatus,
    List<String>? turnOrder,
    String? currentPlayerId,
    String? winner,
    T? customState,
  }) {
    return TurnBasedGameState(
      gameStatus: gameStatus ?? this.gameStatus,
      turnOrder: turnOrder ?? this.turnOrder,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      winner: winner ?? this.winner,
      customState: customState ?? this.customState,
    );
  }

  /// Creates a TurnBasedGameState instance from a JSON object.
  /// Requires a delegate to deserialize the custom game state part.
  factory TurnBasedGameState.fromJson(
      Map<String, dynamic> json, TurnBasedGameDelegate<T> delegate) {
    String gameStatusName = json['gameStatus'] is String
        ? json['gameStatus']
        : "";
    return TurnBasedGameState(
      gameStatus: GameStateX.fromName(gameStatusName),
      turnOrder: (json['turnOrder'] as List).map((e) => e as String).toList(),
      currentPlayerId: json['currentPlayerId'] as String?,
      winner: json['winner'] as String?,
      customState:
          delegate.stateFromJson(json['customState'] as Map<String, dynamic>),
    );
  }

  /// Converts the TurnBasedGameState instance to a JSON object.
  /// Requires a delegate to serialize the custom game state part.
  Map<String, dynamic> toJson(TurnBasedGameDelegate<T> delegate) {
    return {
      'gameStatus': gameStatus.name,
      'turnOrder': turnOrder,
      'currentPlayerId': currentPlayerId,
      'winner': winner,
      'customState': delegate.stateToJson(customState),
    };
  }

  String forPrintJson(TurnBasedGameDelegate<T> delegate) {
    final data ={
      'gameStatus': gameStatus.name,
      'turnOrder': turnOrder,
      'currentPlayerId': currentPlayerId,
      'customState': delegate.stateToJson(customState)
    };
    final encoder = JsonEncoder.withIndent('  ', (object) {
      if (object is Timestamp) {
        return object.toDate().toIso8601String();
      }
      return object;
    });
    return encoder.convert(data);
  }

  // void printJson() {
  //   final data = {
  //     'rooms': _rooms.map((e) => e.toJson()).toList(),
  //     'requests': _requests.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList())),
  //     'responses': _responses.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList())),
  //   };
  //
  //   final encoder = JsonEncoder.withIndent('  ', (object) {
  //     if (object is Timestamp) {
  //       return object.toDate().toIso8601String();
  //     }
  //     return object;
  //   });
  //
  //   print(encoder.convert(data));
  // }
}
