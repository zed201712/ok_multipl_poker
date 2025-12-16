import 'package:json_annotation/json_annotation.dart';

part 'participant_info.g.dart';

@JsonSerializable()
class ParticipantInfo {
  final String id;
  final String name;

  ParticipantInfo({
    required this.id,
    required this.name,
  });

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) =>
      _$ParticipantInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipantInfoToJson(this);
}
