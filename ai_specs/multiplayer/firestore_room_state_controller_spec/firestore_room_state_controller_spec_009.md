| **任務 ID (Task ID)** | `FEAT-DEMO-ROOM-STATE-WIDGET-009` |
| **創建日期 (Date)** | `2025/12/07` |

### 1. 目的 (Objective)

本文件旨在規劃 `firestore_room_state_controller.dart` 的功能增強，主要目標如下：
1.  **引入房間存活機制 (Alive Management)**：為房間增加生命週期管理，自動清理和維護「失連」或「無效」的房間。
2.  **強化管理者能力**：擴展 `_managerRequestHandler` 的功能，使其能夠處理參與者的「離開」請求。
3.  **提升使用者體驗與系統穩健性**：實現明確的請求回饋機制，並處理系統中的 `alive` 訊號。

### 2. 新功能：房間存活機制 (Alive Management)

#### 2.1. 新增 Private Property

*   在 `FirestoreRoomStateController` 中新增一個 `static const`，定義房間的有效存活時間。
    ```dart
    // Defines how long a room is considered active without an update.
    static const Duration _aliveTime = Duration(minutes: 2);
    ```

#### 2.2. Manager 自動維護房間

*   **新增 Private 方法**: `void _performManagerDuties(List<Room> rooms)`
    *   **目的**: 處理身為 Manager 的自動化任務，包含：清理無效房間與保持房間存活。
    *   **觸發時機**: 在 `_listenToRooms` 的 `listen` 回調中調用。
    *   **內部實現**:
        1.  遍歷 `rooms`，找出所有由 `currentUserId` 管理的房間。
        2.  **自動刪除**: 如果房間的 `updatedAt` 時間戳距今已超過 `_aliveTime`，調用 `deleteRoom(roomId: room.roomId)`。
        3.  **自動續期 (Keep-alive)**: 如果房間即將過期 (例如，超過 `_aliveTime` 的 80% 時間)，則調용 `updateRoom(roomId: room.roomId, data: {})` 來更新 `updatedAt` 時間戳。

*   **修改 `_listenToRooms` 方法**:
    *   在 `listen` 回調的 `_roomsController.add(rooms)` 之後，調用 `_performManagerDuties(rooms)`。

#### 2.3. 過濾無效房間

*   **修改 `matchRoom` 方法**:
    *   在 `querySnapshot.docs.where(...)` 的過濾邏輯中，增加一個條件：`DateTime.now().difference(room.updatedAt.toDate()) <= _aliveTime`，確保只匹配依然活躍的房間。

### 3. 新功能：強化 Manager 請求處理

*   **修改 `_managerRequestHandler` 方法**:
    *   擴展其職責，使其可以處理 `join`、`leave` 和 `alive` 三種類型的請求。
    *   **內部實現**:
        1.  過濾出 `action == 'join'` 的請求，遍歷並調用 `_approveJoinRequest`。
        2.  過濾出 `action == 'leave'` 的請求，遍歷並調用 `_handleLeaveRequest`。
        3.  過濾出 `action == 'alive'` 的請求，遍歷並直接調用 `deleteRequest` 將其清除。

*   **新增 Private 方法**: `Future<void> _handleLeaveRequest(RoomRequest request, Room room)`
    *   **目的**: 處理單一的離開請求。
    *   **內部實現**:
        1.  調用 `updateRoom`，使用 `FieldValue.arrayRemove` 同時從 `participants` 和 `seats` 陣列中移除該 `participantId`。
        2.  調用 `deleteRequest` 刪除已處理的請求。

### 4. 新功能：提升使用者體驗與系統穩健性

*   **修改 `_approveJoinRequest` 方法**:
    *   **目的**: 增加請求被拒絕時的回饋。
    *   **內部實現**:
        1.  當因房間已滿而無法加入時，在 `return` 之前，調用 `sendResponse` 向請求者發送一個拒絕回覆，例如 `body: {'status': 'denied', 'reason': 'room_full'}`。
        2.  發送回覆後，仍需調用 `deleteRequest` 將原請求刪除。

*   **[補充強化項目] 使用 Transaction 處理競態條件**:
    *   **問題分析**: `_approveJoinRequest` 和 `_handleLeaveRequest` 都包含「讀取-修改-寫入」的操作流程。如果在高併發場景下 (例如，房主同時批准兩人，或一人加入一人離開)，可能因競態條件 (Race Condition) 導致數據不一致 (如參與者計數錯誤)。
    *   **強化方案**:
        1.  重構 `_approveJoinRequest` 與 `_handleLeaveRequest` 方法，將其核心邏輯放入 `FirebaseFirestore.instance.runTransaction` 中執行。
        2.  在 Transaction 內部，需重新讀取房間的最新狀態，進行判斷與修改，然後一次性地更新房間數據和刪除請求，確保操作的原子性。

### 5. 設計決策 (Design Decisions)

#### 5.1. 為何選擇 Transaction 而非客戶端佇列 (Client-Side Queue)

*   **問題背景**: 為了解決高併發下「讀-改-寫」操作可能引發的競態條件，我們曾探討過使用客戶端 `MessageQueue` 將操作序列化的方案。
*   **分析與決策**:
    1.  **無法根治問題**: 客戶端佇列僅能序列化單一客戶端的請求，但無法阻止多個客戶端之間的伺服器端衝突，治標不治本。
    2.  **實作脆弱**: 依賴監聽 Firestore 回傳的「訊號」來觸發下一個操作，此機制在真實網路環境下極不可靠，容易造成佇列永久阻塞。
    3.  **效能不佳**: 強制序列化會阻塞後續操作，導致 UI 反應延遲，影響使用者體驗。
    4.  **正確的方案**: **Firestore Transaction** 是為了解決此問題而生的標準方案。它將整個「讀-改-寫」流程移至伺服器端作為一個原子操作執行，內建衝突檢測與自動重試機制，能從根本上保證資料的一致性，且實作更為簡潔、穩健。
*   **最終結論**: 團隊決定不採用客戶端佇列方案，而是堅持並擴展對 **Firestore Transaction** 的使用，作為解決競態條件的核心策略。

### 6. 未來建議 (Future Recommendation)

*   **更可靠的房間清理機制**:
    *   **問題**: 目前的自動刪除邏輯依賴於 Manager 的客戶端 App 必須在線。如果 Manager 關閉應用，過期的房間將無法被清理。
    *   **建議**: 長遠來看，應考慮使用 **Cloud Functions for Firebase** 建立一個定時任務 (例如，每小時執行一次)，從伺服器端查詢並刪除所有過期的房間。這是更穩定且可靠的最終解決方案。
