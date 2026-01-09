
enum Poker99Action {
  /// 加
  increase('Increase'),

  /// 減
  decrease('Decrease'),

  /// 跳過
  skip('Skip'),

  /// 反轉
  reverse('Reverse'),

  /// 指定
  target('Target'),

  /// 0
  setToZero('SetToZero'),

  /// 99
  setTo99('SetTo99');

  /// 牌型的顯示名稱 (也是序列化用的字串值)。
  final String displayName;

  const Poker99Action(this.displayName);

  static Poker99Action fromJson(String json) {
    return Poker99Action.values.firstWhere(
          (e) => e.displayName == json,
      orElse: () => throw ArgumentError('無效的牌型字串: $json'),
    );
  }

  /// 序列化為 JSON 字串。
  String toJson() => displayName;

  @override
  String toString() => displayName;
}