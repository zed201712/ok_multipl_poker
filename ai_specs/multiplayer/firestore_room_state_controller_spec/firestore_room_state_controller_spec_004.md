## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                               |
| :--- |:---------------------------------|
| **任務 ID (Task ID)** | `FEAT-ROOM-STATE-CONTROLLER-004` |
| **創建日期 (Date)** | `2025/12/05`                     |
| **目標版本 (Target Version)** | `N/A`                            |
| **專案名稱 (Project)** | `ok_multipl_poker`               |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 重構 `FirestoreRoomStateController`，將其內部的多個 public `Stream` 封裝起來。目標是提供一個統一的、對外的 `Stream` 來暴露特定房間的完整狀態 (包含 `Room` 物件、請求列表、回應列表)，以簡化客戶端的使用和狀態同步邏輯。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **新增 `Entity` (`RoomState`)：**
    1.  在 `lib/entities/` 目錄下建立 `room_state.dart` 檔案。
    2.  定義 `RoomState` class，用來整合單一房間的所有相關狀態。
    3.  `RoomState` 應為不可變 (immutable) 物件，並包含 `Room?`、`List<RoomRequest>` 和 `List<RoomResponse>`。

*   **修改 `pubspec.yaml`：**
    1.  添加 `rxdart` 套件依賴，用於組合多個 Stream。

*   **重構 `FirestoreRoomStateController`：**
    1.  將以下 `Stream` 方法改為 private (方法名稱前加 `_`)：
        *   `roomStream` -> `_roomStream`
        *   `getRequestsStream` -> `_getRequestsStream`
        *   `getResponsesStream` -> `_getResponsesStream`
    2.  **移除** `getRoomBodyStream` 方法，因為它的功能可以被 `_roomStream` 完全取代 (Room 物件已包含 body 資訊)。
    3.  **保留** `roomsStream()` 的 public 屬性，因為它提供的是房間列表，與單一房間的狀態無關，功能獨特。
    4.  **新增** 一個 public 的 `Stream<RoomState> getRoomStateStream({required String roomId})` 方法。
    5.  此方法將使用 `rxdart` 的 `CombineLatestStream` 來組合 `_roomStream`、`_getRequestsStream` 和 `_getResponsesStream`，並在任一 Stream 有更新時，發出一個新的 `RoomState` 物件。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **新增：** `lib/entities/room_state.dart`
*   **修改：** `lib/multiplayer/firestore_room_state_controller.dart`
*   **修改：** `pubspec.yaml`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **`RoomState` Entity:** 應為不可變 (immutable)，並建議實現 `Equatable` 以方便比較。
*   **Controller:** 應使用 `rxdart` 來進行流的組合，確保響應式和高效能。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`lib/entities/room_state.dart`:**
    ```dart
    import 'package:equatable/equatable.dart';
    import 'room.dart';
    import 'room_request.dart';
    import 'room_response.dart';

    class RoomState extends Equatable {
      final Room? room;
      final List<RoomRequest> requests;
      final List<RoomResponse> responses;

      const RoomState({
        this.room,
        this.requests = const [],
        this.responses = const [],
      });

      @override
      List<Object?> get props => [room, requests, responses];
    }
    ```

*   **`lib/multiplayer/firestore_room_state_controller.dart` 的 Public API 變化:**
    ```dart
    class FirestoreRoomStateController {
      // --- Public Streams ---

      /// Returns a stream of all rooms. (Remains Public)
      Stream<List<Room>> roomsStream();
      
      /// Returns a unified stream of the state for a specific room. (New)
      Stream<RoomState> getRoomStateStream({required String roomId});

      // --- Privatized Streams (Not part of public API anymore) ---
      // _roomStream()
      // _getRequestsStream()
      // _getResponsesStream()

      // --- Removed Stream ---
      // getRoomBodyStream() // This is now redundant.

      // ... other public methods like createRoom, sendRequest etc. remain unchanged.
    }
    ```

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  修改 `pubspec.yaml` 加入 `rxdart`。
    2.  建立 `lib/entities/room_state.dart` 檔案並實作 `RoomState` class。
    3.  修改 `lib/multiplayer/firestore_room_state_controller.dart`，將舊的 Stream 方法改為 private，並實作新的 `getRoomStateStream`。
2.  **程式碼輸出：** 分別輸出 `pubspec.yaml` (修改後)、`room_state.dart`、以及 `firestore_room_state_controller.dart` (修改後) 的 **完整程式碼內容**。

#### **3.2 驗證步驟 (Verification Steps)**

1.  **監聽房間狀態：** 呼叫 `getRoomStateStream` 監聽一個房間。
2.  **更新房間資訊：** 呼叫 `updateRoom` (例如更新 `title`)，驗證 `RoomState` Stream 會收到更新，且 `RoomState.room` 的 `title` 是最新的。
3.  **發送請求：** 呼叫 `sendRequest`，驗證 `RoomState` Stream 會收到更新，且 `RoomState.requests` 列表包含了新的請求。
4.  **發送回應：** 呼叫 `sendResponse`，驗證 `RoomState` Stream 會收到更新，且 `RoomState.responses` 列表包含了新的回應。
5.  **確認舊 Stream 不可見：** 確認無法從外部直接呼叫 `_roomStream`, `_getRequestsStream` 等私有方法。
6.  **確認房間列表**：確認呼叫 `roomsStream()` 仍然可以正常獲取所有房間的列表。
