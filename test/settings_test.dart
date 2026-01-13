import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/settings/persistence/memory_settings_persistence.dart';
import 'package:ok_multipl_poker/settings/settings.dart';
import 'package:ok_multipl_poker/style/card_theme_manager/big_two_card_theme.dart';

void main() {
  group('SettingsController Avatar Index Tests', () {
    late SettingsController controller;

    setUp(() {
      controller = SettingsController(store: MemoryOnlySettingsPersistence());
    });

    test('getGlobalIndex should return correct global index', () {
      // weaveZoo has 14 avatars (0-13)
      // goblin has 18 avatars (0-17)
      
      // Test weaveZoo
      expect(controller.getGlobalIndex('weaveZoo', 0), 0);
      expect(controller.getGlobalIndex('weaveZoo', 13), 13);
      
      // Test goblin
      expect(controller.getGlobalIndex('goblin', 0), 14);
      expect(controller.getGlobalIndex('goblin', 17), 31);
      
      // Test invalid theme
      expect(controller.getGlobalIndex('invalid', 0), 0);
      
      // Test out of bounds
      expect(controller.getGlobalIndex('weaveZoo', 100), 0);
      expect(controller.getGlobalIndex('weaveZoo', -1), 0);
    });

    test('getThemeAndRelativeIndex should return correct theme and relative index', () {
      // Test weaveZoo range
      final (theme1, index1) = controller.getThemeAndRelativeIndex(0);
      expect(theme1, BigTwoCardTheme.weaveZoo);
      expect(index1, 0);

      final (theme2, index2) = controller.getThemeAndRelativeIndex(13);
      expect(theme2, BigTwoCardTheme.weaveZoo);
      expect(index2, 13);

      // Test goblin range
      final (theme3, index3) = controller.getThemeAndRelativeIndex(14);
      expect(theme3, BigTwoCardTheme.goblin);
      expect(index3, 0);

      final (theme4, index4) = controller.getThemeAndRelativeIndex(31);
      expect(theme4, BigTwoCardTheme.goblin);
      expect(index4, 17);

      // Test out of bounds
      final (theme5, index5) = controller.getThemeAndRelativeIndex(-1);
      expect(theme5, BigTwoCardTheme.values.first);
      expect(index5, 0);

      final (theme6, index6) = controller.getThemeAndRelativeIndex(100);
      expect(theme6, BigTwoCardTheme.values.first);
      expect(index6, 0);
    });

    test('Conversion consistency', () {
      for (int i = 0; i < controller.avatarList.length; i++) {
        final (theme, relativeIndex) = controller.getThemeAndRelativeIndex(i);
        final globalIndex = controller.getGlobalIndex(theme.name, relativeIndex);
        expect(globalIndex, i, reason: 'Failed at global index $i');
      }
    });
  });
}
