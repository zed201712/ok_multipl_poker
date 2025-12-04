## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
| :--- |:---| 
| **任務 ID (Task ID)** | `FEAT-DEMO-ROOM-STATE-WIDGET-001` |
| **創建日期 (Date)** | `2025/12/05` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 建立一個新的 Demo Widget (`demo_room_state_widget.dart`) 以展示 `FirestoreRoomStateController` 的功能。同時，更新 `FirestoreRoomStateController` 以支援一個新的、基於請求/回應模式的參與者加入流程，並強化房間狀態的更新機制。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **建立 `DemoRoomStateWidget`：**
    1.  在 `lib/demo/` 路徑下建立 `demo_room_state_widget.dart` 檔案。
    2.  此 Widget 將參考 `demo_room_widget.dart` 的版面配置，但改為使用 `FirestoreRoomStateController`。
    3.  **UI 功能**:
        *   **房間建立**：一個表單及按鈕，用於建立新房間。
        *   **房間資訊**：即時顯示當前 `Room` 的 `body`、`participants` 和 `seats` 列表。
        *   **加入請求**：一個按鈕，讓非管理員的參與者可以發送 `body: {'action': 'join'}` 的請求來加入房間。
        *   **請求列表 (管理員視角)**：即時顯示 `rooms/{roomId}/requests` 子集合中的所有請求。
        *   **請求核准 (管理員視角)**：在請求列表的每個項目旁，提供一個「核准」按鈕。點擊後，將該請求的 `participantId` 加入到 `Room` 的 `participants` 陣列中。

*   **修改 `FirestoreRoomStateController`：**
    1.  **新增 `updateRoomBody` 方法**：提供一個專門用來更新 `Room` 文件中 `body` 欄位的功能。
    2.  **更新 `createRoom` 方法**：在建立房間時，初始化 `body` 為空字串，並將 `creatorUid` 同時作為 `participants` 和 `seats` 列表的第一個元素。

*   **新的參與者加入流程：**
    1.  **參與者 (Participant)**：欲加入房間時，呼叫 `sendRequest` 方法，傳入 `body: {'action': 'join'}`。
    2.  **房間管理員 (Manager)**：在其裝置上監聽 `getRequestsStream`。當收到 `join` 請求時，UI 上會顯示一個核准按鈕。
    3.  **管理員核准**：點擊按鈕後，讀取當前的 `Room` 物件，將新的 `participantId` 加入 `participants` 列表中，然後呼叫 `updateRoom` 方法將更新後的列表寫回 Firestore。
    4.  **房間狀態更新**：管理員核准後，會呼叫 `updateRoomBody`，將 `body` 更新為 `'updated: $ManagerId, requesterId: $request.participantId'`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **新增：** `lib/demo/demo_room_state_widget.dart`
*   **修改：** `lib/multiplayer/firestore_room_state_controller.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **UI 風格:** 應與 `demo_room_widget.dart` 保持一致，使用 `StatefulWidget`、`StreamBuilder` 和標準 Material Design 元件。
*   **狀態管理:** UI 的狀態更新應完全由 Firestore 的 `Stream` 驅動。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`lib/multiplayer/firestore_room_state_controller.dart`:**
    ```dart
    class FirestoreRoomStateController {
      // ... existing methods

      // ## Method to be Added ##
      Future<void> updateRoomBody({
        required String roomId,
        required String body,
      });

      // ## Method to be Modified ##
      Future<String> createRoom({
        String? roomId,
        required String creatorUid,
        required String title,
        required int maxPlayers,
        required String matchMode,
        required String visibility,
      }); // Logic inside will be updated
    }
    ```

*   **`lib/demo/demo_room_state_widget.dart`:**
    *   應包含一個 `StatefulWidget` 和它的 `State` class。
    *   `State` class 內應初始化 `FirebaseAuth` 和 `FirestoreRoomStateController`。
    *   UI 應由多個 `StreamBuilder` 組成，分別監聽 `roomStream`、`getRequestsStream` 等。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  修改 `lib/multiplayer/firestore_room_state_controller.dart`，加入 `updateRoomBody` 方法並更新 `createRoom` 的邏輯。
    2.  建立 `lib/demo/demo_room_state_widget.dart`，並根據需求實作 UI 和互動邏輯。
2.  **程式碼輸出：** 分別輸出 `firestore_room_state_controller.dart`（修改後）和 `demo_room_state_widget.dart` 的 **完整程式碼內容**。

#### **3.2 驗證步驟 (Verification Steps)**

1.  **啟動 Demo Widget**：確認 UI 正常顯示，並成功匿名登入取得 User ID。
2.  **使用者 A 建立房間**：確認房間成功建立，且 `Room` 文件中的 `participants` 和 `seats` 列表都包含使用者 A 的 ID。
3.  **使用者 B 加入房間**：
    *   在另一裝置或模擬器上，輸入房間 ID。
    *   點擊「請求加入」按鈕。
    *   確認 `rooms/{roomId}/requests` 子集合中出現一筆新文件。
4.  **使用者 A 核准請求**：
    *   在使用者 A 的畫面上，應能看到使用者 B 的加入請求。
    *   點擊「核准」按鈕。
    *   確認 `Room` 文件中的 `participants` 列表已更新，包含了使用者 B 的 ID。
    *   確認 `Room` 文件中的 `body` 欄位已更新為指定的訊息格式。
5.  **狀態同步驗證**：確認使用者 B 的畫面上也即時顯示了更新後的 `participants` 列表。