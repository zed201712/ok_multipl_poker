// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ok_multipl_poker/settings/onboarding_sheet.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../settings/settings.dart';
import '../style/card_theme_manager/big_two_card_theme.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';
import '../widgets/background_image_widget.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final settingsController = context.watch<SettingsController>();
    final audioController = context.watch<AudioController>();
    
    // Check onboarding on build
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (!settingsController.hasCompletedOnboarding.value) {
          showModalBottomSheet(
             context: context, 
             isDismissible: false,
             enableDrag: false,
             isScrollControlled: true,
             builder: (context) => const OnboardingSheet()
          );
       }
    });

    return
      ValueListenableBuilder<BigTwoCardTheme>(
          valueListenable: settingsController.currentCardTheme,
          builder: (context, themeManager, child) {
            return BackgroundImageWidget(
                imagePath: themeManager.cardManager.mainBackgroundImagePath,
                child:
                Scaffold(
                  backgroundColor: Colors.transparent,
                  body: ResponsiveScreen(
                    squarishMainArea: Center(
                      child: Transform.rotate(
                        angle: -0.1,
                        child: const Text(
                          'BigTwo!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Permanent Marker',
                            fontSize: 55,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    rectangularMenuArea: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        MyButton(
                          onPressed: () {
                            audioController.playSfx(SfxType.buttonTap);
                            GoRouter.of(context).go('/play');
                          },
                          child: const Text('Play'),
                        ),
                        _gap,
                        MyButton(
                          onPressed: () =>
                              GoRouter.of(context).push('/settings'),
                          child: const Text('Settings'),
                        ),
                        _gap,
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: ValueListenableBuilder<bool>(
                            valueListenable: settingsController.audioOn,
                            builder: (context, audioOn, child) {
                              return IconButton(
                                onPressed: () =>
                                    settingsController.toggleAudioOn(),
                                icon: Icon(
                                    audioOn ? Icons.volume_up : Icons
                                        .volume_off),
                              );
                            },
                          ),
                        ),
                        _gap,
                        const Text('Music by Mr Smith'),
                        _gap,
                      ],
                    ),
                  ),
                )
            );
          }
      );
  }

  static const _gap = SizedBox(height: 10);
}
