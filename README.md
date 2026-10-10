# OK Multipl Poker

_用 Flutter 開發的多人在線撲克遊戲平台，目前收錄「大老二」與「99」兩款經典撲克遊戲，以 Firebase 即時同步對局_

---

| 項目 | 內容 |
| --- | --- |
| 線上試玩 | <https://zed201712.github.io/ok_multipl_poker/> |
| 遊戲 | 大老二（Big Two）、99（Poker 99） |
| 後端 | Firebase Cloud Firestore |
| 語言 | 繁體中文、English、日本語 |

## 📋 目錄

- [功能](#-功能)
- [開始使用](#-開始使用)
- [實作方式](#-實作方式)
- [測試與部署](#-測試與部署)

---

## ✨ 功能

- **兩款遊戲**：大老二與 99 的完整規則與牌型判斷
- **即時對戰**：透過 Firestore 配對房間、同步每一手出牌
- **電腦玩家**：大老二與 99 各有 AI 出牌策略
- **跨平台**：同一份程式碼發布到 Web 與行動裝置
- **客製化**：多種牌面主題、頭像、音樂與音效開關，介面支援中英日三種語言

---

## 🚀 開始使用

### 前置需求

| 工具 | 版本 | 為什麼 |
| --- | --- | --- |
| Flutter | 3.35.7 | CI 使用這個版本建置與測試；`pubspec.yaml` 要求 Dart SDK `^3.8.0` |
| Chrome | 最新版 | 用 Web 執行最簡單，不需要額外的 Firebase 設定檔 |
| Xcode／Android Studio | — | 只有要在 iOS、macOS 或 Android 上執行時才需要 |

確認 Flutter 版本：

```bash
flutter --version
```

### 1. 取得程式碼

```bash
git clone https://github.com/zed201712/ok_multipl_poker.git
cd ok_multipl_poker
```

### 2. 安裝套件

```bash
flutter pub get
```

### 3. 執行

```bash
flutter run -d chrome
```

---

## ⚙️ 實作方式

| 層級 | 位置 | 負責 |
| --- | --- | --- |
| 遊戲規則 | [lib/game_internals/](lib/game_internals/) | 牌組、牌型判斷、各遊戲的規則代理（Delegate） |
| 多人同步 | [lib/multiplayer/](lib/multiplayer/) | Firestore 房間與對局控制器、電腦玩家策略 |
| 資料模型 | [lib/entities/](lib/entities/) | 對局狀態與房間資料，負責與 Firestore 的 JSON 轉換 |
| 對局介面 | [lib/play_session/](lib/play_session/) | 遊戲桌面、手牌與出牌區的 Widget |

---

## 🧪 測試與部署

靜態分析與測試：

```bash
flutter analyze
flutter test
```

推送到 `main` 時，[GitHub Actions](.github/workflows/) 會執行 `flutter test`、建置 Web 版，並部署到 GitHub Pages（`gh-pages` branch）。在本機建置相同的 Web 版：

```bash
flutter build web --release --base-href /ok_multipl_poker/
```
