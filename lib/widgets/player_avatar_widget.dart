import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/settings/settings.dart';
import 'package:provider/provider.dart';

class PlayerAvatarWidget extends StatelessWidget {
  final int avatarNumber;
  final double size;

  const PlayerAvatarWidget({
    super.key,
    required this.avatarNumber,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    // Basic validation or fallback logic
    final settingsController = context.watch<SettingsController>();
    final assetPath = settingsController.avatarList[avatarNumber].avatarImagePath;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2), // Slightly thinner border for small icons
        image: DecorationImage(
          image: AssetImage(assetPath),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            // Fallback image handling if needed, though AssetImage usually just fails silently or throws
            // Ideally we could show a placeholder here.
          }
        ),
      ),
    );
  }
}
