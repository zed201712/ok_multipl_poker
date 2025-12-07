import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';

/// Represents the generic state of a turn-based game.
///
/// @param T The type of the custom game state object, managed by a delegate.
class TurnBasedGameState<T> {
  final String gameStatus; // e.g., 'waiting', 'playing', 'finished'
  final List<String> turnOrder;
  final String? currentPlayerId;
  final String? winner;
  final T customState;

  TurnBasedGameState({
    required this.gameStatus,
    required this.turnOrder,
    this.currentPlayerId,
    this.winner,
    required this.customState,
  });

  /// Creates a copy of the state with new values.
  TurnBasedGameState<T> copyWith({
    String? gameStatus,
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
    return TurnBasedGameState(
      gameStatus: json['gameStatus'] as String,
      turnOrder: (json['turnOrder'] as List).map((e) => e as String).toList(),
      currentPlayerId: json['currentPlayerId'] as String?,
      winner: json['winner'] as String?,
      customState: delegate.stateFromJson(json['customState'] as Map<String, dynamic>),
    );
  }

  /// Converts the TurnBasedGameState instance to a JSON object.
  /// Requires a delegate to serialize the custom game state part.
  Map<String, dynamic> toJson(TurnBasedGameDelegate<T> delegate) {
    return {
      'gameStatus': gameStatus,
      'turnOrder': turnOrder,
      'currentPlayerId': currentPlayerId,
      'winner': winner,
      'customState': delegate.stateToJson(customState),
    };
  }
}
