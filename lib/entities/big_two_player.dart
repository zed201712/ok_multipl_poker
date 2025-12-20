import 'package:json_annotation/json_annotation.dart';

part 'big_two_player.g.dart';

@JsonSerializable()
class BigTwoPlayer {
  final String uid;
  final String name;
  final List<String> cards;
  final bool hasPassed;

  BigTwoPlayer({
    required this.uid,
    required this.cards,
    required this.name,
    this.hasPassed = false,
  });

  factory BigTwoPlayer.fromJson(Map<String, dynamic> json) =>
      _$BigTwoPlayerFromJson(json);

  Map<String, dynamic> toJson() => _$BigTwoPlayerToJson(this);

  BigTwoPlayer copyWith({
    String? uid,
    String? name,
    List<String>? cards,
    bool? hasPassed,
  }) {
    return BigTwoPlayer(
        uid: uid ?? this.uid,
        cards: cards ?? this.cards,
        name: name ?? this.name,
        hasPassed: hasPassed ?? this.hasPassed,
    );
  }
}
