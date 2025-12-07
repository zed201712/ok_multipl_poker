| **任務 ID (Task ID)** | `FEAT-ROOM-STATE-CONTROLLER-010` |
| **創建日期 (Date)** | `2025/12/07` |

### 1. 目的 (Objective)

本文件旨在規劃一個穩健的房主（Manager）移交與接管機制。目標是實現兩種場景下的房主變更，確保在任何情況下房間都能保持活性：
1.  **主動移交**：允許現任房主在離開或暫停應用時，平滑地將管理權交給下一位玩家。
2.  **被動接管**：當現任房主因斷線或長時間無響應（AFK）而失聯時，允許房間內的其他玩家根據預設順序，自動、有序地接管房主身份。

### 2. 新增 Private Property

*   在 `FirestoreRoomStateController` 中新增一個 `static const`，定義在房主失聯後，各個玩家嘗試接管的間隔時間。
    ```dart
    // Grace period between each participant's attempt to take over the manager role.
    static const Duration _managerTakeoverTimeout = Duration(seconds: 3);
    ```

### 3. 新功能：主動移交管理權

*   **新增 Public 方法**: `Future<void> handoverRoomManager({required String roomId})`
    *   **目的**: 允許現任房主主動、優雅地將管理權移交給房間內的下一位玩家。
    *   **前置條件**:
        1.  此方法必須由當前的 `managerUid` 調用。
        2.  房間內必須有至少兩位參與者。
    *   **內部實現 (使用 Transaction)**:
        1.  使用 `FirebaseFirestore.instance.runTransaction` 來保證操作的原子性。
        2.  在 Transaction 中，重新讀取房間的最新狀態。
        3.  **驗證身份**: 確認調用者 `currentUserId` 仍然是該房間的 `managerUid`。
        4.  **尋找繼任者**: 從 `participants` 列表中，找出第一位不是現任房主的玩家作為繼任者。
        5.  如果找不到繼任者（例如房間只剩自己），則中止操作。
        6.  **更新房主**: 調用 `transaction.update`，將 `managerUid` 欄位更新為繼任者的 ID，並同時更新 `updatedAt` 時間戳。

### 4. 新功能：被動、有序地接管管理權

此功能將整合到一個新的處理邏輯中，該邏輯會在每次房間狀態更新時，為**所有非房主**的玩家執行。

*   **新增 Private 方法**: `void _handleManagerTakeover(Room room)`
    *   **目的**: 作為非房主玩家，持續監測房主狀態，並在房主失聯時，根據順位在特定時間點嘗試接管。
    *   **觸發時機**: 在 `setRoomId` 的 `_roomStateSubscription.listen` 回調中，為每個玩家調用此方法。
    *   **不執行接管邏輯的條件 (Pre-conditions)**:
        1.  如果我自己 (`currentUserId`) 就是房主，則直接返回。
        2.  如果房間 `updatedAt` 所標記的時間戳仍在 `_aliveTime` 有效期內，表示房主依然活躍，直接返回。
        3.  如果房間參與者少於兩人，則直接返回。
    *   **核心接管邏輯**:
        1.  **計算我的順位**: 建立一個不包含現任房主的「繼任者列表」，然後在這個列表中找到我自己 (`currentUserId`) 的索引（`mySuccessorRank`）。如果找不到（`rank < 0`），則返回。
        2.  **計算我的行動時間**: 根據我的順位，計算出我應該嘗試接管的總延遲時間：`takeoverDelay = _aliveTime + (_managerTakeoverTimeout * mySuccessorRank)`。
        3.  **判斷是否輪到我**: 比較「房間已失聯時間」（`now - room.updatedAt`）與我的「行動時間」。如果前者大於等於後者，則代表輪到我嘗試接管。
        4.  **發起接管**: 調用新增的 `_attemptToBecomeManager(room)` 方法，發起接管操作。

*   **新增 Private 方法**: `Future<void> _attemptToBecomeManager(Room room)`
    *   **目的**: 執行一個帶有條件檢查的、原子性的「奪權」操作。
    *   **內部實現 (使用 Transaction)**:
        1.  使用 `FirebaseFirestore.instance.runTransaction`。
        2.  在 Transaction 中，重新讀取房間的最新狀態。
        3.  **最關鍵的檢查 (CRITICAL CHECK)**: **驗證 `managerUid` 是否仍是我們預期要替換的那個失聯的房主** (`transaction_room.managerUid == room.managerUid`)。
        4.  **如果檢查通過**: 表示我是第一個成功執行此操作的人。調用 `transaction.update`，將 `managerUid` 更新為我自己的 `currentUserId`，並更新 `updatedAt` 時間戳。
        5.  **如果檢查失敗**: 表示在我之前，已經有另一位順位更靠前的玩家成功接管了。此時應**安靜地中止操作**，不做任何事。Transaction 會自動結束，等待下一次的房間狀態更新即可。

*   **修改 `setRoomId` 方法**:
    *   在 `_roomStateSubscription.listen` 的回調中，除了原有的 `_managerRequestHandler`，新增對 `_handleManagerTakeover(room)` 的調用。
    ```dart
    _roomStateSubscription = combinedStream.listen((roomState) {
      _roomStateController.add(roomState); 

      // 房主專屬：處理加入、離開等請求
      _managerRequestHandler(roomState); 
      
      // 所有玩家（特別是非房主）執行：監測並在需要時觸發接管邏輯
      if (roomState.room != null) {
        _handleManagerTakeover(roomState.room!); 
      }
    });
    ```

### 5. 邏輯檢查與補充說明

*   **核心風險與對策**: 您設計的「按順位延時」機制，極大地降低了多位玩家同時搶奪管理權的機率。但為了根除在延時間隔內仍可能發生的網路延遲、時鐘不準等問題所引發的競態條件，**`_attemptToBecomeManager` 中的 Transaction 和條件檢查是不可或缺的**。它確保了最終只會有一個玩家成功接管。
*   **列表順序的依賴性**: 該機制的順序依賴於 Firestore 中 `participants` 陣列的順序。此順序由房主在同意加入或處理離開請求時管理，通常是穩定的，但此設計決策應被知曉。