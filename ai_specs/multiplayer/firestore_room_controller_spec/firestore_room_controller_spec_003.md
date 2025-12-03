## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                         |
| :--- |:---------------------------|
| **任務 ID (Task ID)** | `FEAT-ROOM-CONTROLLER-003` |
| **創建日期 (Date)** | `2025/12/03`               |
| **目標版本 (Target Version)** | `N/A`                      |
| **專案名稱 (Project)** | `ok_multipl_poker`         |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 在 `Room` 資料模型中增加 `managerUid` 欄位，並在 `FirestoreRoomController` 中新增一個專門用來變更管理員的 `changeManager` 方法。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **資料模型增強 (`Room`)：**
    1.  在 `Room` class 中增加一個 `final String managerUid` 屬性。
    2.  更新 `Room` 的建構式、`copyWith`、`fromJson` 和 `toJson` 等方法，以支援新的 `managerUid` 屬性。

*   **Controller 邏輯擴充 (`FirestoreRoomController`)：**
    1.  **`createRoom`**：在建立房間時，`managerUid` 的初始值應設定為與 `creatorUid` 相同。
    2.  **`changeManager`**：
        *   建立一個新的方法 `Future<void> changeManager({required String roomId, required String newManagerUid})`。
        *   此方法內部應呼叫 `updateRoom` 方法，將指定 `roomId` 的 `managerUid` 欄位更新為 `newManagerUid`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/multiplayer/firestore_room_controller.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **慣例：**
    *   `changeManager` 的實現應重用現有的 `updateRoom` 邏輯，以保持程式碼的簡潔與一致性。
    *   所有資料模型應繼續保持不可變 (immutable) 的特性。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`firestore_room_controller.dart`:**

    ```dart
    // Room Model
    class Room {
      // ... existing properties
      final String creatorUid;
      final String managerUid; // New field
      // ... other properties

      Room({
        // ... existing parameters
        required this.creatorUid,
        required this.managerUid, // New parameter
        // ... other parameters
      });

      Room copyWith({
        // ... existing parameters
        String? managerUid, // New parameter
        // ... other parameters
      });
    }

    // Controller
    class FirestoreRoomController {
      // ... existing methods

      Future<String> createRoom({
        // ... existing parameters
        required String creatorUid,
        // ...
      });

      Future<void> updateRoom({
        required String roomId,
        required Map<String, Object?> data,
      });

      // New method
      Future<void> changeManager({
        required String roomId,
        required String newManagerUid,
      });
    }
    ```

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  分析 `lib/multiplayer/firestore_room_controller.dart` 的現有程式碼。
    2.  修改 `Room` class，加入 `managerUid` 屬性並更新相關方法。
    3.  修改 `createRoom` 方法，在建立房間時設定初始的 `managerUid`。
    4.  在 `FirestoreRoomController` 中新增 `changeManager` 方法。
2.  **程式碼輸出：** 輸出 `lib/multiplayer/firestore_room_controller.dart` **完整的修改後內容**。

#### **3.2 驗證步驟 (Verification Steps)**

*   **功能驗證：**
    1.  呼叫 `createRoom` 後，從 `roomsStream` 或 Firestore Console 確認新建立的 `Room` document 中，`managerUid` 欄位的值與 `creatorUid` 相同。
    2.  呼叫 `changeManager` 方法傳入一個新的 `newManagerUid`。
    3.  再次從 `roomsStream` 或 Firestore Console 確認該 `Room` document 的 `managerUid` 欄位已被成功更新，同時 `updatedAt` 時間戳也已更新。
