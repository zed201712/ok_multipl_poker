| **任務 ID (Task ID)** | `FEAT-FAKE-FIREBASE-FIRESTORE-001` |
| **創建日期 (Date)** | `2025/12/11`                          |
| **目標版本 (Target Version)** | `N/A`                                 |
| **專案名稱 (Project)** | `ok_multipl_poker`                    |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 重構 `MockFirestoreRoomStateController`，使其不再使用記憶體內的 `BehaviorSubject` 和 `Map` 來管理狀態，而是改為接受一個 `FakeFirebaseFirestore` 實例作為其後端。這將允許多個 `MockFirestoreRoomStateController` 實例共享同一個模擬的 Firestore 資料庫，從而能夠在單元測試中真實地模擬多個玩家之間的即時互動和狀態同步。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **新增依賴：**
    *   在 `pubspec.yaml` 的 `dev_dependencies` 中新增 `fake_cloud_firestore` 套件。

*   **重構 `MockFirestoreRoomStateController`：**
    1.  修改 `lib/multiplayer/mock_firestore_room_state_controller.dart`。
    2.  更新建構式，使其接收一個 `FakeFirebaseFirestore` 實例和可選的 `collectionName`。
    3.  移除所有內部用於狀態管理的 `Map`, `List` 和 `BehaviorSubject`。
    4.  將所有方法的實作，從操作記憶體內物件改為對傳入的 `FakeFirebaseFirestore` 實例進行 Firestore 操作。
    5.  `roomsStream` 和 `roomStateStream` 應直接從 `FakeFirebaseFirestore` 的 `snapshots()` 產生。

*   **更新/建立測試程式碼：**
    1.  **建立共享狀態測試：** 建立新檔案 `test/multiplayer/fake_firebase_sharing_test.dart`，直接測試兩個 `MockFirestoreRoomStateController` 實例共享一個 `FakeFirebaseFirestore` 實例時的狀態同步。
    2.  **更新現有測試：** 修改所有使用到 `MockFirestoreRoomStateController` 的測試檔案（例如 `mock_firestore_room_state_controller_test.dart` 和 `firestore_turn_based_game_controller_test.dart`）。在測試的 `setUp` 階段，建立 `FakeFirebaseFirestore` 實例並注入，以確保它們共享狀態。


---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **新增：** `test/multiplayer/fake_firebase_sharing_test.dart`
*   **修改：** `pubspec.yaml`
*   **修改：** `lib/multiplayer/mock_firestore_room_state_controller.dart`
*   **修改：** `test/multiplayer/mock_firestore_room_state_controller_test.dart`
*   **修改：** `test/multiplayer/firestore_turn_based_game_controller_test.dart`


#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **核心依賴：** `fake_cloud_firestore`
*   **設計模式：** 依賴注入 (Dependency Injection)。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  修改 `pubspec.yaml` 以新增 `fake_cloud_firestore`。
    2.  修改 `lib/multiplayer/mock_firestore_room_state_controller.dart` 以使用 `FakeFirebaseFirestore`。
    3.  建立 `test/multiplayer/fake_firebase_sharing_test.dart` 並撰寫共享狀態的直接測試。
    4.  修改其他相關測試檔案以適應新的建構式和共享狀態的邏輯。

2.  **程式碼輸出：**
    *   輸出修改後 `pubspec.yaml` 的相關部分。
    *   輸出 `lib/multiplayer/mock_firestore_room_state_controller.dart` 的完整程式碼。
    *   輸出 `test/multiplayer/fake_firebase_sharing_test.dart` 的完整程式碼。
    *   輸出修改後 `test/multiplayer/firestore_turn_based_game_controller_test.dart` 的完整程式碼作為範例。

#### **3.2 驗證步驟 (Verification Steps)**

*   **執行測試：**
    *   執行 `flutter pub get` 以確保新依賴被下載。
    *   執行 `flutter test`，並確保所有相關測試（包括 `fake_firebase_sharing_test.dart`）都能通過。

---

### **Section 4: 自動化測試案例 (Automated Test Case for State Sharing)**

#### **4.1 `test/multiplayer/fake_firebase_sharing_test.dart`**

*   **說明：** 這個測試檔案的唯一目的，是直接驗證 `FakeFirebaseFirestore` 的共享狀態機制。它會建立兩個 `MockFirestoreRoomStateController` 實例（代表兩個不同的玩家），並讓它們共享同一個 `FakeFirebaseFirestore` 實例。測試將驗證由玩家一執行的操作（例如建立房間），其結果能被玩家二的 `Stream` 正確地觀察到，以此證明狀態是跨實例同步的。

*   **程式碼 (Code):**
    '''dart
    import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:ok_multipl_poker/multiplayer/firestore_room_state_controller.dart';
    import 'package:ok_multipl_poker/multiplayer/mock_firestore_room_state_controller.dart';

    void main() {
      group('FakeFirebaseFirestore State Sharing Test', () {
        late FakeFirebaseFirestore fakeFirestore;
        late MockFirestoreRoomStateController controllerP1;
        late MockFirestoreRoomStateController controllerP2;

        setUp(() async {
          // 為每個測試案例建立一個獨立的 FakeFirestore 實例
          fakeFirestore = FakeFirebaseFirestore();

          // 玩家一的控制器
          controllerP1 = MockFirestoreRoomStateController(firestore: fakeFirestore);
          await controllerP1.signIn('player1');

          // 玩家二的控制器，共享同一個 firestore 實例
          controllerP2 = MockFirestoreRoomStateController(firestore: fakeFirestore);
          await controllerP2.signIn('player2');
        });

        test('Player 2 should see the room created by Player 1', () async {
          // 期望：玩家二的 roomsStream 會收到一個更新，
          // 該更新包含一個房間，其 creatorUid 是 player1。
          final expectation = expectLater(
            controllerP2.roomsStream,
            emits(
              (List<Room> rooms) =>
                  rooms.any((room) => room.creatorUid == 'player1'),
            ),
          );

          // 動作：玩家一建立一個房間
          await controllerP1.createRoom({});

          // 等待期望被滿足
          await expectation;
        });

        test('Both players should see participant updates when Player 2 joins room', () async {
          // 動作：玩家一建立房間
          final roomId = await controllerP1.createRoom({});
          controllerP1.setRoomId(roomId);
          controllerP2.setRoomId(roomId);

          // 期望：玩家一的 roomStateStream 會收到更新，
          // 顯示參與者列表中包含 player2
          final p1Expectation = expectLater(
            controllerP1.roomStateStream,
            emitsThrough(
              isA<RoomState>()
                  .having((rs) => rs.room.participants, 'participants', contains('player2')),
            ),
          );

          // 動作：玩家二加入房間 (透過 matchRoom)
          await controllerP2.matchAndJoinRoom(maxPlayers: 2);

          // 等待期望被滿足
          await p1Expectation;
        });
      });
    }
    '''
