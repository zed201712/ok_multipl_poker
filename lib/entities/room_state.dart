import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'room.dart';
import 'room_request.dart';
import 'room_response.dart';

part 'room_state.g.dart';

@JsonSerializable(explicitToJson: true)
class RoomState extends Equatable {
  final Room? room;
  final List<RoomRequest> requests;
  final List<RoomResponse> responses;

  const RoomState({
    this.room,
    this.requests = const [],
    this.responses = const [],
  });

  RoomState copyWith({
    Room? room,
    List<RoomRequest>? requests,
    List<RoomResponse>? responses,
  }) {
    return RoomState(
      room: room ?? this.room,
      requests: requests ?? this.requests,
      responses: responses ?? this.responses,
    );
  }

  @override
  List<Object?> get props => [room, requests, responses];


  factory RoomState.fromJson(Map<String, dynamic> json) =>
      _$RoomStateFromJson(json);

  Map<String, dynamic> toJson() => _$RoomStateToJson(this);
}
