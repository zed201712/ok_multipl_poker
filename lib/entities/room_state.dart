import 'package:equatable/equatable.dart';

import 'room.dart';
import 'room_request.dart';
import 'room_response.dart';

class RoomState extends Equatable {
  final Room? room;
  final List<RoomRequest> requests;
  final List<RoomResponse> responses;

  const RoomState({
    this.room,
    this.requests = const [],
    this.responses = const [],
  });

  @override
  List<Object?> get props => [room, requests, responses];
}
