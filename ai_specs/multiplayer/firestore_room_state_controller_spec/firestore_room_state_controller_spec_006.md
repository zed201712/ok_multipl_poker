## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
| :--- |:---|
| **任務 ID (Task ID)** | `FEAT-ROOM-STATE-CONTROLLER-006` |
| **創建日期 (Date)** | `2025/12/06` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 重構 `FirestoreRoomStateController`，為其對外的 `Stream`（`roomsStream` 和 `getRoomStateStream`）增加一個中介層。目的是將底層的 Firestore `Stream` 封裝在內部，改為由 Controller 自己管理 `StreamController`，從而獲得對數據流的完全控制權，以便在將數據發送給客戶端之前，先進行內部額外的操作或資料處理。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **重構 `FirestoreRoomStateController`：**
    1.  引入兩個私有的 `StreamController`：
        *   一個 `BehaviorSubject<List<Room>>` 用於管理所有房間的列表。
        *   一個 `BehaviorSubject<RoomState>` 用於管理單一房間的狀態。
        *   (使用 `BehaviorSubject` 是為了讓新的監聽者能立即獲取最新的事件)。

    2.  將原本 `roomsStream()` 方法返回的 Firestore `Stream` 改為返回私有 `StreamController` 的 `stream`。

    3.  將原本 `getRoomStateStream()` 方法返回的 `CombineLatestStream` 改為返回私有 `StreamController` 的 `stream`。

    4.  在 `FirestoreRoomStateController` 內部，創建私有的 `StreamSubscription` 來監聽底層的 Firestore `Stream`。

    5.  當從 Firestore `Stream` 收到新數據時，不要直接返回，而是將其 `add` 到對應的私有 `StreamController` 中。

    6.  新增一個 `dispose()` 方法，用於關閉所有內部的 `StreamController` 和 `StreamSubscription`，以防止內存洩漏。

    7.  客戶端（例如 `DemoRoomStateWidget`）與 `FirestoreRoomStateController` 的互動方式應保持不變，但需要記得在適當的時機（例如 `State.dispose`）調用新的 `controller.dispose()` 方法。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/multiplayer/firestore_room_state_controller.dart`
*   **修改：** `lib/demo/demo_room_state_widget.dart` (為了調用 `dispose`)

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   應使用 `rxdart` 套件中的 `BehaviorSubject` 來實現 `StreamController`，以方便地快取最新值。
*   Controller 的生命週期管理至關重要，必須確保 `dispose` 被正確實現和調用。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`lib/multiplayer/firestore_room_state_controller.dart` 的 API 變化:**
    ```dart
    class FirestoreRoomStateController {
      // --- Public Properties ---
      ValueStream<List<Room>> get roomsStream; // 改為 getter
      ValueStream<RoomState> get roomStateStream; // 新增 getter

      // --- Public Methods ---
      
      /// Switches the room state stream to a new room ID.
      void setRoomId(String roomId);

      /// Disposes the controller and releases all resources.
      void dispose();

      // ... 其他 public 方法保持不變

      // --- Removed Methods ---
      // Stream<RoomState> getRoomStateStream({required String roomId}); // 將被 setRoomId 和 roomStateStream 取代
    }
    ```

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  修改 `lib/multiplayer/firestore_room_state_controller.dart` 以實現新的 `StreamController` 中介層架構，並新增 `dispose` 和 `setRoomId` 方法。
    2.  修改 `lib/demo/demo_room_state_widget.dart`，調整其與新 Controller 的互動方式，並在 `dispose` 方法中調用 `_roomController.dispose()`。
2.  **程式碼輸出：** 分別輸出 `lib/multiplayer/firestore_room_state_controller.dart` 和 `lib/demo/demo_room_state_widget.dart` 修改後的 **完整程式碼內容**。

#### **3.2 驗證步驟 (Verification Steps)**

1.  **驗證房間列表：** 啟動 Demo Widget 後，應能正常看到所有房間的列表。
2.  **驗證切換房間：** 在 Demo Widget 中點擊一個房間，應能看到對應的房間詳細資訊。
3.  **驗證狀態更新：**
    *   更新房間資訊（如標題），UI 應即時反應。
    *   發送 `join` 請求，管理者應能看到請求，批准後，參與者列表應更新。
4.  **驗證資源釋放：** 關閉 Demo Widget 時，不應在控制台看到任何關於內存洩漏或未關閉 Stream 的錯誤。
