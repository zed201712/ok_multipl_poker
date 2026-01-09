import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:ok_multipl_poker/play_session/poker_99_board_widget.dart';
import 'package:ok_multipl_poker/settings/settings.dart';
import 'package:ok_multipl_poker/widgets/background_image_widget.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/score.dart';
import '../style/confetti.dart';

/// 這個 Widget 定義了玩家在進行遊戲時所看到的完整畫面。
///
/// 它是一個有狀態的 Widget，負責管理自身的狀態，例如是否處於「獲勝慶祝」的動畫效果中。
/// 這個畫面整合了遊戲的主要視覺元素（例如 `BoardWidget`）、
/// 外部控制按鈕（如設定和返回），並處理遊戲的生命週期，
/// 例如開始遊戲、獲勝時的慶祝動畫，以及與 Firestore 的同步（如果可用）。
class Poker99PlaySessionScreen extends StatefulWidget {
  const Poker99PlaySessionScreen({super.key});

  @override
  State<Poker99PlaySessionScreen> createState() => _Poker99PlaySessionScreenState();
}

class _Poker99PlaySessionScreenState extends State<Poker99PlaySessionScreen> {
  static final _log = Logger('PlaySessionScreen');

  static const _celebrationDuration = Duration(milliseconds: 2000);

  static const _preCelebrationDuration = Duration(milliseconds: 500);

  bool _duringCelebration = false;

  late DateTime _startOfPlay;

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();

    return IgnorePointer(
        ignoring: _duringCelebration,
        child:
        BackgroundImageWidget(
          imagePath: settingsController.currentCardThemeManager.gameBackgroundImagePath,
          child:
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Poker99BoardWidget(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkResponse(
                        onTap: () => GoRouter.of(context).push('/settings'),
                        child: Image.asset(
                          'assets/images/settings.png',
                          width: 30,
                          height: 30,
                          semanticLabel: 'Settings',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox.expand(
                  child: Visibility(
                    visible: _duringCelebration,
                    child: IgnorePointer(
                      child: Confetti(isStopped: !_duringCelebration),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startOfPlay = DateTime.now();
  }

  Future<void> _playerWon() async {
    _log.info('Player won');

    final score = Score(1, 1, DateTime.now().difference(_startOfPlay));

    await Future<void>.delayed(_preCelebrationDuration);
    if (!mounted) return;

    setState(() {
      _duringCelebration = true;
    });

    final audioController = context.read<AudioController>();
    audioController.playSfx(SfxType.congrats);

    await Future<void>.delayed(_celebrationDuration);
    if (!mounted) return;

    GoRouter.of(context).go('/play/won', extra: {'score': score});
  }
}
