| **任務 ID (Task ID)** | `FEAT-TURN-BASED-CONTROLLER-004` |
| **創建日期 (Date)** | `2025/12/11` |

### 1. 目的 (Objective)

本文件旨在簡化 `FirestoreTurnBasedGameController` 的建構子，降低其使用複雜性。目標是將內部依賴的初始化移至 `Controller` 內部，讓調用者只需關注於核心業務邏輯的配置。

### 2. 解決方案 (Solution)

我們將重構 `FirestoreTurnBasedGameController`，使其不再需要外部注入 `FirestoreRoomStateController` 和 `ErrorMessageService`。

#### 2.1. 重構前的結構 (Before Refactoring)

在目前的實現中，所有依賴都需要由外部創建並傳入。

```dart
// firestore_turn_based_game_controller.dart (before)

class FirestoreTurnBasedGameController<T> {
  final FirestoreRoomStateController _roomStateController;
  final TurnBasedGameDelegate<T> _delegate;
  final ErrorMessageService _errorMessageService;

  FirestoreTurnBasedGameController({
    required this.roomStateController,
    required this.delegate,
    required this.errorMessageService,
  });
  // ...
}
```

#### 2.2. 重構後的結構 (After Refactoring)

重構後，`Controller` 將自行管理其內部依賴，建構子變得更加簡潔。

1.  **內部初始化依賴**: `FirestoreRoomStateController` 和 `ErrorMessageService` 將在 `Controller` 內部被創建。
2.  **引入 `collectionName`**: 建構子將接收 `collectionName`，用於初始化 `FirestoreRoomStateController`。
3.  **公開 `errorMessageService`**: `ErrorMessageService` 將作為一個 public property 暴露，以便外部（例如 UI 層）可以監聽錯誤訊息。

```dart
// firestore_turn_based_game_controller.dart (after)

class FirestoreTurnBasedGameController<T> {
  final TurnBasedGameDelegate<T> _delegate;

  late final FirestoreRoomStateController roomStateController;
  final ErrorMessageService errorMessageService = ErrorMessageService();

  FirestoreTurnBasedGameController({
    required TurnBasedGameDelegate<T> delegate,
    required String collectionName,
  }) : _delegate = delegate {

    roomStateController = FirestoreRoomStateController(FirebaseFirestore.instance, FirebaseAuth.instance, collectionName);

    _roomStateSubscription = roomStateController.roomStateStream.listen(_onRoomStateChanged);
  }
  // ...
}
```

### 3. 變更實施回顧 (Review of Implemented Changes)

根據本次重構，我們對以下檔案進行了更新。變更的核心是簡化 `FirestoreTurnBasedGameController` 的使用方式，將依賴管理的複雜性封裝在內部。

#### 3.1. `firestore_turn_based_game_controller.dart`

- **建構子簡化**：原本需要傳入三個物件 (`FirestoreRoomStateController`, `TurnBasedGameDelegate`, `ErrorMessageService`)，現在只需要傳入 `delegate` 和 `collectionName`。
- **依賴內部化**：Controller 現在會自動建立和管理它所需要的 `FirestoreRoomStateController` 和 `ErrorMessageService`，開發者不再需要在外部手動建立它們。
- **公開必要接口**：為了讓外部（如 UI 層）仍能使用，`roomStateController` 和 `errorMessageService` 被設定為公開屬性。
- **資源管理**：確保在 Controller 被銷毀時，內部建立的 `errorMessageService` 也會被正確釋放。

#### 3.2. `draw_card_game_demo_page.dart` 和 `TicTacToeGamePage.dart` (使用範例)

- **初始化流程簡化**：在這兩個範例頁面中，創建 `FirestoreTurnBasedGameController` 的程式碼變得非常簡潔。移除了所有手動建立 `FirestoreRoomStateController` 和 `ErrorMessageService` 的邏輯。
- **適應新版建構子**：頁面改用新的建構子來建立 Controller，代碼更具可讀性。
- **調整內部物件的訪問方式**：原先直接訪問 `_roomStateController` 的地方（例如，獲取當前玩家 ID），現在都改為透過 `_gameController.roomStateController` 來訪問，語意更加清晰。
- **簡化頁面清理邏輯**：頁面銷毀時，不再需要手動清理 `_roomStateController`，因為 `_gameController` 會統一管理。

### 4. 總結 (Summary)

本次重構將 `FirestoreTurnBasedGameController` 的部分依賴轉為內部管理，使其建構子更加簡潔、意圖更加清晰。調用者現在只需要提供遊戲的核心邏輯 (`_delegate`) 和 Firestore 集合名稱 (`collectionName`)，極大地簡化了 `Controller` 的創建過程。同時，通過保留 `_delegate` 的注入，我們確保了 `Controller` 的通用性和可擴展性，遵循了良好的軟體設計原則。
