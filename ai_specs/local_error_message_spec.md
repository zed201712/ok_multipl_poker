| **任務 ID (Task ID)** | `FEAT-LOCAL-ERROR-MESSAGING-001` |
| **創建日期 (Date)** | `2025/12/10` |

### 1. 目的 (Objective)

本文件旨在規劃一個**客戶端本地的、非同步的**錯誤訊息顯示框架。此框架獨立於 Firestore 的遊戲狀態，專門用於處理和顯示那些僅與當前用戶操作相關的本地錯誤（例如，網路異常、本地校驗失敗等）。

目標是建立一個可供應用程式內任何非 UI class（如 `Controller`、`Service`）調用的通用服務，並透過一個集中的 UI 元件（如 `SnackBar`）將錯誤訊息即時反饋給用戶。

### 2. 新架構：本地錯誤服務 (Local Error Service)

我們將建立一個新的、非 UI 的服務類別，它將作為應用程式內本地錯誤訊息的中央樞紐。這個服務應該作為一個**單例 (Singleton)** 或透過依賴注入（如 `Provider`）在整個應用程式中共享。

*   **`ErrorMessageService` Class**:
    *   **`errorStream`**: `final Stream<String>` - 一個公開的錯誤訊息流。UI 元件將監聽此流以獲取最新的錯誤訊息。
    *   **`showError(String message)`**: `void` - 一個公開的方法，允許應用程式的任何部分（例如 `Controller`）向流中發送一個新的錯誤訊息。
    
*   **範例實現**:
    ```dart
    import 'dart:async';

    class ErrorMessageService {
      final _errorController = StreamController<String>.broadcast();

      Stream<String> get errorStream => _errorController.stream;

      void showError(String message) {
        _errorController.add(message);
      }

      void dispose() {
        _errorController.close();
      }
    }
    ```

### 3. 新 UI 組件：根部錯誤監聽器 (Root Error Listener)

我們不會建立一個獨立的、需要在每個頁面都放置的 Widget。取而代之的是，我們將在應用程式的根部（Root）建立一個監聽器，這樣它就可以在任何頁面之上顯示錯誤訊息。

*   **位置**: 建議在 `MaterialApp` 的 `builder` 屬性中，或者在主 `Scaffold` 的 `build` 方法中實現。
*   **功能**: 
    1.  獲取 `ErrorMessageService` 的實例。
    2.  監聽其 `errorStream`。
    3.  每當從流中收到新的錯誤訊息時，使用 `ScaffoldMessenger.of(context).showSnackBar()` 來顯示一個 `SnackBar`。

*   **範例實現 (在主 Widget 中)**:
    ```dart
    // 假設 ErrorMessageService 已透過 Provider 或其他方式提供
    final errorMessageService = Provider.of<ErrorMessageService>(context, listen: false);

    // 在 build 方法或 initState 中設置監聽
    errorMessageService.errorStream.listen((message) {
      if (mounted) { // 確保 Widget 仍在樹中
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
    ```

### 4. 設計修改 (`FirestoreTurnBasedGameController`)

現在，我們將 `ErrorMessageService` 整合到我們的遊戲控制器中，讓它具備顯示本地錯誤的能力。

*   **修改 `FirestoreTurnBasedGameController` 的構造函數**: 
    *   使其接收一個 `ErrorMessageService` 的實例。
    ```dart
    class FirestoreTurnBasedGameController<T> {
      final FirestoreRoomStateController _roomStateController;
      final TurnBasedGameDelegate<T> _delegate;
      final ErrorMessageService _errorMessageService; // <<< 新增

      FirestoreTurnBasedGameController(
        this._roomStateController,
        this._delegate,
        this._errorMessageService, // <<< 新增
      );
      // ...
    }
    ```

*   **修改有本地校驗的方法**:
    *   在之前會拋出通用 `Exception` 的地方，改為調用 `_errorMessageService.showError()`。
    ```dart
    // --- 之前 ---
    Future<void> startGame() {
      final roomId = _roomStateController.roomStateStream.value?.room?.roomId;
      if (roomId == null) throw Exception("Not in a room");
      return _roomStateController.sendRequest(roomId: roomId, body: {'action': 'start_game'});
    }

    // --- 之後 ---
    Future<void> startGame() async {
      final roomId = _roomStateController.roomStateStream.value?.room?.roomId;
      if (roomId == null) {
        _errorMessageService.showError("您目前不在任何房間中");
        return;
      }
      try {
        await _roomStateController.sendRequest(roomId: roomId, body: {'action': 'start_game'});
      } catch (e) {
        _errorMessageService.showError("發送請求失敗: $e");
      }
    }
    ```
    *   同樣地，修改 `sendGameAction` 方法以實現類似的邏輯。

### 5. 邏輯對比與優勢

*   **職責清晰**: 此設計清晰地區分了兩種完全不同的錯誤類型：
    *   **遊戲規則錯誤 (Game Rule Errors)**: 由 `Delegate` 判斷，透過 Firestore 的 `lastError` 欄位同步。它們是**遊戲狀態的一部分**，具有權威性。
    *   **本地操作錯誤 (Local Action Errors)**: 由客戶端本地的 `Controller` 或 `Service` 判斷（如網路異常、前置條件不滿足）。它們**不是遊戲狀態的一部分**，只對當前用戶有意義。
*   **用戶體驗提升**: 無論是哪種錯誤，用戶都能收到即時、清晰的回饋。
*   **代碼解耦**: `Controller` 不再需要關心如何「顯示」錯誤，它只需要將錯誤訊息交給 `ErrorMessageService` 這個專門的服務即可。UI 層也無需為每個 `Controller` 單獨處理錯誤顯示，只需在一個地方監聽 `ErrorMessageService`。