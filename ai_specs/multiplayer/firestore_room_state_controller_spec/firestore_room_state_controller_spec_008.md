| **任務 ID (Task ID)** | `FEAT-DEMO-ROOM-STATE-WIDGET-008` |
| **創建日期 (Date)** | `2025/12/06` |

### 1. 目的 (Objective)

本文件旨在規劃 `firestore_room_state_controller` 的重構與功能強化。主要目標有二：
1.  將目前由 `demo_room_state_widget.dart` 處理的加入房間請求 (`join request`) 邏輯，移至 `firestore_room_state_controller.dart` 中，以集中管理房間相關操作。
2.  賦予 `firestore_room_state_controller.dart` 中的房間管理員 (Room Manager) 自動處理加入請求的能力，簡化管理流程。

### 2. 重構：移動請求邏輯 (Refactoring: Move Request Logic)

#### 2.1. 在 `firestore_room_state_controller.dart`

*   **新增 public 方法**: `Future<void> requestToJoinRoom({required String roomId})`
    *   **目的**: 封裝發送「加入房間」請求的邏輯。
    *   **內部實現**:
        1.  檢查 `currentUserId` 是否存在，若無則拋出異常。
        2.  調用內部的 `sendRequest` 方法，傳入 `roomId` 與固定的 `body: {'action': 'join'}`。

#### 2.2. 在 `demo_room_state_widget.dart`

*   **修改 `_requestToJoin` 方法**:
    *   移除直接調用 `_roomController.sendRequest` 的程式碼。
    *   改為調用 `_roomController.requestToJoinRoom(roomId: roomId)`。

### 3. 新功能：管理者自動同意請求 (New Feature: Manager Auto-Approval)

#### 3.1. 在 `firestore_room_state_controller.dart`

*   **新增 private 方法**: `Future<void> _approveJoinRequest(RoomRequest request, Room room)`
    *   **目的**: 處理單一的加入請求，此邏輯從 `demo_room_state_widget.dart` 的 `_approveRequest` 方法遷移並強化。
    *   **內部實現**:
        1.  **檢查房間容量**: 驗證 `room.participants.length < room.maxPlayers`。如果房間已滿，則不進行任何操作，直接返回。
        2.  **檢查重複加入**: 如果請求者 (`request.participantId`) 已經在 `room.participants` 列表中，則僅刪除此請求後返回。
        3.  將請求者 ID 加入到 `participants` 列表中。
        4.  調用 `updateRoom`，使用新的 `participants` 列表更新 Firestore 中的文件。
        5.  調用 `deleteRequest` 刪除已處理的請求。

*   **新增 private 方法**: `void _managerRequestHandler(RoomState roomState)`
    *   **目的**: 作為 Room Manager 的核心處理器，監聽並自動處理收到的請求。
    *   **內部實現**:
        1.  從 `roomState` 中獲取 `room` 和 `requests`。
        2.  檢查 `room` 是否為空，以及 `currentUserId` 是否等於 `room.managerUid`。如果不是管理者，則不進行任何操作。
        3.  過濾出 `requests` 中 `body['action'] == 'join'` 的請求。
        4.  遍歷所有符合條件的加入請求，異步調用 `_approveJoinRequest` 方法進行處理。

*   **修改 `setRoomId` 方法**:
    *   在 `_roomStateSubscription` 的 `listen` 回調中，於 `_roomStateController.add(roomState)` 之後，調用 `_managerRequestHandler(roomState)`。這將確保每次房間狀態更新時，都會觸發管理者自動處理的邏輯。
