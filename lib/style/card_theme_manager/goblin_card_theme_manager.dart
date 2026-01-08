
import 'package:ok_multipl_poker/style/card_theme_manager/avatar_entity.dart';

import '../../game_internals/playing_card.dart';
import 'card_theme_manager.dart';

class GoblinCardThemeManager implements CardThemeManager {
  @override
  String get mainBackgroundImagePath => 'assets/images/goblin_cards/goblin_bg_001.png';

  @override
  String get gameBackgroundImagePath => 'assets/images/goblin_cards/goblin_bg_002.png';

  @override
  String get cardBackImagePath => 'assets/images/goblin_cards/goblin_1_001.png';

  @override
  String get themePreviewImagePath => 'assets/images/goblin_cards/goblin_1_001.png';

  @override
  String getCardImagePath(PlayingCard card) {
    if (card.value < 0 || card.value > 13) {
      throw ArgumentError('Invalid card value: ${card.value}');
    }
    return 'assets/images/goblin_cards/goblin_1_${card.value.toString().padLeft(3, '0')}.png';
  }

  @override
  List<AvatarEntity> get avatars => _avatars;

  late final List<AvatarEntity> _avatars;

  GoblinCardThemeManager() {
    final String defaultAvatarDescription = '善良的哥布林\n看到敵人跌倒會先扶他起來，再不好意思地問一句「那…我現在可以打你了嗎？」';
    final Map<int, String> avatarDescriptions = {
      1: '哥布林務局局長\n每天坐在破木桌後面蓋章，最擅長的技能是「文件遺失」與「流程再補一張表」，據說沒有任何一隻哥布林真的辦完過手續。',
      2: '山寨寨主哥布林\n其實只有三個部下和一面會倒的旗子，但開會時氣勢十足，講話一定要站在石頭上。',
      3: '哥布林弓箭手\n百發不中不是形容詞，是戰績，射出去的箭有時會先打到自己人，但他堅稱那是戰術。',
      4: '伐伐伐木工哥布林\n口號喊得最大聲，樹卻永遠倒在相反方向，至今仍在研究為什麼樹會報復他。',
      5: '自由的哥布林\nこれが...自由だ\n離開部落後第一天就迷路，第三天開始懷念加班與命令，但嘴上仍然高喊這就是自由。',
      6: '盜賊哥布林\n行竊時動作俐落、眼神銳利，唯一的缺點是偷完一定會忍不住炫耀給被害者看。',
      7: '叛徒哥布林\n哥布林的背叛者，嚴厲斥責',
      8: '騎士哥布林\n穿著撿來的生鏽盔甲，宣誓效忠時很感動，只是劍一拔出來就卡住，需要旁人幫忙。',
      9: '冰霜哥布林\n不畏寒流的冰霜戰士\n站在暴風雪中一動也不動，其實是因為凍到忘記怎麼走路，但氣勢完全沒有輸。',
      10: '狂戰士哥布林\n一進入戰鬥就大吼衝鋒，戰後才發現忘了帶武器，輸出全靠吼',
      11: '貓頭鷹哥布林\n殘暴的貓頭鷹\n夜視能力極強，白天卻常撞牆，傳說他分不清自己是哥布林還是貓頭鷹。',
      12: '哥布林大祭司\n吟唱古老咒語時十分莊嚴，但內容其實是昨晚的食譜，只是沒人聽得懂。',
      13: '巨魔哥布林\n比較寬的哥布林\n不是比較高，是比較橫，走進洞穴時需要側身，戰場上則自帶掩體效果。',
    };
    final avatarList = List.generate(18, (index) {
      final number = (index + 0).toString().padLeft(3, '0');
      final description = avatarDescriptions[(index + 0)] ?? defaultAvatarDescription;
      return AvatarEntity('assets/images/goblin_cards/goblin_1_$number.png', description);
    });
    this._avatars = avatarList;
  }
}