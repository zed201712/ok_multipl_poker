## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-ROOM-STATE-CONTROLLER-015` |
| **標題 (Title)** | `OPTIMIZE STREAMS WITH MANAGER UID FILTERING` |
| **創建日期 (Date)** | `2026/01/07` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 優化 `FirestoreRoomStateController` 的 Firestore 監聽器，透過 `where` 條件過濾不必要的資料讀取，提升效能與減少頻寬消耗。
*   **目的：**
    1.  **Request 優化：** 僅讓 Manager 讀取 `RoomRequest` (透過 `managerUid` 欄位)。
    2.  **Response 優化：** 僅讓目標 Participant 讀取 `RoomResponse` (透過 `participantId` 欄位)。
    3.  **資料結構調整：** 在 `RoomRequest` 中新增 `managerUid` 欄位以支援上述過濾。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **修改 `RoomRequest` Entity**
    *   在 `@/lib/entities/room_request.dart` 中新增 `final String managerUid` 欄位。
    *   更新 `toJson`, `fromJson` (或是 `factory`) 以及 `copyWith` 方法以支援新欄位。
    *   **注意：** 確保 `managerUid` 在建構時為必填 (required)。

2.  **修改 `FirestoreRoomStateController` 的 `sendRequest`**
    *   在 `@/lib/multiplayer/firestore_room_state_controller.dart` 中。
    *   修改 `sendRequest` 方法，使其在建立 Request 時填入目前房間的 `managerUid`。
    *   **實作細節：**
        *   若 `sendRequest` 時 `_roomStateController` 已有值 (例如已在房間內)，可直接取用 `_roomStateController.value!.room!.managerUid`。
        *   若 `_roomStateController` 無值 (例如 Join 時)，需要由呼叫端傳入 `managerUid`，或在 `sendRequest` 內部進行讀取 (建議由呼叫端 `matchRoom` 或 `requestToJoinRoom` 傳遞以減少讀取)。
        *   更新所有呼叫 `sendRequest` 的地方，確保 `managerUid` 正確填入。

3.  **修改 Stream 監聽邏輯 (`FirestoreRoomStateController`)**
    *   **`_getRequestsStream`**: 加入 `.where('managerUid', isEqualTo: currentUserId)`。
        *   這表示只有當「我是該 Request 指定的 Manager」時，我才會收到該 Request。
    *   **`_getResponsesStream`**: 加入 `.where('participantId', isEqualTo: currentUserId)`。
        *   這表示只有當「我是該 Response 的接收者」時，我才會收到該 Response。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **Entity:** `@/lib/entities/room_request.dart`
*   **Controller:** `@/lib/multiplayer/firestore_room_state_controller.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `effective_dart` 程式碼風格。
*   使用 Provider 進行狀態管理 (若適用，目前此 Controller 主要使用 RxDart/Streams)。

---

### **Section 3: 改善建議與邏輯檢查 (Improvement & Logic Check)**

#### **3.1 邏輯檢查 (Logic Check)**

1.  **Manager Handover (管理權轉移) 問題：**
    *   **風險：** 當 Manager 從 A 轉移給 B 時，舊的 Request (其 `managerUid` 為 A) 將不會被 B 收到 (因為 B 只監聽 `managerUid == B`)。
    *   **分析：** 這會導致在轉移瞬間尚未處理的 Requests 被「遺棄」。
    *   **緩解：** 對於輕量級遊戲，這通常可接受 (玩家可重試)。若需嚴格一致性，Handover 時應更新未處理 Request 的 `managerUid`，或讓新 Manager 短暫讀取舊 Manager 的 Request。本次任務暫不實作複雜 Handover 處理，但需知曉此限制。

2.  **`sendRequest` 的 `managerUid` 來源：**
    *   **問題：** 在 `matchRoom` 階段發送 `join` 請求時，使用者尚未「進入」房間 (`setRoomId` 尚未設定或 `RoomState` 尚未建立)，因此無法從 `_roomStateController` 取得 `managerUid`。
    *   **解決方案：** `sendRequest` 應接受 `managerUid` 作為選用參數。若未提供，則嘗試從 `_roomStateController` 獲取。若兩者皆無，則拋出例外或需額外讀取 Room Document。在 `matchRoom` 中，我們已經讀取了 `Room` 物件，應直接將其 `managerUid` 傳給 `sendRequest`。

#### **3.2 改善建議 (Suggestions)**

*   **參數化 `sendRequest`：** 修改 `sendRequest` 簽章，加入 `String? targetManagerUid`。
    *   `matchRoom` 呼叫時：傳入 `roomToJoin.managerUid`。
    *   `leaveRoom` / `alive` 呼叫時：可傳入 `null`，由函式內部取 `_roomStateController.value.room.managerUid`。
*   **安全性：** 確保 Firestore Index 已建立，否則 `where` 查詢可能會失敗 (尤其是複合查詢)。

---

### **Section 4: 產出 Commit Message**

```text
feat(room): optimize request/response streams with filtering

- Entity: Added `managerUid` to `RoomRequest`.
- Controller: Updated `FirestoreRoomStateController` streams:
  - `_getRequestsStream`: Filters by `managerUid == currentUserId`.
  - `_getResponsesStream`: Filters by `participantId == currentUserId`.
- Controller: Updated `sendRequest` to include `managerUid`.
- Refactor: Updated `matchRoom` to pass `managerUid` when joining.
```
