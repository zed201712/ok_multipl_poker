// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ok_multipl_poker/settings/avatar_selection_screen.dart';
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

    return Scaffold(
      backgroundColor: palette.backgroundSettings,
      body: ResponsiveScreen(
        squarishMainArea: ListView(
          children: [
            _gap,
            const Text(
              'Settings',
              textAlign: TextAlign.center,
              style: TextStyle(
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
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('Tap to change avatar'),
              ),
            ),
            
            _gap,
            const _NameChangeLine('Name'),
            ValueListenableBuilder<bool>(
              valueListenable: settings.soundsOn,
              builder: (context, soundsOn, child) => _SettingsLine(
                'Sound FX',
                Icon(soundsOn ? Icons.graphic_eq : Icons.volume_off),
                onSelected: () => settings.toggleSoundsOn(),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: settings.musicOn,
              builder: (context, musicOn, child) => _SettingsLine(
                'Music',
                Icon(musicOn ? Icons.music_note : Icons.music_off),
                onSelected: () => settings.toggleMusicOn(),
              ),
            ),
            _SettingsLine(
              'Reset progress',
              const Icon(Icons.delete),
              onSelected: () {
                context.read<PlayerProgress>().reset();

                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Player progress has been reset.'),
                  ),
                );
              },
            ),
            _gap,

            // QR Code Display
            Center(
              child:
              Image(
                image: AssetImage(
                  'assets/images/goblin_cards/goblin_qr.png',
                ),
                fit: BoxFit.contain,
              ),

            ),
            // Center(
            //   child:
            //   Container(
            //     color: Colors.white,
            //     child: QrImageView(
            //           data: '123',
            //           version: QrVersions.auto,
            //           size: 200.0,
            //           // embeddedImage: const AssetImage('assets/images/goblin_cards/goblin_1_009.png'),
            //           embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(45, 60),
            //         ),
            //       ),
            //   ),
            // ),
            _gap,
          ],
        ),
        rectangularMenuArea: MyButton(
          onPressed: () {
            GoRouter.of(context).pop();
          },
          child: const Text('Back'),
        ),
      ),
    );
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
