import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:ok_multipl_poker/settings/settings.dart';
import 'package:ok_multipl_poker/widgets/background_image_widget.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/board_state.dart';
import '../game_internals/score.dart';
import '../multiplayer/firestore_controller.dart';
import '../style/confetti.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import 'board_widget.dart';
import 'big_two_board_widget.dart';

/// 這個 Widget 定義了玩家在進行遊戲時所看到的完整畫面。
///
/// 它是一個有狀態的 Widget，負責管理自身的狀態，例如是否處於「獲勝慶祝」的動畫效果中。
/// 這個畫面整合了遊戲的主要視覺元素（例如 `BoardWidget`）、
/// 外部控制按鈕（如設定和返回），並處理遊戲的生命週期，
/// 例如開始遊戲、獲勝時的慶祝動畫，以及與 Firestore 的同步（如果可用）。
class PlaySessionScreen extends StatefulWidget {
  const PlaySessionScreen({super.key});

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen> {
  static final _log = Logger('PlaySessionScreen');

  static const _celebrationDuration = Duration(milliseconds: 2000);

  static const _preCelebrationDuration = Duration(milliseconds: 500);

  bool _duringCelebration = false;

  late DateTime _startOfPlay;

  late final BoardState _boardState;

  FirestoreController? _firestoreController;

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();

    return MultiProvider(
      providers: [
        Provider.value(value: _boardState),
      ],
      child: IgnorePointer(
        ignoring: _duringCelebration,
        child:
          BackgroundImageWidget(
              imagePath: settingsController.currentCardTheme.gameBackgroundImagePath,
              child:
              Scaffold(
                backgroundColor: Colors.transparent,
                body: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: BigTwoBoardWidget(),
                        ),
                        // const Spacer(),
                        // const BoardWidget(),
                        // const Text('Drag cards to the two areas above.'),
                        // const Spacer(),

                        // Padding(
                        //   padding: const EdgeInsets.all(8.0),
                        //   child: MyButton(
                        //     onPressed: () => GoRouter.of(context).go('/'),
                        //     child: const Text('Back'),
                        //   ),
                        // ),
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
      ),
    );
  }

  @override
  void dispose() {
    _boardState.dispose();
    _firestoreController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startOfPlay = DateTime.now();

    _boardState = BoardState(onWin: _playerWon);

    final firestore = context.read<FirebaseFirestore?>();
    if (firestore == null) {
      _log.warning(
        "Firestore instance wasn't provided. "
        'Running without _firestoreController.',
      );
    } else {
      _firestoreController = FirestoreController(
        instance: firestore,
        boardState: _boardState,
      );
    }
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
