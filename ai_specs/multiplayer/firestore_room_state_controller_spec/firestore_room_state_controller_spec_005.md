## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                               |
| :--- |:---------------------------------|
| **任務 ID (Task ID)** | `FEAT-ROOM-STATE-CONTROLLER-005` |
| **創建日期 (Date)** | `2025/12/06`                     |
| **目標版本 (Target Version)** | `N/A`                            |
| **專案名稱 (Project)** | `ok_multipl_poker`               |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 擴充 `FirestoreRoomStateController` 的功能，新增 `matchRoom`（智慧配對或創建房間）、`leaveRoom`（處理不同身份的玩家離開房間）以及 `sendAlivePing`（客戶端心跳機制）三個方法，以簡化客戶端的房間生命週期管理邏輯。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **新增 `matchRoom` 方法：**
    1.  實現一個進階的加入房間邏輯。
    2.  首先，搜尋狀態為 `open` 且參與人數 `participants` 小於 `maxPlayers` 的房間。
    3.  **如果找到可加入的房間：** 將使用者加入該房間的 `participants` 和 `seats` 列表，並返回該房間的 `roomId`。
    4.  **如果沒有找到可加入的房間：** 調用現有的 `createRoom` 方法創建一個新房間，並讓使用者成為 `creator` 和 `manager`，最後返回新房間的 `roomId`。

*   **新增 `leaveRoom` 方法：**
    1.  根據使用者在房間中的角色（`manager` 或普通 `participant`）執行不同的操作。
    2.  **若使用者是 `managerUid`：**
        *   如果房間內還有其他參與者，則將 `managerUid` 轉移給 `participants` 列表中的下一位使用者，並將原管理者從 `participants` 和 `seats` 列表中移除。
        *   如果房間內沒有其他參與者（只剩管理者自己），則直接刪除該房間文檔。
    3.  **若使用者是普通的 `participant`：**
        *   發送一個內容為 `{'action':'leave'}` 的 `RoomRequest`。後續的移除操作將由管理者客戶端監聽到此請求後處理。

*   **新增 `sendAlivePing` 方法 (心跳機制):**
    1.  提供一個方法，讓參與者可以定期發送 `{'action':'alive'}` 的 `RoomRequest`，以表示自己仍處於活躍狀態。
    2.  此方法僅負責發送請求，不包含計時器邏輯。計時器應由客戶端自行管理。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/multiplayer/firestore_room_state_controller.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   新功能應最大程度地重用 `FirestoreRoomStateController` 中已有的 `createRoom`, `updateRoom`, `deleteRoom`, `sendRequest` 等底層方法。
*   `matchRoom` 中的房間搜尋邏輯需要先查詢後在客戶端過濾，因為 Firestore 不支援直接對 array 長度進行查詢。
*   所有與 Firestore 互動的方法都應是異步的，並返回 `Future`。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`lib/multiplayer/firestore_room_state_controller.dart` 的 Public API 新增:**
    ```dart
    class FirestoreRoomStateController {
      // ... existing methods

      /// Tries to find an open room to join. If no suitable room is found,
      /// it creates a new one with the provided details.
      Future<String> matchRoom({
        required String userId,
        // These parameters are used when creating a new room.
        required String title,
        required int maxPlayers,
        required String matchMode,
        required String visibility,
      });

      /// Handles the logic for a user leaving a room.
      /// The behavior depends on whether the user is the manager or a participant.
      Future<void> leaveRoom({
        required String roomId,
        required String userId,
      });

      /// Sends a keep-alive ping to the room in the form of a RoomRequest.
      Future<void> sendAlivePing({
        required String roomId,
        required String userId,
      });
    }
    ```

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  在 `lib/multipl/firestore_room_state_controller.dart` 中增加 `matchRoom` 方法的實現。
    2.  在 `lib/multipl/firestore_room_state_controller.dart` 中增加 `leaveRoom` 方法的實現。
    3.  在 `lib/multipl/firestore_room_state_controller.dart` 中增加 `sendAlivePing` 方法的實現。
2.  **程式碼輸出：** 輸出 `lib/multiplayer/firestore_room_state_controller.dart` 修改後的 **完整程式碼內容**。

#### **3.2 驗證步驟 (Verification Steps)**

1.  **`matchRoom` 驗證：**
    *   **場景一（創建新房）：** 當數據庫中沒有可加入的房間時，調用 `matchRoom` 應成功創建一個新房間，並返回 `roomId`。
    *   **場景二（加入舊房）：** 當數據庫中存在 `state: 'open'` 且未滿員的房間時，調用 `matchRoom` 應將使用者加入該房間，並返回該房間的 `roomId`。
2.  **`leaveRoom` 驗證：**
    *   **場景一（管理者離開，轉移權限）：** 當管理者調用 `leaveRoom` 且房內有其他玩家時，`managerUid` 應成功轉移，且原管理者被移除。
    *   **場景二（管理者離開，關閉房間）：** 當管理者調用 `leaveRoom` 且房內無其他玩家時，房間文檔應被刪除。
    *   **場景三（參與者離開）：** 當普通參與者調用 `leaveRoom` 時，系統應成功發送一個 `action: 'leave'` 的請求。
3.  **`sendAlivePing` 驗證：**
    *   調用 `sendAlivePing` 時，系統應成功發送一個 `action: 'alive'` 的請求。
