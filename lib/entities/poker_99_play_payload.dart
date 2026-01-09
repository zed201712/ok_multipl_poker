import 'package:json_annotation/json_annotation.dart';
import 'package:ok_multipl_poker/game_internals/poker_99_action.dart';

part 'poker_99_play_payload.g.dart';

@JsonSerializable()
class Poker99PlayPayload {
  final List<String> cards;
  final Poker99Action action;
  final int value;
  final String targetPlayerId;

  Poker99PlayPayload({
    required this.cards,
    required this.action,
    this.value = 0,
    this.targetPlayerId = '',
  });

  factory Poker99PlayPayload.fromJson(Map<String, dynamic> json) =>
      _$Poker99PlayPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$Poker99PlayPayloadToJson(this);
}
