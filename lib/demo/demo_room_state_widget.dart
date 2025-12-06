import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ok_multipl_poker/entities/room_state.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_room_state_controller.dart';

import '../entities/room.dart';
import '../entities/room_request.dart';

class DemoRoomStateWidget extends StatefulWidget {
  const DemoRoomStateWidget({super.key});

  @override
  State<DemoRoomStateWidget> createState() => _DemoRoomStateWidgetState();
}

class _DemoRoomStateWidgetState extends State<DemoRoomStateWidget> {
  // Controllers for text fields
  final _roomTitleController = TextEditingController(text: 'Test Room');
  final _maxPlayersController = TextEditingController(text: '4');
  final _roomIdController = TextEditingController();

  // Firebase and Controller instances
  late final FirestoreRoomStateController _roomController;

  // State variables
  String? _userId;
  StreamSubscription<RoomState?>? _roomStateSubscription;
  StreamSubscription<String?>? _userIdSubscription;
  RoomState? _currentRoomState;

  @override
  void initState() {
    super.initState();
    _roomController = FirestoreRoomStateController(
        FirebaseFirestore.instance, FirebaseAuth.instance, 'rooms');

    _roomIdController.addListener(_onRoomIdChanged);

    // Listen to the new roomStateStream
    _roomStateSubscription = _roomController.roomStateStream.listen((roomState) {
      if (mounted) {
        setState(() {
          _currentRoomState = roomState;
        });
      }
    });

    // Listen to the userIdStream
    _userIdSubscription = _roomController.userIdStream.listen((userId) {
      if (mounted) {
        setState(() {
          _userId = userId;
        });
      }
    });
  }

  @override
  void dispose() {
    _roomIdController.removeListener(_onRoomIdChanged);
    _roomStateSubscription?.cancel();
    _userIdSubscription?.cancel();
    _roomController.dispose(); // Dispose the controller!
    _roomTitleController.dispose();
    _maxPlayersController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  void _onRoomIdChanged() {
    // When the text controller changes, update the controller's target room ID
    _roomController.setRoomId(_roomIdController.text);
  }

  void _handleRoomTap(Room room) {
    _roomIdController.text = room.roomId;
    _roomTitleController.text = room.title;
  }

  Future<void> _createRoom() async {
    final newRoomId = await _roomController.createRoom(
      roomId: _roomIdController.text.isEmpty ? null : _roomIdController.text,
      title: _roomTitleController.text,
      maxPlayers: int.tryParse(_maxPlayersController.text) ?? 4,
      matchMode: 'casual',
      visibility: 'public',
    );
    if (mounted) {
      _roomIdController.text = newRoomId; // This will trigger _onRoomIdChanged
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room created: $newRoomId')),
      );
    }
  }

  Future<void> _requestToJoin() async {
    final roomId = _roomIdController.text;
    if (roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a room first.')),
      );
      return;
    }
    await _roomController.requestToJoinRoom(
      roomId: roomId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request sent.')),
      );
    }
  }

  Future<void> _matchRoom() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not initialized yet.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Searching for a room...')),
    );

    final roomId = await _roomController.matchRoom(
      title: _roomTitleController.text,
      maxPlayers: int.tryParse(_maxPlayersController.text) ?? 4,
      matchMode: 'casual',
      visibility: 'public',
    );

    if (mounted) {
      _roomIdController.text = roomId; // This will trigger _onRoomIdChanged
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Matched! Joined room: $roomId')),
      );
    }
  }

  Future<void> _leaveRoom() async {
    final roomId = _roomIdController.text;
    if (roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a room ID to leave.')),
      );
      return;
    }

    await _roomController.leaveRoom(
      roomId: roomId,
    );

    if (mounted) {
      _roomIdController.text = ''; // Clear the room ID, this triggers _onRoomIdChanged
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have left the room.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManager = _userId != null && _currentRoomState?.room?.managerUid == _userId;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User ID: ${_userId ?? "Initializing..."}'),
          const Divider(),

          // Room Selection / Creation
          TextField(
              controller: _roomIdController,
              decoration: const InputDecoration(hintText: 'Room ID')),
          TextField(
              controller: _roomTitleController,
              decoration: const InputDecoration(hintText: 'Room Title')),
          ElevatedButton(
              onPressed: _createRoom, child: const Text('Create Room')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _matchRoom,
                  child: const Text('Match Room'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _leaveRoom,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Leave Room'),
                ),
              ),
            ],
          ),
          const Divider(height: 30),

          // All Rooms List
          Text('All Rooms (Live)',
              style: Theme.of(context).textTheme.titleLarge),
          SizedBox(
            height: 200,
            child: RoomsListWidget(
              roomsStream: _roomController.roomsStream,
              onRoomTap: _handleRoomTap,
            ),
          ),
          const Divider(height: 30),

          // Room Info Section
          _buildRoomInfo(),
          const Divider(height: 30),

          // Actions Section
          if (!isManager && _roomIdController.text.isNotEmpty)
            ElevatedButton(
                onPressed: _requestToJoin,
                child: const Text('Request to Join Room')),

          // Manager Section
          if (isManager) _buildManagerView(),
        ],
      ),
    );
  }

  Widget _buildRoomInfo() {
    final room = _currentRoomState?.room;
    if (room == null) {
      return const Text('Select a room from the list above or create a new one.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Room Details (Live)',
            style: Theme.of(context).textTheme.titleLarge),
        Text('Body: ${room.body}'),
        Text('Manager: ${room.managerUid}'),
        Text('Participants: ${room.participants.join(", ")}'),
        Text('Seats: ${room.seats.join(", ")}'),
      ],
    );
  }

  Widget _buildManagerView() {
    final requests = _currentRoomState?.requests ?? [];
    final joinRequests =
        requests.where((req) => req.body['action'] == 'join').toList();

    if (joinRequests.isEmpty) {
      return const Text('No pending join requests.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Join Requests', style: Theme.of(context).textTheme.titleLarge),
        ...joinRequests.map((request) {
          return Card(
            child: ListTile(
              title: Text('Requester: ${request.participantId}'),
              subtitle: Text('Action: ${request.body['action']}'),
            ),
          );
        }),
      ],
    );
  }
}

// A widget to display a clickable list of rooms
class RoomsListWidget extends StatelessWidget {
  final Stream<List<Room>> roomsStream;
  final Function(Room room) onRoomTap;

  const RoomsListWidget({
    Key? key,
    required this.roomsStream,
    required this.onRoomTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Room>>(
      stream: roomsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rooms = snapshot.data ?? [];
        if (rooms.isEmpty) {
          return const Center(child: Text('No rooms found. Create one!'));
        }
        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return Card(
              child: ListTile(
                title: Text(room.title),
                subtitle: Text('ID: ${room.roomId}'),
                onTap: () => onRoomTap(room),
              ),
            );
          },
        );
      },
    );
  }
}
