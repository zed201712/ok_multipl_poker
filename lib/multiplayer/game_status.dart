enum GameStatus {
  /// 初始狀態，尚未開始匹配
  idle,

  /// 正在等待玩家加入
  matching,

  /// 遊戲正在進行中
  playing,

  /// 遊戲已結束
  finished,
}
extension GameStateX on GameStatus {
  static GameStatus fromName(
      String name, {
        GameStatus fallback = GameStatus.idle,
      }) {
    return GameStatus.values.firstWhere(
          (e) => e.name == name,
      orElse: () => fallback,
    );
  }
}
