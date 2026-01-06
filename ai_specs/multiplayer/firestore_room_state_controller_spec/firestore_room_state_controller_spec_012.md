## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-ROOM-STATE-CONTROLLER-012` |
| **標題 (Title)** | `ROOM MANAGER OPTIMIZATION & ENTITY UTILITIES` |
| **創建日期 (Date)** | `2026/01/06` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 在 `FirestoreRoomStateController` 中新增房主權限判斷、優化房主發送請求的流程（減少 Firestore 寫入），並實作 `end_room` 功能與 `RoomState` 的深拷貝方法。
*   **目的：**
    1.  **效能優化 (Performance)：** 當房主自己發送請求（如踢人、結束房間）時，略過寫入 `requests` 集合的步驟，直接在本地觸發邏輯，減少延遲與資料庫寫入成本。
    2.  **功能擴充 (Feature Expansion)：** 支援 `end_room` 動作，允許房主主動關閉房間。
    3.  **程式碼健壯性 (Robustness)：** 為 `RoomState` 補全 `copyWith` 方法，方便狀態操作與測試。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **新增房主判斷 Helper (`_isCurrentUserTheManager`)**
    *   在 `FirestoreRoomStateController` 中新增私有方法 `bool _isCurrentUserTheManager()`。
    *   邏輯：檢查 `currentUserId` 是否不為空且等於 `_roomsController` (或當前 RoomState) 中房間的 `managerUid`。

2.  **實作 `end_room` 處理邏輯**
    *   在 `_managerRequestHandler` 內的動作判斷中，新增對 `action: 'end_room'` 的支援。
    *   邏輯：若收到此請求且執行者為房主，直接呼叫 `deleteRoom`。

3.  **實作 `RoomState.copyWith`**
    *   修改 `lib/entities/room_state.dart`。
    *   新增 `copyWith` 方法，支援 `room`, `requests`, `responses` 的深拷貝或替換。

4.  **優化 `sendRequest` (Local Loopback)**
    *   修改 `sendRequest` 方法。
    *   **邏輯變更：**
        *   在發送請求前，先呼叫 `_isCurrentUserTheManager()` 判斷。
        *   **若是房主**：不執行 Firestore `add` 操作。
            1.  建立一個帶有臨時 ID 的 `RoomRequest` 物件。
            2.  取得當前 `_roomStateController.value`。
            3.  使用 `RoomState.copyWith` 將新請求加入 `requests` 列表。
            4.  直接呼叫 `_managerRequestHandler(newRoomState)`。
            5.  *注意：需確保 Handler 內部嘗試刪除該 Request 時，若 Firestore 文件不存在不會拋出異常 (Firestore delete 是冪等的，通常安全，但需確認 Transaction 內行為)。*
        *   **若非房主**：維持原有邏輯，寫入 Firestore。

5.  **測試案例 (Testing)**
    *   **Unit Test (`room_state_test.dart`):** 測試 `copyWith` 是否正確複製且不影響原物件。
    *   **Integration/Unit Test (`firestore_room_state_controller_test.dart`):**
        *   測試 `sendRequest` 在房主身份下，不會呼叫 Firestore 的 `collection('requests').add` (透過 Mock)。
        *   測試 `sendRequest` 帶有 `end_room` action 時，房間被刪除。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **Controller:** `lib/multiplayer/firestore_room_state_controller.dart`
*   **Entity:** `lib/entities/room_state.dart`
*   **Tests:**
    *   `test/multiplayer/firestore_room_state_controller_test.dart`
    *   `test/entities/room_state_test.dart` (若不存在則建立)

#### **2.2 程式碼風格 (Style)**

*   遵循 `effective_dart`。
*   使用 `CombinedLatestStream` 或類似機制確保狀態同步（現有架構）。
*   確保 `copyWith` 處理 List 時建立新的實例 (`List.from`) 以避免引用共用。

---

### **Section 3: 改善建議與邏輯檢查 (Improvement & Logic Check)**

#### **3.1 潛在邏輯問題**
*   **Transaction 安全性：** `_approveJoinRequest` 使用 `transaction.delete(requestRef)`。如果 `sendRequest` 走了 Local Loopback 優化，該 `requestRef` 指向的文件在 Firestore 中並不存在。
    *   **風險：** 在 Transaction 中對不存在的文件執行 delete 可能會導致錯誤或 Transaction 失敗（取決於 SDK 版本行為）。
    *   **修正建議：** 在 `_managerRequestHandler` 處理優化過的請求時，應避免進入需要 Transaction 讀取該 Request 文件的路徑，或者修改 Handler 邏輯以容許「虛擬 Request」。
    *   **針對本任務：** `end_room` 是直接 `deleteRoom` (非 Transaction)，所以安全。但若未來擴充其他 Local Request，需特別注意 `_approveJoinRequest` 等依賴 Transaction 的邏輯。建議本次優化**僅針對不需要 Transaction 鎖定 Request 文件的操作**，或是確保 `deleteRequest` 使用一般的 `doc.delete()` (這是安全的) 而非 Transaction 內的 delete。

#### **3.2 架構建議**
*   目前的優化方案是一種 "Optimistic Update" 的變體，但僅限於房主對自己的 Loopback。這能顯著提升房主操作的反應速度（如踢人、開始遊戲）。

---

### **Section 4: 驗證與輸出 (Verification & Output)**

#### **4.1 驗證步驟**
1.  **RoomState Copy:** 寫單元測試驗證 `reqs = state.requests; new = state.copyWith(); reqs.add(...)` 不會影響 `new`。
2.  **Manager Check:** 確認 `_isCurrentUserTheManager` 能正確反映身份。
3.  **End Room:** 房主呼叫 `sendRequest(..., action: 'end_room')`，確認 Firestore 中房間文件被刪除。
4.  **Request Optimization:** 使用 Mock Firestore，房主發送請求時，驗證 `collection('requests').add` **未被呼叫**，但 `_managerRequestHandler` 被觸發。

---

### **Section 5: 產出 Commit Message**

```text
feat(controller): optimize manager requests and add end_room action

- Entity: Added `copyWith` to `RoomState` for immutable state updates.
- Controller: Implemented `_isCurrentUserTheManager` helper.
- Controller: Added handling for `end_room` action to delete the room.
- Perf: Optimized `sendRequest` for the room manager to bypass Firestore writes (local loopback) for self-issued commands, reducing latency and write costs.
- Tests: Added unit tests for RoomState deep copy and controller manager logic.
```
