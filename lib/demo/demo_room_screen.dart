import 'package:flutter/material.dart';
import 'demo_room_widget.dart';

class RoomDemoScreen extends StatelessWidget {
  const RoomDemoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room Demo')),
      body: const SafeArea(
        child: DemoRoomWidget(), // 你的 widget 放這裡
      ),
    );
  }
}
