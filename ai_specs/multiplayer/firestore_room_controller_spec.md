## AI 專案任務指示文件 (Refactor Task)

### **文件標頭 (Metadata)**

| 區塊 | 內容                         |
| :--- |:---------------------------|
| **任務 ID (Task ID)** | `FEAT-ROOM-CONTROLLER-001` |
| **創建日期 (Date)** | `2025/12/02`               |
| **目標版本 (Target Version)** | `N/A`                      |
| **專案名稱 (Project)** | `ok_multipl_poker`         |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

* **說明：** 將 `DemoRoomScreen.dart` 中的 Firestore 資料存取邏輯，分離到一個獨立的 `FirestoreRoomController` 中，並建立對應的資料模型，以達成關注點分離 (Separation of Concerns)。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **邏輯分離：**
    1.  建立一個 `FirestoreRoomController` class，它將封裝所有與 `rooms` collection 及其 sub-collection `participants` 的 CRUD (建立、讀取、更新、刪除) 操作。
    2.  原本在 `_RoomDemoWidgetState` 中的 `_createRoom` 和 `_joinRoom` 函式的核心邏輯需要被移動到 `FirestoreRoomController` 中。
    3.  `FirestoreRoomController` 應提供 `Stream` 接口，讓 UI 層可以監聽 `rooms` 列表和單一 `participant` 文件的變化。
*   **資料模型化：**
    1.  建立 `Room` class，用來表示 `rooms` collection 中的一個 document。
    2.  建立 `Participant` class，用來表示 `participants` sub-collection 中的一個 document。
    3.  這兩個 class 都必須包含 `fromFirestore` (factory constructor) 和 `toFirestore` (method) 方法，以便在 Dart 物件和 Firestore Map 之間進行轉換。
*   **UI 層重構：**
    1.  `RoomDemoWidget` 將會持有一個 `FirestoreRoomController` 的實例。
    2.  UI 中的按鈕事件（如 `_createRoom`）現在應該呼叫 `FirestoreRoomController` 的對應方法。
    3.  `RoomsStreamWidget` 和 `ParticipantStreamWidget` 應改為接收 `Stream<List<Room>>` 和 `Stream<Participant?>`，而不是直接操作 `QuerySnapshot`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **新增：** `lib/play_session/firestore_room_controller.dart`
*   **修改：** `lib/play_session/DemoRoomScreen.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **語言：** Dart
*   **框架：** Flutter
*   **資料庫：** Cloud Firestore
*   **架構：** 從原本的「UI 與業務邏輯混合」重構為「簡易 Controller 模式」。Controller 負責資料處理，Widget 負責畫面呈現。
*   **慣例：**
    *   資料模型 (`Room`, `Participant`) 應為不可變 (immutable)，所有屬性設為 `final`。
    *   `FirestoreRoomController` 的 `userId` 應由外部傳入，以保持其無狀態和可測試性。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`firestore_room_controller.dart`:**
    ```dart
    // Room Model
    class Room {
      final String roomId;
      // ... other properties
      Room({required this.roomId, ...});
      factory Room.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc);
      Map<String, dynamic> toFirestore();
    }

    // Participant Model
    class Participant { ... }

    // Controller
    class FirestoreRoomController {
      FirestoreRoomController(this._firestore);
      final FirebaseFirestore _firestore;

      Future<String> createRoom({
        required String userId,
        required String title,
        required int maxPlayers,
        // ... other room properties
      });

      Future<void> joinRoom({
        required String roomId,
        required String userId,
        required String status,
      });

      Stream<List<Room>> roomsStream();

      Stream<Participant?> participantStream({required String roomId, required String userId});
    }
    ```

*   **`DemoRoomScreen.dart`:**
    *   `_RoomDemoWidgetState` 將會新增 `late final FirestoreRoomController _roomController;`。
    *   `_createRoom` 和 `_joinRoom` 函式內部將簡化為對 `_roomController` 的單行呼叫。
    *   `RoomsStreamWidget` 和 `ParticipantStreamWidget` 的 `stream` 參數將來自 `_roomController`。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  建立 `lib/play_session/firestore_room_controller.dart` 檔案，並在其中實作 `Room`, `Participant`, 和 `FirestoreRoomController` 三個 class 的完整程式碼。
    2.  修改 `lib/play_session/DemoRoomScreen.dart` 檔案，將其重構以使用新的 `FirestoreRoomController`。
2.  **程式碼輸出：** 依序輸出上述兩個檔案的**完整修改後內容**。

#### **3.2 驗證步驟 (Verification Steps)**

*   **重構後的功能應與重構前完全一致。**
    1.  啟動 App 並導航至 `DemoRoomScreen`。
    2.  確認匿名登入依然正常，`userId` 能成功獲取並顯示。
    3.  建立一個新房間，確認下方的 `RoomsStreamWidget` 能即時顯示新房間的資訊。
    4.  使用上一步驟得到的 `roomId` 加入房間。
    5.  確認 `ParticipantStreamWidget` 能即時顯示自己的參與者資訊。
    6.  所有操作過程中的 `SnackBar` 提示應與之前相同。

---

### **Section 4: 上一輪回饋 (Previous Iteration Feedback) (可選)**

*   N/A
