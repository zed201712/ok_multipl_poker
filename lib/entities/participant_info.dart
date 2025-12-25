import 'package:json_annotation/json_annotation.dart';

part 'participant_info.g.dart';

@JsonSerializable()
class ParticipantInfo {
  final String id;
  final String name;
  final String avatarNumber;

  ParticipantInfo({
    required this.id,
    required this.name,
    this.avatarNumber = '1',
  });

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) =>
      _$ParticipantInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipantInfoToJson(this);
}
