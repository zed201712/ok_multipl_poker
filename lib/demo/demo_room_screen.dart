import 'package:flutter/material.dart';
import '../demos/draw_card_game/draw_card_game_demo_page.dart';
import 'TicTacToeGamePage.dart';

class RoomDemoScreen extends StatelessWidget {
  const RoomDemoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room Demo')),
      body: const SafeArea(
        child: TicTacToeGamePage(), // 你的 widget 放這裡
      ),
    );
  }
}
