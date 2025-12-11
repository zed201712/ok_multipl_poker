## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                    |
| :--- |:--------------------------------------|
| **任務 ID (Task ID)** | `FEAT-MOCK-ROOM-STATE-CONTROLLER-001` |
| **創建日期 (Date)** | `2025/12/11`                          |
| **目標版本 (Target Version)** | `N/A`                                 |
| **專案名稱 (Project)** | `ok_multipl_poker`                    |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 建立一個 `MockFirestoreRoomStateController` 來模擬 `FirestoreRoomStateController` 的行為，用以進行本地單元測試和整合測試。這個 Mock 控制器應讓 `FirestoreRoomStateController` 的呼叫端（例如 `FirestoreTurnBasedGameController`）能夠無縫地注入並進行測試，而無需連接到真實的 Firebase 後端。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **建立 `MockFirestoreRoomStateController`：**
    1.  建立新檔案 `lib/multiplayer/mock_firestore_room_state_controller.dart`。
    2.  `MockFirestoreRoomStateController` 類別必須實作 `FirestoreRoomStateController` 的所有公開介面 (public interface)。
    3.  使用記憶體內的資料結構 (例如 `List`, `Map`, `BehaviorSubject`) 來模擬 Firestore 的資料存儲和即時串流行為。
    4.  所有來自 `FirestoreRoomStateController` 的公開方法和 `Stream` 都必須在 Mock 中有對應的實作。
    5.  Mock 控制器應提供額外的方法，讓測試程式碼可以方便地控制其內部狀態（例如：手動新增房間、觸發 `Stream` 事件、模擬玩家加入/離開）。

*   **重構呼叫端以支援依賴注入 (Dependency Injection)：**
    1.  修改 `lib/multiplayer/firestore_turn_based_game_controller.dart` 的建構式，使其接收一個 `FirestoreRoomStateController` 的實例，而不是在內部自行建立。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **新增：** `lib/multiplayer/mock_firestore_room_state_controller.dart`
*   **修改：** `lib/multiplayer/firestore_turn_based_game_controller.dart`
*   **建議新增 (Optional but Recommended):** `test/multiplayer/firestore_turn_based_game_controller_test.dart` (如果尚未存在)，用以展示如何使用 Mock 進行測試。

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **介面一致性：** `MockFirestoreRoomStateController` 的公開 API 應與 `FirestoreRoomStateController` 完全匹配。考慮定義一個抽象介面 `IRoomStateController` 由兩者共同實作，以確保一致性。
*   **響應式程式設計：** Mock 中的 `Stream` 應使用 `rxdart` 的 `BehaviorSubject` 來準確模擬真實控制器的行為。
*   **可測試性：** Mock 的設計應著重於使其易於在測試環境中設定、控制和驗證。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`lib/multiplayer/mock_firestore_room_state_controller.dart`:**
    '''dart
    import 'package:ok_multipl_poker/multiplayer/firestore_room_state_controller.dart';
    import 'package:rxdart/rxdart.dart';
    // Other necessary imports

    class MockFirestoreRoomStateController implements FirestoreRoomStateController {
      // --- Mock-specific properties for state control ---
      final _rooms = <Room>[];
      final _requests = <String, List<RoomRequest>>{};
      final _responses = <String, List<RoomResponse>>{};
      
      // --- BehaviorSubjects to mimic streams ---
      final _roomsController = BehaviorSubject<List<Room>>.seeded([]);
      final _roomStateController = BehaviorSubject<RoomState?>.seeded(null);
      final _userIdController = BehaviorSubject<String?>.seeded('mock_user_id');

      // --- Constructor ---
      MockFirestoreRoomStateController() {
        // Initialization logic if any
      }

      // --- Implementation of the public interface ---
      @override
      ValueStream<List<Room>> get roomsStream => _roomsController.stream;

      @override
      ValueStream<RoomState?> get roomStateStream => _roomStateController.stream;

      // ... Implement all other methods and getters from FirestoreRoomStateController
      
      // --- Mock-specific helper methods for testing ---
      void addRoom(Room room) { ... }
      void clear() { ... }
    }
    '''

*   **`lib/multiplayer/firestore_turn_based_game_controller.dart` (Refactoring):**
    '''dart
    // --- Before Refactoring ---
    /*
    class FirestoreTurnBasedGameController<T> {
      late final FirestoreRoomStateController roomStateController;
      
      FirestoreTurnBasedGameController({
        required TurnBasedGameDelegate<T> delegate,
        required String collectionName,
      }) : _delegate = delegate {
        roomStateController = FirestoreRoomStateController(FirebaseFirestore.instance, FirebaseAuth.instance, collectionName);
        // ...
      }
    }
    */

    // --- After Refactoring ---
    class FirestoreTurnBasedGameController<T> {
      final FirestoreRoomStateController roomStateController; // Dependency
      
      FirestoreTurnBasedGameController({
        required TurnBasedGameDelegate<T> delegate,
        required this.roomStateController, // Injected
      }) : _delegate = delegate {
        _roomStateSubscription = roomStateController.roomStateStream.listen(_onRoomStateChanged);
      }
      // ...
    }
    '''

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  建立 `lib/multiplayer/mock_firestore_room_state_controller.dart` 檔案，並使用記憶體內資料實作 `FirestoreRoomStateController` 的所有功能。
    2.  重構 `lib/multiplayer/firestore_turn_based_game_controller.dart` 的建構式以接受 `FirestoreRoomStateController` 實例。
    3.  提供使用 `MockFirestoreRoomStateController` 對 `FirestoreTurnBasedGameController` 進行測試的範例程式碼 (例如在一個新的 `_test.dart` 檔案中)。

2.  **程式碼輸出：**
    *   輸出 `lib/multiplayer/mock_firestore_room_state_controller.dart` 的完整程式碼。
    *   輸出修改後 `lib/multiplayer/firestore_turn_based_game_controller.dart` 的完整程式碼。

#### **3.2 驗證步驟 (Verification Steps)**

*   **單元測試：**
    1.  建立一個 `FirestoreTurnBasedGameController` 的測試檔案。
    2.  在 `setUp` 中，初始化 `MockFirestoreRoomStateController` 和 `FirestoreTurnBasedGameController` (注入 Mock)。
    3.  撰寫測試案例，透過操作 Mock 的狀態（例如，手動新增一個 `Room` 到 Mock 中並觸發 `roomsStream`），來驗證 `FirestoreTurnBasedGameController` 的 `gameStateStream` 是否發出預期的狀態。
    4.  驗證呼叫 `FirestoreTurnBasedGameController` 的方法（如 `sendGameAction`）時，Mock 中的 `sendRequest` 方法有被正確呼叫。
    5.  確保所有相關測試案例都能通過。
