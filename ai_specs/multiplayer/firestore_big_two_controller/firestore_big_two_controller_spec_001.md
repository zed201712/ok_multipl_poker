| **任務 ID (Task ID)** | `FEAT-FIRESTORE-BIG-TWO-CONTROLLER-001` |
| **創建日期 (Date)** | `2025/12/18` |

### 1. 目的 (Objective)

本文件旨在定義一個獨立於 UI、可重用的 `FirestoreBigTwoController`，用於管理「大老二」多人卡牌遊戲的業務邏輯。此控制器將基於 `FirestoreTurnBasedGameController` 進行封裝，提供一個簡潔的 API 來處理房間匹配、遊戲狀態同步和玩家操作，並確保程式碼的健壯性和可測試性。

### 2. 設計思路 (Design Approach)

1.  **控制器封裝**: 建立一個名為 `FirestoreBigTwoController` 的新類別，其內部將實例化並管理一個 `FirestoreTurnBasedGameController<BigTwoState>`。這樣做可以將「大老二」的特定邏輯與通用的回合制遊戲基礎設施分離。
2.  **依賴注入 (Dependency Injection)**: `FirestoreBigTwoController` 的建構子將接收 `FirebaseFirestore` 和 `FirebaseAuth` 的實例。這使得在生產環境中可以使用真實的 Firebase服務，而在測試環境中可以注入 `fake_cloud_firestore` 和 `firebase_auth_mocks`，從而實現單元測試和整合測試。
3.  **簡化 API**: 控制器將向 UI 層暴露一組簡單明瞭的非同步方法，如 `matchRoom()`、`leaveRoom()`、`restart()` 和 `playCards()`。UI 層無需了解背後的 Firestore 請求細節。
4.  **狀態流 (State Stream)**: 控制器將從底層的 `FirestoreTurnBasedGameController` 導出一個 `Stream<TurnBasedGameState<BigTwoState>?>`，以便 UI 層能夠響應式地監聽遊戲狀態的變化。
5.  **遊戲規則代理 (Game Logic Delegate)**: 所有「大老二」的核心遊戲規則（如發牌、出牌合法性驗證、判定下一位玩家、勝負條件）將被封裝在一個獨立的 `BigTwoDelegate` 類別中，該類別實現 `TurnBasedGameDelegate<BigTwoState>` 接口。

### 3. 核心 API 設計 (`firestore_big_two_controller.dart`)

```dart
class FirestoreBigTwoController {
  /// 遊戲狀態的響應式數據流。
  late final Stream<TurnBasedGameState<BigTwoState>?> gameStateStream;

  /// 底層的回合制遊戲控制器。
  late final FirestoreTurnBasedGameController<BigTwoState> _gameController;

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
  }

  /// 匹配並加入一個最多4人的遊戲房間。
  /// 成功時返回房間 ID。
  Future<String> matchRoom() async {
    // ... 實現尋找和加入房間的邏輯
  }

  /// 離開當前所在的房間。
  Future<void> leaveRoom() async {
    // ... 實現離開房間的邏輯
  }

  /// 發起重新開始遊戲的請求。
  /// 所有玩家都請求後，遊戲將會重置。
  Future<void> restart() async {
    _gameController.sendGameAction('request_restart');
  }

  /// 玩家出牌。
  /// [cards] 是一個代表玩家要出的牌的列表。
  Future<void> playCards(List<Card> cards) async {
    // ... 實現出牌動作的邏輯
  }
  
  /// 玩家選擇 pass。
  Future<void> passTurn() async {
    _gameController.sendGameAction('pass_turn');
  }

  /// 釋放資源，關閉數據流。
  void dispose() {
    _gameController.dispose();
  }
}
```

### 4. 狀態管理 (`BigTwoState` and `BigTwoDelegate`)

#### 4.1. `BigTwoState`

遊戲狀態物件，需要包含「大老二」遊戲所需的所有數據。

```dart
class BigTwoState {
  final List<String> playerIds; // 玩家 ID 列表，按出牌順序排列
  final Map<String, List<Card>> hands; // 每位玩家的手牌
  final List<Card> lastPlayedHand; // 最後一手在桌面上的牌
  final String lastPlayedPlayerId; // 最後出牌的玩家
  final String? winner; // 贏家 ID
  final List<String> restartRequesters; // 請求重啟的玩家列表

  // ... fromJson, toJson 方法
}

class Card {
  final Suit suit;
  final Rank rank;
  
  // ... fromJson, toJson, a nd comparison logic
}
```

#### 4.2. `BigTwoDelegate`

實現 `TurnBasedGameDelegate<BigTwoState>`，包含核心遊戲規則。

-   `initializeGame(Room room)`: 初始化遊戲，為 4 位玩家隨機發牌。
-   `processAction(...)`: 處理 `'play_cards'`, `'pass_turn'`, `'request_restart'` 等動作。
    -   `'play_cards'`: 驗證出牌是否合法（牌型、大小），更新桌面和玩家手牌。
    -   `'pass_turn'`: 處理玩家跳過回合的邏輯。
    -   `'request_restart'`: 處理重開請求，若所有人都同意則重新 `initializeGame`。
-   `getCurrentPlayer(BigTwoState state)`: 根據 `lastPlayedHand` 和 `lastPlayedPlayerId` 決定當前回合的玩家。如果所有其他玩家都 pass，則出牌權回到上一位出牌者。
-   `getWinner(BigTwoState state)`: 檢查是否有玩家手牌為空，若有則返回該玩家 ID 作為贏家。

### 5. 邏輯檢查與改善建議

1.  **`matchRoom` 的穩健性**: `matchRoom` 方法應處理 `_gameController.matchAndJoinRoom` 可能拋出的異常或返回的 `null`，並向上層提供明確的成功或失敗反饋，例如通過返回可空的 `String?` 或拋出自定義異常。
2.  **玩家輪轉邏輯**: `getCurrentPlayer` 的邏輯是「大老二」遊戲中最複雜的部分之一。需要仔細處理玩家 `pass` 的情況。當一輪中所有其他三名玩家都 `pass` 後，出牌權應回到上一手牌的出牌者，並且他可以出任意合法的牌型 (`lastPlayedHand` 應被清空)。`BigTwoDelegate` 必須準確實現這一點。
3.  **第一回合規則**: `initializeGame` 後，擁有梅花3的玩家應為第一回合的 `currentPlayer`，且第一手牌必須包含梅花3。此邏輯應在 `initializeGame` 和 `getCurrentPlayer` 中體現。
4.  **出牌驗證**: `processAction` 在處理 `play_cards` 時，必須包含一個強大的驗證器，用於檢查牌型（單張、對子、順子、同花、葫蘆、鐵支、同花順）以及點數/花色的大小比較。
5.  **用戶反饋**: 當一個動作（如出牌）因不符合規則而無效時，控制器應提供一種機制讓 UI 知道（例如，通過一個錯誤流 `errorStream`），而不是靜默地失敗。雖然 `gameStateStream` 不會更新，但明確的錯誤反饋對用戶體驗至關重要。可以考慮在 `FirestoreTurnBasedGameController` 中增加一個可選的錯誤回調或數據流。
