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

  @override
  void initState() {
    super.initState();
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
            // 比較時，settings.playerAvatarNumber.value 可能是 "1"，而我們這邊是 "1"。
            // 只要確保儲存的和比較的是一致的 (不含前導零，或者都含前導零)。
            // SettingsController 的 setPlayerAvatarNumber 存入的是 raw string。
            // 我們這裡存入 (index + 1).toString() 即 "1", "10"。
            final isSelected = settings.playerAvatarNumber.value == avatarNumber;
            
            return InkWell(
              onTap: () {
                settings.setPlayerAvatarNumber(avatarNumber);
                GoRouter.of(context).pop();
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
        rectangularMenuArea: const SizedBox(),
      ),
    );
  }
}
