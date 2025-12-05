import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final _auth = FirebaseAuth.instance;
  late final FirestoreRoomStateController _roomController;

  // State variables
  String _userId = '';
  String _managerId = '';
  Stream<Room?>? _roomStream;
  Stream<List<RoomRequest>>? _requestsStream;
  Stream<List<Room>>? _allRoomsStream;

  @override
  void initState() {
    super.initState();
    _roomController = FirestoreRoomStateController(FirebaseFirestore.instance);
    _initUser();
    _roomIdController.addListener(_onRoomIdChanged);
  }

  @override
  void dispose() {
    _roomIdController.removeListener(_onRoomIdChanged);
    _roomTitleController.dispose();
    _maxPlayersController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  Future<void> _initUser() async {
    User? user = _auth.currentUser;
    user ??= (await _auth.signInAnonymously()).user;
    _allRoomsStream = _roomController.roomsStream(); // Initialize the stream for all rooms
    if (mounted) {
      setState(() {
        _userId = user!.uid;
      });
    }
  }

  void _onRoomIdChanged() {
    final roomId = _roomIdController.text;
    if (roomId.isEmpty) {
      setState(() {
        _roomStream = null;
        _requestsStream = null;
        _managerId = '';
      });
      return;
    }
    setState(() {
      _roomStream = _roomController.roomStream(roomId: roomId);
      _requestsStream = _roomController.getRequestsStream(roomId: roomId);
      _roomStream?.listen((room) {
        if (room != null && mounted) {
          setState(() {
            _managerId = room.managerUid;
          });
        }
      });
    });
  }

  void _handleRoomTap(Room room) {
    _roomIdController.text = room.roomId;
    _roomTitleController.text = room.title;
  }

  Future<void> _createRoom() async {
    final newRoomId = await _roomController.createRoom(
      roomId: _roomIdController.text.isEmpty ? null : _roomIdController.text,
      creatorUid: _userId,
      title: _roomTitleController.text,
      maxPlayers: int.tryParse(_maxPlayersController.text) ?? 4,
      matchMode: 'casual',
      visibility: 'public',
    );
    if (mounted) {
      setState(() {
        _roomIdController.text = newRoomId;
      });
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
    await _roomController.sendRequest(
      roomId: roomId,
      participantId: _userId,
      body: {'action': 'join'},
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request sent.')),
      );
    }
  }

  Future<void> _approveRequest(RoomRequest request, Room currentRoom) async {
    final newParticipants = List<String>.from(currentRoom.participants);
    if (!newParticipants.contains(request.participantId)) {
      newParticipants.add(request.participantId);
    }
    await _roomController.updateRoom(
      roomId: currentRoom.roomId,
      data: {'participants': newParticipants},
    );

    await _roomController.updateRoomBody(
      roomId: currentRoom.roomId,
      body: 'updated: $_managerId, requesterId: ${request.participantId}',
    );

    await _roomController.deleteRequest(
        roomId: currentRoom.roomId, requestId: request.requestId);
  }

  @override
  Widget build(BuildContext context) {
    bool isManager = _userId.isNotEmpty && _userId == _managerId;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User ID: $_userId'),
          const Divider(),

          // Room Selection / Creation
          TextField(controller: _roomIdController, decoration: const InputDecoration(hintText: 'Room ID')),
          TextField(controller: _roomTitleController, decoration: const InputDecoration(hintText: 'Room Title')),
          ElevatedButton(onPressed: _createRoom, child: const Text('Create Room')),
          const Divider(height: 30),

          // All Rooms List
          Text('All Rooms (Live)', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(
            height: 200,
            child: RoomsListWidget(
              roomsStream: _allRoomsStream,
              onRoomTap: _handleRoomTap,
            ),
          ),
          const Divider(height: 30),
          
          // Room Info Section
          _buildRoomInfo(),
          const Divider(height: 30),

          // Actions Section
          if (!isManager && _roomIdController.text.isNotEmpty) 
            ElevatedButton(onPressed: _requestToJoin, child: const Text('Request to Join Room')),

          // Manager Section
          if (isManager) _buildManagerView(),
        ],
      ),
    );
  }

  Widget _buildRoomInfo() {
    return StreamBuilder<Room?>(
      stream: _roomStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Text('Select a room from the list above or create a new one.');
        }
        final room = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Room Details (Live)', style: Theme.of(context).textTheme.titleLarge),
            Text('Body: ${room.body}'),
            Text('Manager: ${room.managerUid}'),
            Text('Participants: ${room.participants.join(", ")}'),
            Text('Seats: ${room.seats.join(", ")}'),
          ],
        );
      },
    );
  }

  Widget _buildManagerView() {
    return StreamBuilder<List<RoomRequest>>(
      stream: _requestsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No pending join requests.');
        }
        final requests = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Join Requests', style: Theme.of(context).textTheme.titleLarge),
            ...requests.where((req) => req.body['action'] == 'join').map((request) {
              return Card(
                child: ListTile(
                  title: Text('Requester: ${request.participantId}'),
                  subtitle: Text('Action: ${request.body['action']}'),
                  trailing: StreamBuilder<Room?>(
                    stream: _roomStream,
                    builder: (context, roomSnapshot) {
                      if (!roomSnapshot.hasData) return const SizedBox.shrink();
                      return ElevatedButton(
                        onPressed: () => _approveRequest(request, roomSnapshot.data!),
                        child: const Text('Approve'),
                      );
                    },
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// A widget to display a clickable list of rooms
class RoomsListWidget extends StatelessWidget {
  final Stream<List<Room>>? roomsStream;
  final Function(Room room) onRoomTap;

  const RoomsListWidget({
    Key? key,
    required this.roomsStream,
    required this.onRoomTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (roomsStream == null) {
      return const Center(child: Text('Stream not available.'));
    }
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
