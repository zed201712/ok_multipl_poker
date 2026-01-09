import 'package:json_annotation/json_annotation.dart';

part 'poker_player.g.dart';

@JsonSerializable()
class PokerPlayer {
  final String uid;
  final String name;
  final List<String> cards;
  final int avatarNumber;

  PokerPlayer({
    required this.uid,
    required this.cards,
    required this.name,
    this.avatarNumber = 0,
  });

  factory PokerPlayer.fromJson(Map<String, dynamic> json) =>
      _$PokerPlayerFromJson(json);

  Map<String, dynamic> toJson() => _$PokerPlayerToJson(this);

  PokerPlayer copyWith({
    String? uid,
    String? name,
    List<String>? cards,
    int? avatarNumber,
  }) {
    return PokerPlayer(
      uid: uid ?? this.uid,
      cards: cards ?? this.cards,
      name: name ?? this.name,
      avatarNumber: avatarNumber ?? this.avatarNumber,
    );
  }
}
