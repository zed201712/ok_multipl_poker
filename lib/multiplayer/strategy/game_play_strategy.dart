abstract class GamePlayStrategy {
  Future<String?> matchRoom();
  Future<void> startGame();
  Future<void> restart();
  Future<void> leaveRoom();
  Future<void> endRoom();
  Future<void> sendGameAction(String action, {Map<String, dynamic>? payload});
}
