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

  final String _defaultAvatarDescription = '善良的哥布林\n看到敵人跌倒會先扶他起來，再不好意思地問一句「那…我現在可以打你了嗎？」';
  final Map<String, String> _avatarDescriptions = {
    '1': '哥布林務局局長\n每天坐在破木桌後面蓋章，最擅長的技能是「文件遺失」與「流程再補一張表」，據說沒有任何一隻哥布林真的辦完過手續。',
    '2': '山寨寨主哥布林\n其實只有三個部下和一面會倒的旗子，但開會時氣勢十足，講話一定要站在石頭上。',
    '3': '哥布林弓箭手\n百發不中不是形容詞，是戰績，射出去的箭有時會先打到自己人，但他堅稱那是戰術。',
    '4': '伐伐伐木工哥布林\n口號喊得最大聲，樹卻永遠倒在相反方向，至今仍在研究為什麼樹會報復他。',
    '5': '自由的哥布林\nこれが...自由だ\n離開部落後第一天就迷路，第三天開始懷念加班與命令，但嘴上仍然高喊這就是自由。',
    '6': '盜賊哥布林\n行竊時動作俐落、眼神銳利，唯一的缺點是偷完一定會忍不住炫耀給被害者看。',
    '7': '叛徒哥布林\n哥布林的背叛者，嚴厲斥責',
    '8': '騎士哥布林\n穿著撿來的生鏽盔甲，宣誓效忠時很感動，只是劍一拔出來就卡住，需要旁人幫忙。',
    '9': '冰霜哥布林\n不畏寒流的冰霜戰士\n站在暴風雪中一動也不動，其實是因為凍到忘記怎麼走路，但氣勢完全沒有輸。',
    '10': '狂戰士哥布林\n一進入戰鬥就大吼衝鋒，戰後才發現忘了帶武器，輸出全靠吼',
    '11': '貓頭鷹哥布林\n殘暴的貓頭鷹\n夜視能力極強，白天卻常撞牆，傳說他分不清自己是哥布林還是貓頭鷹。',
    '12': '哥布林大祭司\n吟唱古老咒語時十分莊嚴，但內容其實是昨晚的食譜，只是沒人聽得懂。',
    '13': '巨魔哥布林\n比較寬的哥布林\n不是比較高，是比較橫，走進洞穴時需要側身，戰場上則自帶掩體效果。',
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
    
    final paths = List.generate(18, (index) {
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
