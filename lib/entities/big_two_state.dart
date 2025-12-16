import 'package:json_annotation/json_annotation.dart';
import 'big_two_player.dart';
import 'participant_info.dart';

part 'big_two_state.g.dart';

@JsonSerializable(explicitToJson: true)
class BigTwoState {
  final List<BigTwoPlayer> participants;
  final List<String> seats;
  final String currentPlayerId;
  final List<String> lastPlayedHand;
  final String lastPlayedById;
  final String? winner;
  final int passCount;

  BigTwoState({
    required this.participants,
    required this.seats,
    required this.currentPlayerId,
    this.lastPlayedHand = const [],
    this.lastPlayedById = '',
    this.winner,
    this.passCount = 0,
  });

  factory BigTwoState.fromJson(Map<String, dynamic> json) =>
      _$BigTwoStateFromJson(json);

  Map<String, dynamic> toJson() => _$BigTwoStateToJson(this);
}
