import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/palette.dart';
import '../style/responsive_screen.dart';
import 'settings.dart';

class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  late int _selectedAvatarNumber;

  @override
  void initState() {
    super.initState();
    _selectedAvatarNumber = context.read<SettingsController>().playerAvatarNumber.value;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final palette = context.watch<Palette>();
    final avatarList = settings.avatarList;

    return Scaffold(
      backgroundColor: palette.backgroundSettings,
      appBar: AppBar(
        title: const Text('Select Avatar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ResponsiveScreen(
        squarishMainArea: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: avatarList.length,
          itemBuilder: (context, index) {
            final path = avatarList[index].avatarImagePath;
            // 比較時，使用本地狀態 _selectedAvatarNumber
            final isSelected = _selectedAvatarNumber == index;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedAvatarNumber = index;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  border: isSelected ? Border.all(color: Colors.amber, width: 4) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(path, fit: BoxFit.cover),
                ),
              ),
            );
          },
        ),
        rectangularMenuArea: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Description Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                avatarList[_selectedAvatarNumber].description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Permanent Marker',
                  fontSize: 20,
                  color: Colors.white, // Assuming dark background or readable color
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel Button (X)
                ElevatedButton(
                  onPressed: () {
                    GoRouter.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.red, // Cancel color
                  ),
                  child: const Icon(Icons.close, size: 30, color: Colors.white),
                ),
                
                // Confirm Button (Check)
                ElevatedButton(
                  onPressed: () {
                    settings.setPlayerAvatarNumber(_selectedAvatarNumber);
                    GoRouter.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.green, // Confirm color
                  ),
                  child: const Icon(Icons.check, size: 30, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
