import '../BotContext.dart';
import 'game_play_strategy.dart';

class BotGameStrategy<T extends Object> implements GamePlayStrategy {
  final BotContext<dynamic> _botContext;

  BotGameStrategy(this._botContext);

  @override
  Future<String?> matchRoom() async {
    _botContext.createRoom();
    return 'bot_room';
  }

  @override
  Future<void> startGame() async {
    _botContext.startGame();
  }

  @override
  Future<void> restart() async {
    _botContext.createRoom();
    _botContext.startGame();
  }

  @override
  Future<void> leaveRoom() async {
    // No-op for bot game
  }

  @override
  Future<void> endRoom() async {
    // No-op for bot game
  }

  @override
  Future<void> sendGameAction(String action, {Map<String, dynamic>? payload}) async {
    _botContext.sendAction(action, payload: payload);
  }
}
