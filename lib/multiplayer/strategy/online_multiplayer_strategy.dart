import '../firestore_turn_based_game_controller.dart';
import '../turn_based_game_state.dart';
import 'game_play_strategy.dart';

class OnlineMultiplayerStrategy<T extends TurnBasedCustomState> implements GamePlayStrategy {
  final FirestoreTurnBasedGameController<T> _gameController;

  OnlineMultiplayerStrategy(this._gameController);

  @override
  Future<String?> matchRoom() async {
    try {
      final roomId = await _gameController.matchAndJoinRoom(maxPlayers: 6);
      return roomId;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> startGame() async {
    await _gameController.startGame();
  }

  @override
  Future<void> restart() async {
    _gameController.sendGameAction('request_restart');
  }

  @override
  Future<void> leaveRoom() async {
    await _gameController.leaveRoom();
  }

  @override
  Future<void> endRoom() async {
    await _gameController.endRoom();
  }

  @override
  Future<void> sendGameAction(String action, {Map<String, dynamic>? payload}) async {
    _gameController.sendGameAction(action, payload: payload);
  }
}
