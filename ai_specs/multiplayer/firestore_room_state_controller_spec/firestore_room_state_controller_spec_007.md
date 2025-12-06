## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
| :--- |:---|
| **任務 ID (Task ID)** | `FEAT-ROOM-STATE-CONTROLLER-007` |
| **創建日期 (Date)** | `2025/12/06` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 將使用者身份驗證（`FirebaseAuth`）的邏輯從 `demo_room_state_widget.dart` 遷移至 `firestore_room_state_controller.dart`。使 Controller 成為唯一負責處理用戶匿名登入和管理用戶狀態的地方，從而簡化 Widget 層的依賴和邏輯。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **修改 `FirestoreRoomStateController`：**
    1.  在其構造函數中增加 `FirebaseAuth` 的依賴。
    2.  新增一個 `ValueStream<String?> get userIdStream` 來向外暴露當前用戶的 UID。
    3.  新增一個 `String? get currentUserId` 的 getter，方便非響應式地獲取當前用戶 UID。
    4.  新增一個 `Future<void> initializeUser()` 的 public 方法。此方法負責檢查當前登入用戶，如果沒有用戶，則執行匿名登入，並將獲取到的 `uid` 添加到 `userIdStream` 中。
    5.  修改以下現有方法，使其不再需要從外部傳入 `userId` 或 `creatorUid`，而是直接使用內部管理的 `currentUserId`：
        *   `createRoom` (移除 `creatorUid` 參數)
        *   `matchRoom` (移除 `userId` 參數)
        *   `leaveRoom` (移除 `userId` 參數)
        *   `sendRequest` (移除 `participantId` 參數)
        *   `sendAlivePing` (移除 `userId` 參數)

*   **修改 `DemoRoomStateWidget`：**
    1.  移除所有 `FirebaseAuth` 的直接引用和實例。
    2.  更新 `FirestoreRoomStateController` 的實例化過程，將 `FirebaseAuth.instance` 傳遞給其構造函數。
    3.  在 `initState` 或 `_initUser` 中，調用 `_roomController.initializeUser()` 來觸發用戶初始化流程。
    4.  監聽 `_roomController.userIdStream` 來獲取 `userId` 並更新 UI。
    5.  移除本地的 `_userId` 狀態變數。
    6.  更新所有對 Controller 方法的調用，移除 `userId` 相關的參數。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/multiplayer/firestore_room_state_controller.dart`
*   **修改：** `lib/demo/demo_room_state_widget.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   Controller 應作為單一的數據來源 (`Single Source of Truth`)，統一管理房間狀態和用戶認證狀態。
*   Widget 層應盡可能保持無狀態，僅響應從 Controller 傳來的數據流。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`lib/multiplayer/firestore_room_state_controller.dart` 的 API 變化:**
    ```dart
    class FirestoreRoomStateController {
      // Constructor
      FirestoreRoomStateController(this._firestore, this._auth, this._collectionName);

      // --- Public Streams & Properties ---
      ValueStream<String?> get userIdStream;
      String? get currentUserId;
      ValueStream<List<Room>> get roomsStream;
      ValueStream<RoomState?> get roomStateStream;

      // --- Public Methods ---
      Future<void> initializeUser();
      void setRoomId(String? roomId);
      void dispose();

      // --- Modified Methods (Signature Changed) ---
      Future<String> createRoom({
        String? roomId,
        required String title,
        required int maxPlayers,
        required String matchMode,
        required String visibility,
      });

      Future<String> matchRoom({
        required String title,
        required int maxPlayers,
        required String matchMode,
        required String visibility,
      });

      Future<void> leaveRoom({required String roomId});
      Future<void> sendAlivePing({required String roomId});
      Future<String> sendRequest({
        required String roomId,
        required Map<String, dynamic> body,
      });
      
      // ... other methods like updateRoom, deleteRoom remain unchanged.
    }
    ```

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  修改 `lib/multiplayer/firestore_room_state_controller.dart` 以整合 `FirebaseAuth` 邏輯，並更新相關方法簽名。
    2.  修改 `lib/demo/demo_room_state_widget.dart` 以移除 `FirebaseAuth` 依賴，並調整與新 Controller 的互動方式。
2.  **程式碼輸出：** 分別輸出 `lib/multiplayer/firestore_room_state_controller.dart` 和 `lib/demo/demo_room_state_widget.dart` 修改後的 **完整程式碼內容**。

#### **3.2 驗證步驟 (Verification Steps)**

1.  **用戶初始化：** 啟動 Demo Widget，應用應自動執行匿名登入，並在 UI 上顯示由 Controller 提供的用戶 ID。
2.  **無直接依賴：** 確認 `demo_room_state_widget.dart` 檔案中不再有 `import 'package:firebase_auth/firebase_auth.dart';`。
3.  **功能正常：** 測試 `Create Room`, `Match Room`, `Leave Room` 等按鈕功能，確認它們在不需要傳遞 `userId` 的情況下仍能正常工作。
4.  **狀態一致性：** 確認所有操作（如創建、加入、離開房間）都能正確地反映在 UI 上，數據流從 Controller 到 Widget 的傳遞正常。
