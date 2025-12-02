## AI 專案任務指示文件 (Widget Creation)

### **文件標頭 (Metadata)**

| 區塊 | 內容                          | 
| :--- |:----------------------------|
| **任務 ID (Task ID)** | `FEAT-DEMO-ROOM-SCREEN-002` |
| **創建日期 (Date)** | `2025/12/02`                |
| **目標版本 (Target Version)** | `N/A`                       |
| **專案名稱 (Project)** | `ok_multipl_poker`          |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

* **說明：** 建立一個新的 `DemoRoomWidget`，將 `RoomDemoScreen` 的 UI 邏輯與 `FirestoreRoomController` 的資料邏輯結合，並讓 `DemoRoomScreen` 專注於頁面框架。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **建立新 Widget:**
    1.  建立一個新檔案：`lib/play_session/demo_room_widget.dart`。
    2.  在此檔案中建立一個名為 `DemoRoomWidget` 的 `StatefulWidget`。
*   **UI 邏輯遷移:**
    1.  將 `RoomDemoScreen.dart` 中 `_RoomDemoWidgetState` 的所有 UI 元素、`TextEditingController`、以及狀態管理的邏輯全部遷移到 `_DemoRoomWidgetState` 中。
    2.  `DemoRoomWidget` 將負責處理所有用戶輸入和 UI 互動。
*   **資料邏輯整合:**
    1.  `_DemoRoomWidgetState` 必須實例化並持有一個 `FirestoreRoomController`。
    2.  所有按鈕的 `onPressed` 事件 (如 `_createRoom`, `_joinRoom`) 都必須呼叫 `FirestoreRoomController` 的對應方法來執行資料庫操作。
    3.  Widget 內部必須使用 `StreamBuilder` 來監聽從 `FirestoreRoomController` 提供的 `roomsStream` 和 `participantStream`，並根據資料流更新 UI。
*   **簡化 `RoomDemoScreen`:**
    1.  重構 `RoomDemoScreen.dart`，使其成為一個簡單的 `StatelessWidget`。
    2.  它的 `build` 方法中只應包含 `Scaffold`、`AppBar`，以及將新的 `DemoRoomWidget` 作為其 `body`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **新增：** `lib/play_session/demo_room_widget.dart`
*   **修改：** `lib/play_session/RoomDemoScreen.dart`
*   **參考：** `lib/play_session/firestore_room_controller.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **語言：** Dart / Flutter
*   **架構：** Controller-View 分離。`DemoRoomWidget` (View) 負責 UI，`FirestoreRoomController` (Controller) 負責資料處理。
*   **慣例：** 
    *   `DemoRoomWidget` 不應直接依賴 `cloud_firestore`。
    *   保持 `RoomDemoScreen` 的無狀態特性。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`demo_room_widget.dart`:**
    *   `DemoRoomWidget`: `StatefulWidget`
    *   `_DemoRoomWidgetState`:
        *   `late final FirestoreRoomController _roomController;`
        *   `final _roomTitleController = TextEditingController();` (以及其他 controllers)
        *   `_createRoom()`: `Future<void>`
        *   `_joinRoom()`: `Future<void>`
        *   內部包含 `RoomsStreamWidget` 和 `ParticipantStreamWidget` 子元件。
*   **`RoomDemoScreen.dart`:**
    *   `RoomDemoScreen`: `StatelessWidget`
    *   `build()` 方法回傳 `Scaffold(body: DemoRoomWidget())`。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  建立並撰寫 `lib/play_session/demo_room_widget.dart` 的完整內容。
    2.  重構並撰寫 `lib/play_session/RoomDemoScreen.dart` 的完整內容。
2.  **程式碼輸出：** 依序提供上述兩個檔案的**完整修改後內容**。

#### **3.2 驗證步驟 (Verification Steps)**

*   **功能應與重構前完全一致。**
    1.  啟動 App 並導航至 `RoomDemoScreen`。
    2.  確認 `DemoRoomWidget` 顯示正常，且匿名登入 `userId` 顯示正常。
    3.  執行「建立房間」和「加入房間」操作。
    4.  驗證 UI 上的 `RoomsStreamWidget` 和 `ParticipantStreamWidget` 能正確反映 Firestore 中的數據變化。
    5.  確認 `RoomDemoScreen.dart` 的程式碼已被大幅簡化。

---

### **Section 4: 上一輪回饋 (Previous Iteration Feedback) (可選)**

*   N/A
