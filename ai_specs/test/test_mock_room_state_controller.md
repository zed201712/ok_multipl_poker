| **任務 ID (Task ID)** | `TEST-MOCK-ROOM-STATE-CONTROLLER-001` |
| **創建日期 (Date)** | `2025/12/11` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 針對 `lib/multiplayer/mock_firestore_room_state_controller.dart` 建立一個完整的單元測試套件。此測試旨在驗證 `MockFirestoreRoomStateController` 的內部邏輯是否正確，並確保其作為 `FirestoreRoomStateController` 的模擬替代品時，其行為（如狀態管理、Stream 事件發送、方法互動）符合預期。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **建立測試檔案：**
    *   在 `test/multiplayer/` 目錄下建立新檔案 `mock_firestore_room_state_controller_test.dart`。

*   **撰寫測試案例：**
    *   **`createRoom`:** 驗證呼叫 `createRoom` 後，`roomsStream` 會發出包含新房間的列表，且房間的初始屬性（如 `creatorUid`, `managerUid`）設定正確。
    *   **`leaveRoom` (管理員，無其他成員):** 驗證當房間中唯一的管理員呼叫 `leaveRoom` 時，該房間會被正確刪除 (`deleteRoom` 被呼叫)。
    *   **`leaveRoom` (管理員，有其他成員):** 驗證當房間管理員離開但仍有其他成員時，會觸發 `handoverRoomManager`，並發送 `action: 'leave'` 的請求。
    *   **`leaveRoom` (非管理員成員):** 驗證非管理員成員離開時，僅會發送 `action: 'leave'` 的請求，而不會刪除房間或轉交管理權。
    *   **`matchRoom` (無符合房間):** 驗證當沒有可匹配的公開房間時，`matchRoom` 會自動呼叫 `createRoom` 建立一個新房間。
    *   **`matchRoom` (有符合房間):** 先手動加入一個可匹配的房間，然後驗證 `matchRoom` 會將使用者加入該房間，而不是建立新房間。
    *   **`setRoomId` 與 `roomStateStream`:** 驗證呼叫 `setRoomId` 後，`roomStateStream` 會發出對應的 `RoomState`。同時驗證傳入 `null` 時，`roomStateStream` 也會發出 `null`。
    *   **`sendRequest`:** 驗證呼叫 `sendRequest` 後，對應的 `roomStateStream` 會收到一個包含新請求的 `RoomState` 更新。
    *   **`handoverRoomManager`:** 驗證呼叫此方法會將 `managerUid` 轉交給下一位參與者，或者在沒有其他參與者時刪除房間。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **新增：** `test/multiplayer/mock_firestore_room_state_controller_test.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **測試框架：** 使用 `flutter_test` 和 `test` 套件。
*   **非同步測試：** 使用 `expectLater` 和 `emitsInOrder` 來驗證 `Stream` 的行為。
*   **測試結構：** 使用 `group` 將相關的測試案例組織在一起，並在 `setUp` 中初始化 `MockFirestoreRoomStateController` 實例。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  建立 `test/multiplayer/mock_firestore_room_state_controller_test.dart` 檔案。
    2.  根據「詳細需求」區塊中定義的測試案例，撰寫完整的測試程式碼。
    3.  將完成的測試程式碼寫入新檔案中。

2.  **程式碼輸出：**
    *   輸出 `test/multiplayer/mock_firestore_room_state_controller_test.dart` 的完整程式碼。

#### **3.2 驗證步驟 (Verification Steps)**

*   **執行測試：** 執行 `flutter test test/multiplayer/mock_firestore_room_state_controller_test.dart`，並確保所有測試案例均通過。