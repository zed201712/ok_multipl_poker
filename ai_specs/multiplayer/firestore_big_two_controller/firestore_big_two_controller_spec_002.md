| **任務 ID (Task ID)** | `FEAT-FIRESTORE-BIG-TWO-CONTROLLER-002` |
| **創建日期 (Date)** | `2025/12/19` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

修改 `lib/multiplayer/firestore_big_two_controller.dart`，在 `SettingsController` 的 `testModeOn` 為 `true` 時，自動建立 3 個 `BigTwoAI` 實例。這將允許開發者在測試模式下，使用單一設備模擬 4 人（1 真人 + 3 AI）的大老二對局。

### 2. 設計思路 (Design Approach)

1.  **偵測測試模式**: 在 `FirestoreBigTwoController` 的建構子中，讀取 `SettingsController` 的 `testModeOn` 屬性。
2.  **實例化 AI**: 若測試模式開啟，則建立 3 個 `BigTwoAI` 物件。
    *   **依賴注入**: AI 需要 `Firestore`、`Auth` 和 `SettingsController`。
    *   **Firestore**: 使用與控制器相同的 `firestore` 實例（確保在同一數據庫環境）。
    *   **Auth**: 為了區分玩家，必須為每個 AI 注入具有不同 UID 的 `MockFirebaseAuth`（依賴 `firebase_auth_mocks` 套件）。
3.  **生命週期管理**: 新增 `_aiPlayers` 列表來持有這些 AI 實例，並在控制器的 `dispose()` 方法中一併呼叫它們的 `dispose()`，以避免內存洩漏。

### 3. 核心實作 (`firestore_big_two_controller.dart`)

```dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 需要引入 firebase_auth_mocks 與 BigTwoAI
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart'; 
import 'package:ok_multipl_poker/entities/big_two_player.dart';
import 'package:ok_multipl_poker/entities/big_two_state.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/multiplayer/firestore_turn_based_game_controller.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_state.dart';
import 'package:ok_multipl_poker/settings/settings.dart';
import 'package:ok_multipl_poker/multiplayer/big_two_ai/big_two_ai.dart'; // Import BigTwoAI

import '../game_internals/card_suit.dart';

class FirestoreBigTwoController {
  /// 遊戲狀態的響應式數據流。
  late final Stream<TurnBasedGameState<BigTwoState>?> gameStateStream;

  /// 底層的回合制遊戲控制器。
  late final FirestoreTurnBasedGameController<BigTwoState> _gameController;
  
  /// 測試模式下的 AI 玩家列表
  final List<BigTwoAI> _testModeAIs = [];

  /// 建構子，要求傳入 Firestore 和 Auth 實例。
  FirestoreBigTwoController({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required SettingsController settingsController,
  }) {
    _gameController = FirestoreTurnBasedGameController<BigTwoState>(
      store: firestore,
      auth: auth,
      delegate: BigTwoDelegate(),
      collectionName: 'big_two_rooms',
      settingsController: settingsController,
    );
    gameStateStream = _gameController.gameStateStream;

    // 檢查測試模式並初始化 AI
    if (settingsController.testModeOn.value) {
      _initTestModeAIs(firestore, settingsController);
    }
  }

  void _initTestModeAIs(FirebaseFirestore firestore, SettingsController settingsController) {
    for (int i = 1; i <= 3; i++) {
      final mockAuth = MockFirebaseAuth(
        signedIn: true, 
        mockUser: MockUser(
          uid: 'ai_bot_$i', 
          displayName: 'Bot $i',
          email: 'bot$i@example.com',
        ),
      );
      
      _testModeAIs.add(BigTwoAI(
        firestore: firestore,
        auth: mockAuth, // 每個 AI 使用獨立的 Mock Auth
        settingsController: settingsController,
      ));
    }
  }

  // ... (其餘方法保持不變: matchRoom, leaveRoom, restart, playCards, passTurn)

  /// 釋放資源，關閉數據流。
  void dispose() {
    _gameController.dispose();
    // 釋放 AI 資源
    for (final ai in _testModeAIs) {
      ai.dispose();
    }
    _testModeAIs.clear();
  }
}

// ... (BigTwoDelegate 保持不變)
```

### 4. 邏輯檢查與改善建議 (Logic Analysis & Recommendations)

#### 4.1. 架構問題：生產環境依賴測試庫
*   **問題**: 在 `lib/` 目錄下的核心控制器中引入 `firebase_auth_mocks` 是一個潛在風險。通常 `mocks` 庫只在 `dev_dependencies` 中聲明。如果將此應用發佈到生產環境，且 `firebase_auth_mocks` 未包含在 `dependencies` (非 dev) 中，編譯可能會失敗。
*   **改善建議**:
    1.  確認 `pubspec.yaml` 中 `firebase_auth_mocks` 是否為正式依賴 (dependency) 而非開發依賴 (dev_dependency)。如果是前者，則沒問題（但會增加包大小）。
    2.  **更佳做法**: 將 AI 初始化的邏輯抽離到外部。例如，UI 層 (`TicTacToeGamePage` 範例) 或 `Dependency Injection` 容器在建立 Controller 時，若檢測到測試模式，則額外建立 AI 管理器，而不是讓 Controller 自己管理 AI。
    3.  **折衷方案**: 如果必須在 Controller 內處理（如本任務要求），請確保使用條件導入 (Conditional Import) 或確保 Mocks 庫在所有構建目標中可用。

#### 4.2. AI 行為時序
*   **邏輯**: `BigTwoAI` 建構時會立即開始監聽 `big_two_rooms`。當真人玩家透過此 Controller 呼叫 `matchRoom()` 建立或加入房間時，AI 應該能偵測到該房間的變化並嘗試加入。
*   **潛在競爭**: 如果真人玩家建立房間後瞬間填滿（不太可能，因為只有1人），或者 AI 搶在真人之前加入別人的房間（如果用的是共享的 Firestore 開發環境）。
    *   **建議**: 確保測試環境的 `collectionName` 或 Firestore 實例是隔離的（例如使用 Emulator 或獨立的 Root Collection），以免干擾其他開發者。但在 `testModeOn` 下，通常意味著本地測試，這點應該可控。

#### 4.3. 資源管理
*   已在 `dispose()` 中正確處理 AI 的釋放，這是正確的。

#### 4.4. Auth 混淆
*   透過注入 `MockFirebaseAuth` 給 AI，我們確保了每個 AI 有獨立的 UID。這對於 `BigTwoDelegate` 區分不同玩家至關重要。邏輯正確。
