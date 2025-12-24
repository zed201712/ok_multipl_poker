import '../entities/room.dart';

/// Delegate for handling game-specific logic in a turn-based game.
///
/// Implement this class to define the rules of your specific game.
///
/// @param T The type of the custom game state object.
abstract class TurnBasedGameDelegate<T> {
  /// Creates and returns the initial state of the game based on the players.
  T initializeGame(Room room);

  /// Processes a player's action and returns the updated game state.
  ///
  /// This is where you implement the core rules of your game,
  /// such as validating moves, updating scores, and determining the next player.
  T processAction(
      Room room, T currentState, String action, String playerId, Map<String, dynamic> payload);

  // --- State Querying Methods ---
  // These methods allow the generic controller to query the specific state.

  /// Returns the ID of the player whose turn it is.
  String? getCurrentPlayer(T state);

  /// Returns the ID of the winner, if the game has ended.
  String? getWinner(T state);

  // --- Serialization ---

  /// Deserializes the custom game state from JSON.
  T stateFromJson(Map<String, dynamic> json);

  /// Serializes the custom game state to JSON.
  Map<String, dynamic> stateToJson(T state);
}
