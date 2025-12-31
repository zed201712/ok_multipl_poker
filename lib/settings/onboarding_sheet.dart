import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ok_multipl_poker/settings/avatar_selection_screen.dart';
import 'package:provider/provider.dart';

import '../style/palette.dart';
import 'settings.dart';

class OnboardingSheet extends StatefulWidget {
  const OnboardingSheet({super.key});

  @override
  State<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<OnboardingSheet> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsController>();
    _nameController = TextEditingController(text: settings.playerName.value);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final palette = context.read<Palette>();

    return PopScope(
      canPop: false, // Prevent dismissing without completing
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: palette.backgroundSettings,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'welcome'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Permanent Marker',
                  fontSize: 35,
                ),
              ),
              const SizedBox(height: 30),

              // Avatar Selection
              Center(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AvatarSelectionScreen())
                    );
                  },
                  child: Column(
                    children: [
                      ValueListenableBuilder<int>(
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
                      const SizedBox(height: 8),
                      Text('tap_to_change_avatar'.tr()),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Name Input
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'your_name'.tr(),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  settings.setPlayerName(value);
                },
              ),

              const SizedBox(height: 40),

              // Let's Play Button
              ElevatedButton(
                onPressed: () {
                  settings.setHasCompletedOnboarding(true);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  "lets_play".tr(),
                  style: const TextStyle(fontSize: 20, fontFamily: 'Permanent Marker'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
