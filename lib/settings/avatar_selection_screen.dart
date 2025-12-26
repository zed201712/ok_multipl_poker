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
  final List<String> _avatarPaths = [];
  late String _selectedAvatarNumber;

  final String _defaultAvatarDescription = 'A mysterious goblin.';
  final Map<String, String> _avatarDescriptions = {
    '1': 'The brave beginner goblin.',
    '2': 'The cunning card shark.',
    '3': 'The wise old sage.',
    '4': 'The quick-fingered thief.',
    '5': 'The joyful jester.',
    '6': 'The grumpy guard.',
    '7': 'The lucky gambler.',
    '8': 'The stoic warrior.',
    '9': 'The mystical mage.',
    '10': 'The royal advisor.',
    '11': 'The forest scout.',
    '12': 'The mountain climber.',
    '13': 'The swamp dweller.',
  };

  @override
  void initState() {
    super.initState();
    _selectedAvatarNumber = context.read<SettingsController>().playerAvatarNumber.value;
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    // 由於 AssetManifest 需要在 Flutter binding 初始化後才能使用
    // 且這是一個簡單的示例，我們先列出已知的圖片範圍
    // 實際專案中，使用 AssetManifest 讀取所有 assets 是更好的做法
    // 這裡我們假設圖片命名規則為 goblin_1_001.png 到 goblin_1_013.png
    // 以及 goblin_bg_001.png, goblin_bg_002.png (背景圖可能不適合當頭像，這裡僅列出卡片圖)
    
    // final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    // 簡單解析 AssetManifest (實際應使用 jsonDecode)
    // 這裡為了簡化，直接生成已知列表
    
    final paths = List.generate(13, (index) {
      final number = (index + 1).toString().padLeft(3, '0');
      return 'assets/images/goblin_cards/goblin_1_$number.png';
    });

    if (mounted) {
      setState(() {
        _avatarPaths.addAll(paths);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final palette = context.watch<Palette>();

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
          itemCount: _avatarPaths.length,
          itemBuilder: (context, index) {
            final path = _avatarPaths[index];
            final avatarNumber = (index + 1).toString();
            // 比較時，使用本地狀態 _selectedAvatarNumber
            final isSelected = _selectedAvatarNumber == avatarNumber;
            
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedAvatarNumber = avatarNumber;
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
                _avatarDescriptions[_selectedAvatarNumber] ?? _defaultAvatarDescription,
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
