
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ok_multipl_poker/multiplayer/firestore_room_controller.dart';

class DemoRoomWidget extends StatefulWidget {
  const DemoRoomWidget({super.key});

  @override
  State<DemoRoomWidget> createState() => _DemoRoomWidgetState();
}

class _DemoRoomWidgetState extends State<DemoRoomWidget> {
  final _roomTitleController = TextEditingController();
  final _maxPlayersController = TextEditingController(text: '4');
  final _matchModeController = TextEditingController(text: 'casual');
  final _visibilityController = TextEditingController(text: 'public');
  final _participantStatusController = TextEditingController(text: 'ready');
  final _roomIdController = TextEditingController();

  String _userId = '';

  final _auth = FirebaseAuth.instance;
  late final FirestoreRoomController _roomController;

  Stream<List<Room>>? _roomsStream;
  Stream<List<Participant>>? _participantsStream; // Changed to plural

  @override
  void initState() {
    super.initState();
    _roomController = FirestoreRoomController(FirebaseFirestore.instance);
    _roomsStream = _roomController.roomsStream();
    _initUser();
    _roomIdController.addListener(_onRoomIdChanged);
  }

  @override
  void dispose() {
    _roomIdController.removeListener(_onRoomIdChanged);
    _roomTitleController.dispose();
    _maxPlayersController.dispose();
    _matchModeController.dispose();
    _visibilityController.dispose();
    _participantStatusController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  Future<void> _initUser() async {
    User? user = _auth.currentUser;
    if (user == null) {
      user = (await _auth.signInAnonymously()).user;
    }
    if (mounted) {
      setState(() {
        _userId = user!.uid;
        _onRoomIdChanged();
      });
    }
  }

  void _onRoomIdChanged() {
    setState(() {
      _participantsStream = _roomController.participantsStream(
        roomId: _roomIdController.text,
      );
    });
  }

  Future<void> _createRoom() async {
    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not initialized yet.')),
      );
      return;
    }

    final newRoomId = await _roomController.createRoom(
      roomId: _roomIdController.text,
      creatorUid: _userId,
      title: _roomTitleController.text,
      maxPlayers: int.tryParse(_maxPlayersController.text) ?? 4,
      matchMode: _matchModeController.text,
      visibility: _visibilityController.text,
    );

    setState(() {
      _roomIdController.text = newRoomId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Room created successfully, roomId: $newRoomId')),
    );
  }

  Future<void> _joinRoom() async {
    final roomId = _roomIdController.text;
    if (roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a room ID or create a room first.')),
      );
      return;
    }

    await _roomController.joinRoom(
      roomId: roomId,
      userId: _userId,
      status: _participantStatusController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joined room $roomId')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Room ID (leave blank to auto-generate):'),
          TextField(controller: _roomIdController, decoration: const InputDecoration(hintText: 'roomId')),
          const SizedBox(height: 12),
          Text('Room Name:'),
          TextField(controller: _roomTitleController),
          const SizedBox(height: 12),
          Text('Max Players:'),
          TextField(controller: _maxPlayersController, keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _createRoom, child: const Text('Create Room')),
          const Divider(height: 40),
          Text('Participant Status:'),
          TextField(controller: _participantStatusController, decoration: const InputDecoration(hintText: 'e.g., ready')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _joinRoom, child: const Text('Join Room / Update Status')),
          const SizedBox(height: 20),
          Text('Current Room ID: ${_roomIdController.text}'),
          Text('Current User ID: $_userId'),
          const Divider(height: 30),

          Text('=== All Rooms (Live) ===', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 220, child: RoomsStreamWidget(roomsStream: _roomsStream)),
          const SizedBox(height: 20),

          Text('=== All Participants (Live) ===', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(
            height: 220,
            child: ParticipantStreamWidget(participantsStream: _participantsStream, roomId: _roomIdController.text),
          ),
        ],
      ),
    );
  }
}


class RoomsStreamWidget extends StatelessWidget {
  final Stream<List<Room>>? roomsStream;
  const RoomsStreamWidget({Key? key, required this.roomsStream}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (roomsStream == null) return const Center(child: Text('Stream not ready.'));

    return StreamBuilder<List<Room>>(
      stream: roomsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final rooms = snapshot.data ?? [];
        if (rooms.isEmpty) return const Center(child: Text('No rooms found.'));

        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('ID: ${room.roomId}\nTitle: ${room.title}, Players: ${room.maxPlayers}, Status: ${room.status}'),
              ),
            );
          },
        );
      },
    );
  }
}

class ParticipantStreamWidget extends StatelessWidget {
  final Stream<List<Participant>>? participantsStream;
  final String roomId;

  const ParticipantStreamWidget({Key? key, this.participantsStream, required this.roomId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (roomId.isEmpty) return const Text('Enter Room ID above to see participants.');
    if (participantsStream == null) return const Text('Stream not ready.');

    return StreamBuilder<List<Participant>>(
      stream: participantsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final participants = snapshot.data ?? [];
        if (participants.isEmpty) return const Center(child: Text('No participants in this room.'));

        return ListView.builder(
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final participant = participants[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('User: ${participant.uid}\nStatus: ${participant.status}\nJoined: ${participant.joinedAt.toDate()}'),
              ),
            );
          },
        );
      },
    );
  }
}
