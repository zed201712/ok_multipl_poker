// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ok_multipl_poker/settings/avatar_selection_screen.dart';
import 'package:ok_multipl_poker/style/card_theme_manager/big_two_card_theme.dart'
   ;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../player_progress/player_progress.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';
import 'custom_name_dialog.dart';
import 'settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _gap = SizedBox(height: 60);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final palette = context.watch<Palette>();

    return ValueListenableBuilder<Locale>(
      valueListenable: settings.currentLocale,
      builder: (context, locale, child) {
        return Scaffold(
          backgroundColor: palette.backgroundSettings,
          body: ResponsiveScreen(
            squarishMainArea: ListView(
              children: [
                _gap,
                Text(
                  'settings'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Permanent Marker',
                    fontSize: 55,
                    height: 1,
                  ),
                ),
                _gap,
                
                // Avatar Selection Row
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AvatarSelectionScreen())
                    );
                  },
                  child: Center(
                    child: ValueListenableBuilder<int>(
                      valueListenable: settings.playerAvatarNumber,
                      builder: (context, number, _) {
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            image: DecorationImage(
                              image: AssetImage(settings.currentAvatarPath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('tap_to_change_avatar'.tr()),
                  ),
                ),
                
                _gap,
                const _NameChangeLine('Name'),

                // Language Selection Row
                Row(
                  children: [
                    Text(
                      'language'.tr(),
                      style: const TextStyle(fontFamily: 'Permanent Marker', fontSize: 30),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () {
                             settings.cycleLanguage(context);
                          },
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            _getLanguageDisplayName(locale),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Permanent Marker',
                              fontSize: 20,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: () {
                             settings.cycleLanguage(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                // Card Theme Selection Row
                ValueListenableBuilder<BigTwoCardTheme>(
                  valueListenable: settings.currentCardTheme,
                  builder: (context, theme, _) {
                    return Row(
                      children: [
                        Text(
                          'theme'.tr(),
                          style: const TextStyle(fontFamily: 'Permanent Marker', fontSize: 30),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              onPressed: () {
                                settings.setCardTheme(theme.previous());
                              },
                            ),
                            Container(
                              width: 120, // Adjust size as needed
                              height: 160,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: AssetImage(theme.cardManager.themePreviewImagePath),
                                  fit: BoxFit.contain, // Or cover, depending on the asset aspect ratio
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios),
                              onPressed: () {
                                settings.setCardTheme(theme.next());
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                ValueListenableBuilder<bool>(
                  valueListenable: settings.soundsOn,
                  builder: (context, soundsOn, child) => _SettingsLine(
                    'sound'.tr(),
                    Icon(soundsOn ? Icons.graphic_eq : Icons.volume_off),
                    onSelected: () => settings.toggleSoundsOn(),
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: settings.musicOn,
                  builder: (context, musicOn, child) => _SettingsLine(
                    'music'.tr(),
                    Icon(musicOn ? Icons.music_note : Icons.music_off),
                    onSelected: () => settings.toggleMusicOn(),
                  ),
                ),
                _SettingsLine(
                  'reset_progress'.tr(),
                  const Icon(Icons.delete),
                  onSelected: () {
                    context.read<PlayerProgress>().reset();

                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('progress_reset_message'.tr()),
                      ),
                    );
                  },
                ),
                _gap,

                // QR Code Display
                const Center(
                  child:
                  Image(
                    image: AssetImage(
                      'assets/images/goblin_cards/goblin_qr.png',
                    ),
                    fit: BoxFit.contain,
                  ),

                ),
                _gap,
              ],
            ),
            rectangularMenuArea: MyButton(
              onPressed: () {
                GoRouter.of(context).pop();
              },
              child: Text('back'.tr()),
            ),
          ),
        );
      }
    );
  }

  String _getLanguageDisplayName(Locale locale) {
    if (locale.languageCode == 'zh') {
      return '繁體中文';
    } else if (locale.languageCode == 'ja') {
      return '日本語';
    } else {
      return 'English';
    }
  }
}

class _NameChangeLine extends StatelessWidget {
  final String title;

  const _NameChangeLine(this.title);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return InkResponse(
      highlightShape: BoxShape.rectangle,
      onTap: () => showCustomNameDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Permanent Marker',
                fontSize: 30,
              ),
            ),
            const Spacer(),
            ValueListenableBuilder(
              valueListenable: settings.playerName,
              builder: (context, name, child) => Text(
                '‘$name’',
                style: const TextStyle(
                  fontFamily: 'Permanent Marker',
                  fontSize: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsLine extends StatelessWidget {
  final String title;

  final Widget icon;

  final VoidCallback? onSelected;

  const _SettingsLine(this.title, this.icon, {this.onSelected});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      highlightShape: BoxShape.rectangle,
      onTap: onSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Permanent Marker',
                  fontSize: 30,
                ),
              ),
            ),
            icon,
          ],
        ),
      ),
    );
  }
}
