import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/entities/room_state.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';

abstract class BigTwoAI {
  String get aiUserId;
  void updateState(TurnBasedGameState<BigTwoState> gameState, RoomState roomState);
  void dispose();
}
