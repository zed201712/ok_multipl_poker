/// 大老二 (Big Two) 遊戲中的合法牌型。
///
/// 用於識別玩家出的牌型是否合法，以及比牌邏輯。
enum BigTwoCardPattern {
  /// 單張 (Single)
  single('Single'),

  /// 對子 (Pair)
  pair('Pair'),

  /// 順子 (Straight)
  straight('Straight'),

  /// 葫蘆 (Full House)
  fullHouse('Full House'),

  /// 鐵支 (Four of a Kind)
  fourOfAKind('Four of a Kind'),

  /// 同花順 (Straight Flush)
  straightFlush('Straight Flush');

  /// 牌型的顯示名稱 (也是序列化用的字串值)。
  final String displayName;

  const BigTwoCardPattern(this.displayName);

  /// 將字串轉換為 [BigTwoCardPattern]。
  ///
  /// 如果字串無法匹配，則拋出 [ArgumentError]。
  static BigTwoCardPattern fromJson(String json) {
    return BigTwoCardPattern.values.firstWhere(
      (e) => e.displayName == json,
      orElse: () => throw ArgumentError('無效的牌型字串: $json'),
    );
  }

  /// 序列化為 JSON 字串。
  String toJson() => displayName;

  @override
  String toString() => displayName;
}
