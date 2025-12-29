import 'package:ok_multipl_poker/style/card_theme_manager/card_theme_manager.dart';
import 'package:ok_multipl_poker/style/card_theme_manager/goblin_card_theme_manager.dart';
import 'package:ok_multipl_poker/style/card_theme_manager/weave_zoo_card_theme_manager.dart';

enum BigTwoCardTheme {
  weaveZoo,
  goblin;

  // Use static final instances to avoid overhead of creating managers (and their avatar lists) repeatedly.
  static final _goblinManager = GoblinCardThemeManager();
  static final _weaveManager = WeaveZooCardThemeManager();

  CardThemeManager get cardManager {
    switch (this) {
      case BigTwoCardTheme.goblin:
        return _goblinManager;
      case BigTwoCardTheme.weaveZoo:
        return _weaveManager;
    }
  }

  BigTwoCardTheme next() {
    final nextIndex = (index + 1) % BigTwoCardTheme.values.length;
    return BigTwoCardTheme.values[nextIndex];
  }

  BigTwoCardTheme previous() {
    final prevIndex = (index - 1 + BigTwoCardTheme.values.length) % BigTwoCardTheme.values.length;
    return BigTwoCardTheme.values[prevIndex];
  }
}
