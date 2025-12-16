### **文件標頭 (Metadata)**

| 區塊 | 內容 | 目的/對 AI 的意義 |
| :--- |:---|:---|
| **任務 ID (Task ID)** | `FEAT-ROOM-STATE-CONTROLLER-011` | 方便追蹤和版本控制。 |
| **創建日期 (Date)** | `2025/12/16` | - |

---

### **1. 目的 (Objective)**

本次任務旨在更新 `FirestoreRoomStateController`，以完全支援 `Room` 實體中 `participants` 屬性從 `List<String>` 到 `List<ParticipantInfo>` 的結構變更。

為此，我們將修改 `FirestoreRoomStateController` 的建構子，注入一個 `SettingsController` 實例，以便在需要時（如建立或加入房間）能直接獲取當前玩家的暱稱。這將取代在各個方法中獨立傳遞 `playerName` 參數的做法。

### **2. 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響的檔案**

*   `lib/multiplayer/firestore_room_state_controller.dart`
*   `lib/multiplayer/firestore_turn_based_game_controller.dart` *(連動修改)*
*   `test/multiplayer/firestore_room_state_controller_test.dart` *(連動修改)*

#### **2.2 `firestore_room_state_controller.dart` 修改細節**

1.  **建構子與屬性**
    *   匯入 `settings_controller.dart`。
    *   新增一個 `SettingsController` 屬性：`final SettingsController _settingsController;`
    *   更新建構子，接收並初始化此屬性：`FirestoreRoomStateController(this._firestore, this._auth, this._collectionName, this._settingsController)`

2.  **`createRoom` 方法**
    *   **移除參數**: 不再需要 `playerName` 參數。
    *   **更新資料**: 從 `_settingsController` 獲取玩家暱稱，並將 `participants` 欄位的初始值修改為一個 `ParticipantInfo` 物件陣列。
        *   **原程式碼**: `'participants': [creatorUid]`
        *   **新程式碼**:
            ```dart
            final playerName = _settingsController.playerName.value;
            'participants': [{'id': creatorUid, 'name': playerName}]
            ```

3.  **`matchRoom` 方法**
    *   **移除參數**: 不再需要 `playerName` 參數。
    *   **邏輯更新**:
        *   在**找不到可加入房間而需要新建**時，`createRoom` 方法會自動從 `_settingsController` 獲取暱稱。
        *   在**找到可加入房間**時，從 `_settingsController` 獲取暱稱，並將其包含在 `join` 請求的 `body` 中。
            *   **新程式碼**:
                ```dart
                final playerName = _settingsController.playerName.value;
                sendRequest(..., body: {'action': 'join', 'name': playerName});
                ```

4.  **`_approveJoinRequest` 方法**
    *   **存在性檢查**: 更新判斷玩家是否已在房間內的邏輯：`room.participants.any((p) => p.id == request.participantId)`
    *   **更新陣列**: 從請求的 `body` 中讀取 `name`，並使用 `FieldValue.arrayUnion` 添加一個完整的 `ParticipantInfo` 物件。

5.  **`_handleLeaveRequest` 方法**
    *   **更新陣列**: 修正 `FieldValue.arrayRemove` 的邏輯，使其能夠移除 `ParticipantInfo` 物件。
        *   **新程式碼 (在 Transaction 中)**:
            1.  讀取房間當前的 `participants` 列表。
            2.  找到與 `request.participantId` 匹配的 `ParticipantInfo` 物件。
            3.  將找到的完整物件（`.toJson()`）傳入 `FieldValue.arrayRemove`。

6.  **`leaveRoom`, `handoverRoomManager`, `_handleManagerTakeover` 方法**
    *   所有 `room.participants` 的相關操作都從直接比較字串改為比較物件的 `id` 屬性（例如 `p.id != userId`）。

#### **2.3 連動修改 (Upstream Changes)**

由於 `FirestoreRoomStateController` 的建構子已變更，因此所有實例化該 Controller 的地方都需要進行相應的修改。

1.  **`firestore_turn_based_game_controller.dart`**
    *   **建構子更新**: `FirestoreTurnBasedGameController` 的建構子需新增 `required SettingsController settingsController` 參數。
    *   **實例化更新**: 在內部實例化 `FirestoreRoomStateController` 時，需將 `settingsController` 傳遞進去。
        *   **新程式碼**: `roomStateController = FirestoreRoomStateController(store, auth, collectionName, settingsController);`
    *   **移除 `matchAndJoinRoom` 的參數**: 由於 `FirestoreRoomStateController` 會自動從 `SettingsController` 獲取玩家名稱，因此 `matchAndJoinRoom` 方法不再需要 `playerName` 參數。

2.  **`firestore_room_state_controller_test.dart`**
    *   **測試環境設定**: 在測試的 `setUp` 或 `setUpAll` 中，需要建立一個 `FakeSettingsController` 的實例。
    *   **實例化更新**: 在測試中所有實例化 `FirestoreRoomStateController` 的地方，都需要將 `FakeSettingsController` 實例傳入其建構子中。

---

### **3. 改善建議與邏輯檢查 (Improvement & Logic Check)**

1.  **嚴重邏輯錯誤修正 (`_handleLeaveRequest`)**: `FieldValue.arrayRemove` 必須提供一個與陣列中元素完全相同的物件才能成功移除。在 Transaction 中先讀取再移除是正確的作法。

2.  **設計模式考量 (耦合性)**: 在建構子中注入 `SettingsController` 雖然增加了耦合度，但在整個 App 的生命週期中，`SettingsController` 作為一個頂層依賴，這種設計是常見且可接受的。

### **4. 驗證步驟 (Verification Steps)**

1.  確認在 `createRoom` 或 `matchRoom` (新房間) 後，Firestore 中的 `participants` 欄位是一個包含正確 `id` 和 `name`（來自 `SettingsController`）的物件陣列。
2.  確認在 `matchRoom` (加入房間) 後，`participants` 陣列能成功 `arrayUnion` 一個新的 `ParticipantInfo` 物件。
3.  由一位玩家執行 `leaveRoom`，確認 `_handleLeaveRequest` 能正確地從 `participants` 陣列中 `arrayRemove` 對應的物件。
4.  確認 `firestore_turn_based_game_controller.dart` 的建構子已更新，並且不再需要從外部傳入 `playerName`。
5.  確認相關測試檔案 (`firestore_room_state_controller_test.dart`) 已更新，並能成功運行。
