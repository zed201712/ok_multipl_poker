| **任務 ID (Task ID)** | `FEAT-MOCK-ROOM-STATE-CONTROLLER-002` |
| **創建日期 (Date)** | `2025/12/11`                          |
| **目標版本 (Target Version)** | `N/A`                                 |
| **專案名稱 (Project)** | `ok_multipl_poker`                    |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 根據 `FEAT-MOCK-ROOM-STATE-CONTROLLER-001` 已建立的 `MockFirestoreRoomStateController`，接續完成其中被標記為 `// TODO: implement` 的方法。實作應參考現有的 `leaveRoom` 方法，以確保 Mock Controller 行為的一致性與合理性。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **完成 `handoverRoomManager`:**
    *   當被呼叫時，此方法應將房間管理員（`managerUid`）轉交給房間內除了現任管理員之外的另一位參與者。
    *   如果房間內沒有其他參與者可供轉交，則應將該房間刪除，這與 `leaveRoom` 在管理員是最後一個參與者時的行為一致。
    *   更新後，應觸發 `_roomsController` 和 `_roomStateController` 的更新。

*   **完成 `matchRoom`:**
    *   此方法應模擬尋找並加入一個符合條件的公開房間。
    *   應搜尋一個 `state` 為 `open`、`visibility` 為 `public`、且參與人數未滿的房間。
    *   如果找到符合條件的房間，目前的使用者應加入該房間的 `participants` 和 `seats` 列表。
    *   如果找不到，則應呼叫 `createRoom` 建立一個新的公開房間。
    *   返回找到或建立的房間 ID。

*   **完成 `requestToJoinRoom`:**
    *   此方法應模擬使用者請求加入一個（通常是私人的）房間。
    *   應呼叫 `sendRequest` 方法，並在 body 中包含一個 `action: 'request_to_join'` 的標記。

*   **完成 `sendAlivePing`:**
    *   此方法模擬客戶端發送心跳以表示活躍狀態。
    *   在 Mock 環境中，這可以透過更新房間的 `updatedAt` 時間戳來模擬。
    *   如果找不到房間，應靜默處理而不是拋出錯誤，因為 Ping 可能會在房間剛被刪除時發送。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/multiplayer/mock_firestore_room_state_controller.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **一致性：** 實作邏輯需參考 `leaveRoom` 方法，確保 Mock 行為的合理性。例如，當操作影響到房間狀態時，需手動觸發 `_roomsController` 和 `_roomStateController` 的 `add` 事件。
*   **非同步處理：** 所有返回 `Future` 的方法都應使用 `async` 標記。
*   **Null Safety:** 確保程式碼符合 Dart 的空安全規則。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  讀取 `lib/multiplayer/mock_firestore_room_state_controller.dart` 的內容。
    2.  將 `handoverRoomManager`, `matchRoom`, `requestToJoinRoom`, `sendAlivePing` 四個方法中的 `UnimplementedError` 替換為完整的 Mock 實作。
    3.  將更新後的完整程式碼寫回 `lib/multiplayer/mock_firestore_room_state_controller.dart`。

2.  **程式碼輸出：**
    *   輸出修改後 `lib/multiplayer/mock_firestore_room_state_controller.dart` 的完整程式碼。

#### **3.2 驗證步驟 (Verification Steps)**

*   **靜態分析：** 在修改後，執行 `analyze_current_file` 工具，確保沒有任何錯誤或警告。
*   **單元測試：** (可選) 執行相關的單元測試，確保所有測試案例都能通過。
