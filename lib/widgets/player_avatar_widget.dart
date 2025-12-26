import 'package:flutter/material.dart';

class PlayerAvatarWidget extends StatelessWidget {
  final String avatarNumber;
  final double size;

  const PlayerAvatarWidget({
    super.key,
    required this.avatarNumber,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    // Basic validation or fallback logic
    final validNumber = int.tryParse(avatarNumber) != null ? avatarNumber : '1';
    final assetPath = 'assets/images/goblin_cards/goblin_1_${validNumber.padLeft(3, '0')}.png';

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
