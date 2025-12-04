## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
| :--- |:---| 
| **任務 ID (Task ID)** | `FEAT-ROOM-STATE-CONTROLLER-001` |
| **創建日期 (Date)** | `2025/12/04` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 設計並實作一個新的 `FirestoreRoomStateController`，用於管理 `Room` 內的即時狀態同步與通訊。此機制將圍繞一個 `result` 字串欄位以及 `requests` 和 `responses` 子集合來實現。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **新增 `Entity` (`RoomRequest`, `RoomResponse`)：**
    1.  建立 `lib/entities/room_request.dart` 檔案，定義 `RoomRequest` class。
    2.  建立 `lib/entities/room_response.dart` 檔案，定義 `RoomResponse` class。
    3.  這兩個 class 都應具備 `JsonSerializable` 的能力，並包含 Firestore 時間戳。

*   **建立 `FirestoreRoomStateController`：**
    1.  建立 `lib/multiplayer/firestore_room_state_controller.dart` 檔案。
    2.  **Room CRUD**: 整合 `@/lib/multiplayer/firestore_room_controller.dart` 中對 `Room` 的 CRUD 功能。
    3.  **`sendRequest`**: 允許 Participant 在 `rooms/{roomId}/requests` 子集合中建立請求文件。
    4.  **`sendResponse`**: 允許 Room Manager 在 `rooms/{roomId}/responses` 子集合中建立回應文件。
    5.  **`updateRoomResult`**: 允許 Room Manager 更新 `rooms/{roomId}` 文件中的 `result` 欄位。
    6.  **`getRoomResultStream`**: 提供一個 `Stream` 來監聽 `Room` 的 `result` 欄位變化。
    7.  **`getResponsesStream`**: 提供一個 `Stream` 來監聽指定 `roomId` 的 `responses` 子集合。
    8.  **RoomRequest, RoomResponse CRUD**: 加上對 RoomRequest 和 RoomResponse 的 CRUD (Create, Read, Update, Delete) 功能。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **新增：** `lib/entities/room_request.dart`
*   **新增：** `lib/entities/room_response.dart`
*   **新增：** `lib/multiplayer/firestore_room_state_controller.dart`
*   **修改：** `lib/entities/room.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **慣例：** 
    *   所有 `Entity` 都應為不可變 (immutable) 物件，並具備 `copyWith`、`toJson`、`fromJson` 方法。
    *   `Controller` 應透過建構式注入 `FirebaseFirestore` 實例。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`lib/entities/room_request.dart`:**
    ```dart
    class RoomRequest {
      final String requestId;
      final String participantId;
      final Map<String, dynamic> body;
      final Timestamp createdAt;
    }
    ```

*   **`lib/entities/room_response.dart`:**
    ```dart
    class RoomResponse {
      final String requestId; // Corresponds to the original request
      final String responseId;
      final String participantId;
      final Map<String, dynamic> body;
      final Timestamp createdAt;
    }
    ```

*   **`lib/multiplayer/firestore_room_state_controller.dart`:**
    ```dart
    class FirestoreRoomStateController {
      FirestoreRoomStateController(this._firestore);

      // --- Room CRUD ---
      Future<String> createRoom({
        String? roomId,
        required String creatorUid,
        required String title,
        required int maxPlayers,
        required String matchMode,
        required String visibility,
      });
      Future<void> updateRoom({
        required String roomId,
        required Map<String, Object?> data,
      });
      Future<void> deleteRoom({required String roomId});
      Stream<Room?> roomStream({required String roomId});
      Stream<List<Room>> roomsStream();

      // --- Room State ---
      Future<void> updateRoomResult({
        required String roomId,
        required String result,
      });
      Stream<String?> getRoomResultStream({required String roomId});

      // --- Request / Response CRUD ---
      Future<String> sendRequest({
        required String roomId,
        required String participantId,
        required Map<String, dynamic> body,
      });
      Future<void> deleteRequest({
        required String roomId,
        required String requestId,
      });
      Stream<List<RoomRequest>> getRequestsStream({required String roomId});

      Future<String> sendResponse({
        required String roomId,
        required String requestId,
        required String participantId,
        required Map<String, dynamic> body,
      });
      Future<void> deleteResponse({
        required String roomId,
        required String requestId,
      });
      Stream<List<RoomResponse>> getResponsesStream({required String roomId});
    }
    ```

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  建立 `lib/entities/room_request.dart`。
    2.  建立 `lib/entities/room_response.dart`。
    3.  修改 `lib/entities/room.dart`，加入 `result` 欄位。
    4.  建立 `lib/multiplayer/firestore_room_state_controller.dart` 並實作其所有方法。
2.  **程式碼輸出：** 分別輸出 `room_request.dart`、`room_response.dart`、`room.dart`（修改後）、以及 `firestore_room_state_controller.dart` 的 **完整程式碼內容**。

#### **3.2 驗證步驟 (Verification Steps)**

*   **功能驗證：**
    1.  呼叫 `createRoom` 建立房間，並透過 `roomsStream` 確認房間存在。
    2.  呼叫 `sendRequest`，確認 `rooms/{roomId}/requests` 中出現新文件。
    3.  呼叫 `sendResponse`，確認 `rooms/{roomId}/responses` 中出現新文件。
    4.  呼叫 `updateRoomResult`，並透過 `getRoomResultStream` 確認能收到更新後的 `result` 字串。
    5.  確認 `getResponsesStream` 能夠正確監聽到 `sendResponse` 後的新增資料。
    6.  呼叫 `deleteRequest` 和 `deleteResponse` 並確認文件已被刪除。
    7.  呼叫 `deleteRoom` 並確認房間已被刪除。
```