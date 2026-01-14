// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:easy_localization/easy_localization.dart';
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

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _onboardingShowing = false;

  @override
  void initState() {
    super.initState();
    _setupLanguage();
  }

  void _setupLanguage() async {
    final settingsController = context.read<SettingsController>();
    await settingsController.initializationFinished;
    if (!mounted) return;
    settingsController.setLanguage(context, settingsController.currentLocale.value);
  }

  void _checkOnboarding() {
    final settingsController = context.read<SettingsController>();
    if (!settingsController.hasCompletedOnboarding.value && !_onboardingShowing) {
      _onboardingShowing = true;
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        builder: (context) => const OnboardingSheet(),
      ).then((_) {
        if (mounted) {
          setState(() {
            _onboardingShowing = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final settingsController = context.watch<SettingsController>();
    final audioController = context.watch<AudioController>();

    // Check onboarding on build
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnboarding());

    return ValueListenableBuilder<Locale>(
      valueListenable: settingsController.currentLocale,
      builder: (context, locale, child) {
        return ValueListenableBuilder<BigTwoCardTheme>(
            valueListenable: settingsController.currentCardTheme,
            builder: (context, themeManager, child) {
              return BackgroundImageWidget(
                  imagePath: themeManager.cardManager.mainBackgroundImagePath,
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: ResponsiveScreen(
                      squarishMainArea: Center(
                        child: Transform.rotate(
                          angle: -0.1,
                          child: const Text(
                            'Welcome!',
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
                            child: Text('bigtwo'.tr()),
                          ),
                          _gap,
                          MyButton(
                            onPressed: () {
                              audioController.playSfx(SfxType.buttonTap);
                              GoRouter.of(context).go('/poker99');
                            },
                            child: Text('99'),
                          ),
                          _gap,
                          MyButton(
                            onPressed: () => GoRouter.of(context).push('/settings'),
                            child: Text('settings'.tr()),
                          ),
                          _gap,
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: ValueListenableBuilder<bool>(
                              valueListenable: settingsController.audioOn,
                              builder: (context, audioOn, child) {
                                return IconButton(
                                  onPressed: () => settingsController.toggleAudioOn(),
                                  icon: Icon(audioOn ? Icons.volume_up : Icons.volume_off),
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
                  ));
            });
      },
    );
  }

  static const _gap = SizedBox(height: 10);
}
