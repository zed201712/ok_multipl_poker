## AI 專案任務指示文件 (Refactor Task)

| 區塊 | 內容                         |
| :--- |:---------------------------|
| **任務 ID (Task ID)** | `FEAT-ROOM-CONTROLLER-002` |
| **創建日期 (Date)** | `2025/12/03`               |
| **目標版本 (Target Version)** | `N/A`                      |
| **專案名稱 (Project)** | `ok_multipl_poker`         |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 基於 `FEAT-ROOM-CONTROLLER-001` 的基礎，擴充 `FirestoreRoomController` 的功能，為 `Room` 和 `Participant` 資料模型增加完整的 CRUD (建立、讀取、更新、刪除) 操作，並引入 `createdAt` 與 `updatedAt` 時間戳。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **資料模型增強：**
    1.  在 `Room` class 中增加 `createdAt` 和 `updatedAt` 兩個 `Timestamp` 類型的屬性。
    2.  在 `Participant` class 中增加 `createdAt` 和 `updatedAt` 兩個 `Timestamp` 類型的屬性。
    3.  更新 `fromFirestore` 和 `toFirestore` 方法以支援新的時間戳屬性。

*   **Controller 邏輯擴充：**
    1.  **Create:** `createRoom` 和 `joinRoom` 方法在建立文件時，應同時寫入 `createdAt` 和 `updatedAt` 欄位。
    2.  **Update:**
        *   建立 `updateRoom(String roomId, Map<String, dynamic> data)` 方法，用於更新指定 `Room` 的資料。此方法必須自動更新 `updatedAt` 欄位。
        *   建立 `updateParticipant(String roomId, String userId, Map<String, dynamic> data)` 方法，用於更新指定 `Participant` 的資料。此方法必須自動更新 `updatedAt` 欄位。
    3.  **Delete:**
        *   建立 `deleteRoom(String roomId)` 方法，用於刪除整個 `Room` document (可選擇性地一併刪除其下的 `participants` sub-collection)。
        *   建立 `leaveRoom(String roomId, String userId)` 方法，語意上即為刪除指定的 `Participant` document。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/multiplayer/firestore_room_controller.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **慣例：**
    *   所有更新操作都必須使用 `FieldValue.serverTimestamp()` 來更新 `updatedAt` 欄位，以確保時間的伺服器端一致性。
    *   資料模型 (`Room`, `Participant`) 應繼續保持不可變 (immutable) 的特性。
    *   針對 `JsonSerializableMixin` 的實作：
        *   需覆寫 `Set<String> get timeKeys`，並回傳所有 `Timestamp` 相關的欄位名稱 (例如：`'createdAt'`, `'updatedAt'`)，以利序列化時正確轉換。
        *   非 Firestore document `data` 一部份的欄位 (如 `roomId`) 應使用 `@JsonKey(includeFromJson: false, includeToJson: false)` 標記，將其從序列化/反序列化過程中排除。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`firestore_room_controller.dart`:**

    ```dart
    // Room Model
    class Room {
      // ... existing properties
      final Timestamp createdAt;
      final Timestamp updatedAt;

      Room({..., required this.createdAt, required this.updatedAt});

      factory Room.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc);
      Map<String, dynamic> toFirestore();
    }

    // Participant Model
    class Participant {
      // ... existing properties
      final Timestamp createdAt;
      final Timestamp updatedAt;

      Participant({..., required this.createdAt, required this.updatedAt});

      factory Participant.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc);
      Map<String, dynamic> toFirestore();
    }

    // Controller
    class FirestoreRoomController {
      // ... existing properties and methods

      // --- Create ---
      // createRoom, joinRoom signatures remain the same, but implementation changes

      // --- Update ---
      Future<void> updateRoom({
        required String roomId,
        required Map<String, Object?> data,
      });

      Future<void> updateParticipant({
        required String roomId,
        required String userId,
        required Map<String, Object?> data,
      });

      // --- Delete ---
      Future<void> deleteRoom({required String roomId});

      Future<void> leaveRoom({required String roomId, required String userId});
    }
    ```

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  修改 `lib/multiplayer/firestore_room_controller.dart` 檔案，更新 `Room` 和 `Participant` 模型，並實作新的 `update` 和 `delete` 方法。
2.  **程式碼輸出：** 輸出 `lib/multiplayer/firestore_room_controller.dart` **完整的修改後內容**。

#### **3.2 驗證步驟 (Verification Steps)**

*   **功能應保持向下相容，並增加新功能。**
    1.  **Create/Read:** 執行先前的所有驗證步驟，確保建立和讀取功能依然正常。
    2.  **Update:**
        *   呼叫 `updateRoom`，並在 Firestore Console 或透過 `roomsStream` 確認 `updatedAt` 欄位和被修改的資料已成功更新。
        *   呼叫 `updateParticipant`，並在 Firestore Console 或透過 `participantStream` 確認 `updatedAt` 欄位和被修改的資料已成功更新。
    3.  **Delete:**
        *   呼叫 `leaveRoom`，確認對應的 `participant` document 已被刪除。
        *   呼叫 `deleteRoom`，確認對應的 `room` document 已被刪除。

---

### **Section 4: 上一輪回饋 (Previous Iteration Feedback) (可選)**

*   N/A
