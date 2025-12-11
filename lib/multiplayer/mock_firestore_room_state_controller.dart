import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_room_state_controller.dart';
import 'package:rxdart/rxdart.dart';

import '../entities/room.dart';
import '../entities/room_request.dart';
import '../entities/room_response.dart';
import '../entities/room_state.dart';

class MockFirestoreRoomStateController implements FirestoreRoomStateController {
  // --- Mock-specific properties for state control ---
  final _rooms = <Room>[];
  final _requests = <String, List<RoomRequest>>{};
  final _responses = <String, List<RoomResponse>>{};

  // --- BehaviorSubjects to mimic streams ---
  final _roomsController = BehaviorSubject<List<Room>>.seeded([]);
  final _roomStateController = BehaviorSubject<RoomState?>.seeded(null);
  final _userIdController = BehaviorSubject<String?>.seeded('mock_user_id${const Uuid().v4()}');

  // --- Constructor ---
  MockFirestoreRoomStateController() {
    // Initialization logic if any
  }

  void printJson() {
    final data = {
      'rooms': _rooms.map((e) => e.toJson()).toList(),
      'requests': _requests.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList())),
      'responses': _responses.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList())),
    };

    final encoder = JsonEncoder.withIndent('  ', (object) {
      if (object is Timestamp) {
        return object.toDate().toIso8601String();
      }
      return object;
    });

    print(encoder.convert(data));
  }


  // --- Implementation of the public interface ---
  @override
  ValueStream<List<Room>> get roomsStream => _roomsController.stream;

  @override
  ValueStream<RoomState?> get roomStateStream => _roomStateController.stream;

  @override
  ValueStream<String?> get userIdStream => _userIdController.stream;

  @override
  String? get currentUserId => _userIdController.value;

  @override
  Future<String> createRoom({
    String? roomId,
    required String title,
    required int maxPlayers,
    required String matchMode,
    required String visibility,
  }) async {
    final creatorUid = currentUserId;
    if (creatorUid == null) {
      throw Exception('User not authenticated.');
    }

    final docId = (roomId != null && roomId.isNotEmpty) ? roomId : 'mock_room_${_rooms.length}';

    final room = Room(
      roomId: docId,
      creatorUid: creatorUid,
      managerUid: creatorUid,
      title: title,
      maxPlayers: maxPlayers,
      state: 'open',
      body: '',
      matchMode: matchMode,
      visibility: visibility,
      participants: [creatorUid],
      seats: [creatorUid],
      createdAt: _currentTimestamp(),
      updatedAt: _currentTimestamp(),
    );

    _rooms.add(room);
    _roomsController.add(List.from(_rooms));
    _updateRoomState(docId);
    return docId;
  }

  @override
  Future<void> updateRoom({
    required String roomId,
    required Map<String, Object?> data,
  }) async {
    final index = _rooms.indexWhere((r) => r.roomId == roomId);
    if (index != -1) {
      // This is a simplified update. A real implementation would need to handle
      // nested fields and various data types.
      final existingRoom = _rooms[index];
      // A proper implementation would merge `data` with the room's properties.
      // For now, we just update the timestamp
      _rooms[index] = existingRoom.copyWith(updatedAt: _currentTimestamp());
      _roomsController.add(List.from(_rooms));
      _updateRoomState(roomId);
    }
  }

  @override
  Future<void> deleteRoom({required String roomId}) async {
    _rooms.removeWhere((r) => r.roomId == roomId);
    _roomsController.add(List.from(_rooms));
    final currentRoomState = _roomStateController.value;
    if (currentRoomState != null && currentRoomState.room?.roomId == roomId) {
      _roomStateController.add(null);
    }
  }

  @override
  void dispose() {
    _roomsController.close();
    _roomStateController.close();
    _userIdController.close();
  }

  @override
  Future<void> handoverRoomManager({required String roomId}) async {
    final roomIndex = _rooms.indexWhere((r) => r.roomId == roomId);
    if (roomIndex == -1) {
      throw Exception('Room not found.');
    }
    var room = _rooms[roomIndex];
    final currentManagerId = room.managerUid;
    final otherParticipants = room.participants.where((p) => p != currentManagerId).toList();

    if (otherParticipants.isNotEmpty) {
      final newManagerId = otherParticipants.first;
      room = room.copyWith(managerUid: newManagerId, updatedAt: _currentTimestamp());
      _rooms[roomIndex] = room;
      _roomsController.add(List.from(_rooms));
      _updateRoomState(roomId);
    } else {
      // If no one else is in the room, delete it.
      await deleteRoom(roomId: roomId);
    }
  }

  @override
  Future<String> matchRoom(
      {required String title, required int maxPlayers, required String matchMode, required String visibility}) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated.');
    }

    final availableRoomIndex = _rooms.indexWhere((r) =>
        r.state == 'open' && r.visibility == 'public' && r.participants.length < r.maxPlayers);

    if (availableRoomIndex != -1) {
      var room = _rooms[availableRoomIndex];
      final newParticipants = List<String>.from(room.participants)..add(userId);
      final newSeats = List<String>.from(room.seats)..add(userId);
      room = room.copyWith(participants: newParticipants, seats: newSeats, updatedAt: _currentTimestamp());
      _rooms[availableRoomIndex] = room;

      _roomsController.add(List.from(_rooms));
      _updateRoomState(room.roomId);
      return room.roomId;
    } else {
      return await createRoom(
        title: title,
        maxPlayers: maxPlayers,
        matchMode: matchMode,
        visibility: 'public',
      );
    }
  }

  @override
  void setRoomId(String? roomId) {
    if (roomId == null) {
      _roomStateController.add(null);
      return;
    }
    final room = _rooms.firstWhereOrNull((r) => r.roomId == roomId);
    if (room != null) {
      _roomStateController.add(RoomState(
        room: room,
        requests: _requests[roomId] ?? [],
        responses: _responses[roomId] ?? [],
      ));
    } else {
       _roomStateController.add(null);
    }
  }

  @override
  Future<String> sendRequest({required String roomId, required Map<String, dynamic> body}) async {
    final participantId = currentUserId;
    if (participantId == null) {
      throw Exception('User not authenticated.');
    }
    final request = RoomRequest(
      requestId: 'mock_request_${const Uuid().v4()}',
      roomId: roomId,
      participantId: participantId,
      body: body,
      createdAt: _currentTimestamp(),
    );
    _requests.putIfAbsent(roomId, () => []).add(request);
    _updateRoomState(roomId);
    return request.requestId;
  }


  @override
  Future<void> deleteRequest({required String roomId, required String requestId}) async {
    _requests[roomId]?.removeWhere((req) => req.requestId == requestId);
    _updateRoomState(roomId);
  }

  @override
  Future<String> sendResponse({required String roomId, required String requestId, required Map<String, dynamic> body}) async {
    final participantId = currentUserId;
    if (participantId == null) {
      throw Exception('User not authenticated.');
    }
    final response = RoomResponse(
      responseId: 'mock_response_${const Uuid().v4()}',
      requestId: requestId,
      roomId: roomId,
      participantId: participantId,
      body: body,
      createdAt: _currentTimestamp(),
    );
    _responses.putIfAbsent(roomId, () => []).add(response);
    _updateRoomState(roomId);
    return response.responseId;
  }

  @override
  Future<void> deleteResponse({required String roomId, required String responseId}) async {
    _responses[roomId]?.removeWhere((res) => res.responseId == responseId);
    _updateRoomState(roomId);
  }
  
  void _updateRoomState(String roomId) {
    final room = _rooms.firstWhereOrNull((r) => r.roomId == roomId);
    final currentRoomState = _roomStateController.value;
    if (room != null && currentRoomState != null && currentRoomState.room?.roomId == roomId) {
      _roomStateController.add(RoomState(
        room: room,
        requests: _requests[roomId] ?? [],
        responses: _responses[roomId] ?? [],
      ));
    }
  }

  // --- Mock-specific helper methods for testing ---
  void addRoom(Room room) {
    _rooms.add(room);
    _roomsController.add(List.from(_rooms));
  }

  void clear() {
    _rooms.clear();
    _requests.clear();
    _responses.clear();
    _roomsController.add([]);
    _roomStateController.add(null);
  }

  @override
  Future<void> leaveRoom({required String roomId}) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated.');
    }

    final roomIndex = _rooms.indexWhere((r) => r.roomId == roomId);
    if (roomIndex == -1) {
      // Room already gone, do nothing.
      return;
    }
    var room = _rooms[roomIndex];

    final newParticipants = room.participants.where((p) => p != userId).toList();
    final newSeats = room.seats.where((p) => p != userId).toList();
    
    room = room.copyWith(
      participants: newParticipants,
      seats: newSeats,
      updatedAt: _currentTimestamp(),
    );
    _rooms[roomIndex] = room;


    if (room.managerUid == userId) {
      if (newParticipants.isNotEmpty) {
        await handoverRoomManager(roomId: roomId);
      } else {
        await deleteRoom(roomId: roomId);
        return; 
      }
    }
    
    _roomsController.add(List.from(_rooms));
    _updateRoomState(roomId);
    await sendRequest(roomId: roomId, body: {'action': 'leave'});
  }

  @override
  Future<void> requestToJoinRoom({required String roomId}) async {
    await sendRequest(roomId: roomId, body: {'action': 'request_to_join'});
  }
  
  @override
  Future<void> sendAlivePing({required String roomId}) async {
    final roomIndex = _rooms.indexWhere((r) => r.roomId == roomId);
    if (roomIndex != -1) {
      var room = _rooms[roomIndex];
      _rooms[roomIndex] = room.copyWith(updatedAt: _currentTimestamp());
      _roomsController.add(List.from(_rooms));
      _updateRoomState(roomId);
    }
    // Silently ignore if room not found
  }

  Timestamp _currentTimestamp() => Timestamp.fromDate(DateTime.now());
}