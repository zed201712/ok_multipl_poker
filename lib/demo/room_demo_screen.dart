import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomDemoScreen extends StatelessWidget {
  const RoomDemoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room Demo')),
      body: const SafeArea(
        child: RoomDemoWidget(), // 你的 widget 放這裡
      ),
    );
  }
}
class RoomDemoWidget extends StatefulWidget {
  const RoomDemoWidget({super.key});

  @override
  State<RoomDemoWidget> createState() => _RoomDemoWidgetState();
}

class _RoomDemoWidgetState extends State<RoomDemoWidget> {
  final _roomTitleController = TextEditingController();
  final _maxPlayersController = TextEditingController(text: '4');
  final _matchModeController = TextEditingController(text: 'casual');
  final _visibilityController = TextEditingController(text: 'public');
  final _participantStatusController = TextEditingController(text: 'ready');
  String _roomId = '';
  String _userId = '';

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    User? user = _auth.currentUser;
    if (user == null) {
      user = (await _auth.signInAnonymously()).user;
    }
    setState(() {
      _userId = user!.uid;
    });
  }

  /// 建立房間
  Future<void> _createRoom() async {
    final roomId = _roomId.isNotEmpty ? _roomId : _firestore.collection('rooms').doc().id;

    final roomData = {
      'roomId': roomId,
      'creatorUid': _userId,
      'title': _roomTitleController.text,
      'maxPlayers': int.tryParse(_maxPlayersController.text) ?? 4,
      'status': 'open',
      'matchMode': _matchModeController.text,
      'visibility': _visibilityController.text,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivityAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('rooms').doc(roomId).set(roomData);
    setState(() {
      _roomId = roomId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('房間建立成功，roomId: $roomId')),
    );
  }

  /// 參與者填寫自己的 participant 資訊
  Future<void> _joinRoom() async {
    if (_roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先輸入 roomId 或建立房間')),
      );
      return;
    }

    final participantData = {
      'uid': _userId,
      'status': _participantStatusController.text,
      'joinedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('rooms')
        .doc(_roomId)
        .collection('participants')
        .doc(_userId)
        .set(participantData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已加入房間 $_roomId')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Room ID (可空白自動生成):'),
          TextField(
            onChanged: (v) => _roomId = v,
            decoration: const InputDecoration(hintText: 'roomId'),
          ),
          const SizedBox(height: 12),
          Text('房間名稱:'),
          TextField(controller: _roomTitleController),
          const SizedBox(height: 12),
          Text('最多人數:'),
          TextField(
            controller: _maxPlayersController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Text('配對模式:'),
          TextField(controller: _matchModeController),
          const SizedBox(height: 12),
          Text('房間可見性:'),
          TextField(controller: _visibilityController),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _createRoom,
            child: const Text('建立房間'),
          ),
          const Divider(height: 40),
          Text('參與者資訊 (填寫自己的狀態):'),
          TextField(
            controller: _participantStatusController,
            decoration: const InputDecoration(hintText: 'ready / not ready'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _joinRoom,
            child: const Text('加入房間 / 更新 participant'),
          ),
          const SizedBox(height: 20),
          Text('目前 roomId: $_roomId'),
          Text('目前 userId: $_userId'),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),

          // 子 Widget：列出 rooms collection 的內容
          Text('=== 所有 rooms (實時) ===', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(
            height: 220,
            child: RoomsStreamWidget(firestore: _firestore),
          ),
          const SizedBox(height: 20),

          // 子 Widget：監聽指定 room 的 participant doc（rooms/{roomId}/participants/{userId}）
          Text('=== 目前 participant doc (實時) ===', style: Theme.of(context).textTheme.titleMedium),
          ParticipantStreamWidget(
            firestore: _firestore,
            roomId: _roomId,
            userId: _userId,
          ),
        ],
      ),
    );
  }
}

/// 子 Widget: 監聽並顯示 rooms collection 裡的所有 documents
class RoomsStreamWidget extends StatelessWidget {
  final FirebaseFirestore firestore;

  const RoomsStreamWidget({Key? key, required this.firestore}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore.collection('rooms').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('錯誤: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('目前沒有 rooms'));
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('roomId: ${doc.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    // 顯示所有 key:value
                    ...data.entries.map((e) {
                      final value = e.value;
                      final display = value is Timestamp ? value.toDate().toString() : value.toString();
                      return Text('${e.key}: $display');
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 子 Widget: 監聽並顯示單一 participant doc 在 rooms/{roomId}/participants/{userId}
class ParticipantStreamWidget extends StatelessWidget {
  final FirebaseFirestore firestore;
  final String roomId;
  final String userId;

  const ParticipantStreamWidget({
    Key? key,
    required this.firestore,
    required this.roomId,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (roomId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('請先輸入或建立 roomId（上方輸入框）以監聽 participant。'),
      );
    }
    if (userId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('User 尚未初始化。請等候或重新載入頁面以取得 userId。'),
      );
    }

    final docRef = firestore.collection('rooms').doc(roomId).collection('participants').doc(userId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('錯誤: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final doc = snapshot.data;
        if (doc == null || !doc.exists) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('participant document 尚未存在（path: rooms/$roomId/participants/$userId）'),
          );
        }

        final data = doc.data()!;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('rooms/$roomId/participants/$userId', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...data.entries.map((e) {
                  final value = e.value;
                  final display = value is Timestamp ? value.toDate().toString() : value.toString();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('${e.key}: $display'),
                  );
                }).toList(),
                const SizedBox(height: 8),
                Text('最後更新時間: ${doc.metadata.hasPendingWrites ? "本地未同步" : "已同步"}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
