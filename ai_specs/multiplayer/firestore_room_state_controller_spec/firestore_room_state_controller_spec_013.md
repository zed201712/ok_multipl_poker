## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-ROOM-STATE-CONTROLLER-013` |
| **標題 (Title)** | `LOCAL REQUEST HANDLING & SAFETY FIXES` |
| **創建日期 (Date)** | `2026/01/06` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 針對 `FEAT-ROOM-STATE-CONTROLLER-012` 引入的本地 Loopback 優化機制，完善 `RoomRequest` 與 Controller 的處理邏輯。確保標記為 "Local" 的請求不會觸發 Firestore 的刪除或寫入操作，避免對不存在的文件執行操作導致錯誤。同時修復 `FirestoreTurnBasedGameController` 中可能誤刪除房間管理請求的邏輯。
*   **目的：**
    1.  **邏輯正確性 (Correctness)：** 修正 `FirestoreRoomStateController` 與 `FirestoreTurnBasedGameController` 中對本地模擬請求 (Local Request) 的處理方式，防止對 Firestore 發出無效的 `delete` 指令。
    2.  **安全性 (Safety)：** 確保 Transaction 操作時，不會因為嘗試刪除不存在的 Request 文件而失敗。防止遊戲控制器誤刪除 `join`/`leave` 等基礎設施請求。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **擴充 `RoomRequest` (`lib/entities/room_request.dart`)**
    *   新增欄位 `final bool isLocal;`，預設值為 `false`。
    *   標註 `@JsonKey(includeFromJson: false, includeToJson: false)` 以避免序列化到 Firestore。
    *   更新 `copyWith`、建構子與 `props`。

2.  **更新 `FirestoreRoomStateController` (`lib/multiplayer/firestore_room_state_controller.dart`)**
    *   **`sendRequest` (Local Loopback):** 在建立本地 `RoomRequest` 物件時，設定 `isLocal: true`。
    *   **`_managerRequestHandler`:** 在處理各類 Action (如 `alive`, `end_room`) 時，若需呼叫 `deleteRequest`，必須先檢查 `!request.isLocal`。
    *   **`_approveJoinRequest`:** 檢查 `!request.isLocal`。
    *   **`_handleLeaveRequest`:** 檢查 `!request.isLocal`。
    *   **`deleteRequest`:** 保持原樣，呼叫端負責檢查。

3.  **更新 `FirestoreTurnBasedGameController` (`lib/multiplayer/firestore_turn_based_game_controller.dart`)**
    *   **`_processRequests`:** 
        *   遍歷請求列表時，在呼叫 `deleteRequest` 之前，檢查 `if (!request.isLocal)`。
        *   **新增邏輯：** 跳過 (不處理且不刪除) 屬於 `FirestoreRoomStateController` 管理的請求 (`join`, `leave`, `alive`, `end_room`)，避免競態條件導致請求遺失。
    *   **`_handleStartGame`:** 清理 `start_game` 請求時，檢查 `if (!req.isLocal)`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **Entity:** `lib/entities/room_request.dart`
*   **Controller:** `lib/multiplayer/firestore_room_state_controller.dart`
*   **Controller:** `lib/multiplayer/firestore_turn_based_game_controller.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `effective_dart`。
*   保持 `RoomRequest` 的不可變性 (Immutable)。

---

### **Section 3: 改善建議與邏輯檢查 (Improvement & Logic Check)**

#### **3.1 邏輯檢查**
*   **Transaction Consistency:** 雖然 Local Request 不存在於 Firestore，但其觸發的 *效果* (如更新 Room 的 `participants`) 仍需寫入 Firestore。因此，Transaction 依然是必要的，只是移除了對 Request 文件的 `delete` 操作。
*   **Request Deletion Safety:** `FirestoreTurnBasedGameController` 原本會無條件刪除所有看到的請求，這可能導致 `join` 請求在被 `FirestoreRoomStateController` 處理前就被刪除。需增加過濾邏輯。

#### **3.2 測試建議**
*   應驗證當 `isLocal: true` 時，Mock Firestore 的 `delete` 方法未被呼叫。
*   驗證 `join` 請求存在時，`FirestoreTurnBasedGameController` 不會刪除它。

---

### **Section 4: 產出 Commit Message**

```text
fix(controller): handle local requests safely and prevent infrastructure request deletion

- Entity: Added `isLocal` flag to `RoomRequest`.
- Controller: Updated `FirestoreRoomStateController` to bypass Firestore deletion for local requests.
- GameController: Updated `FirestoreTurnBasedGameController` to check `isLocal` before deleting.
- Fix: Prevented `FirestoreTurnBasedGameController` from deleting `join`, `leave`, `alive`, `end_room` requests which are managed by the room controller.
```
