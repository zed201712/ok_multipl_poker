## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-ROOM-STATE-CONTROLLER-014` |
| **標題 (Title)** | `END ROOM LOGIC & REQUEST HANDLING` |
| **創建日期 (Date)** | `2026/01/06` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 分析 Commit `b578678` 引入的 "End Room" (結束房間) 邏輯。該功能旨在允許使用者主動結束並刪除房間，或在滿足特定條件下發送請求通知其他玩家。同時，檢視與修復可能的邏輯漏洞，確保 `end_room` 行為的安全性與一致性。
*   **目的：**
    1.  **邏輯正確性 (Correctness)：** 確保 `endRoom` 在單人與多人情境下均能正確運作。單人時直接刪除房間，多人時發送 `end_room` 請求。
    2.  **安全性 (Safety)：** 驗證 `endRoom` 操作是否依賴正確的 Room ID 與使用者權限。防止因直接調用 `deleteRoom` 而繞過必要的清理步驟（若有）。
    3.  **UI/UX 整合 (Integration)：** 確認 `BigTwoBoardWidget` 中的 "Leave" 按鈕行為從單純的 `leaveRoom` 變更為 `endRoom` 是否符合預期（這會強制解散房間，而非僅讓玩家離開）。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **分析 Commit `b578678` 的變更**
    *   **`FirestoreRoomStateController.endRoom`**:
        *   檢查當前使用者是否已認證。
        *   檢查房間是否存在。
        *   **邏輯分支：**
            *   若房間內有**其他**參與者 (`otherParticipants.isNotEmpty`)，則發送 `end_room` 請求 (`action: 'end_room'`)。
            *   若房間內**無**其他參與者 (僅剩自己)，則直接呼叫 `deleteRoom(roomId: roomId)`。
    *   **`FirestoreTurnBasedGameController.endRoom`**:
        *   作為 `FirestoreRoomStateController` 的轉發層，處理 `roomId` 的獲取與錯誤捕獲。
    *   **`BigTwoBoardWidget`**:
        *   將 `_leaveButton` 的行為由 `leaveRoom` 改為 `endRoom`。
        *   修正 `ChangeNotifierProvider` 為 `.value` 建構子，解決 `CardPlayer` 雙重 Dispose 的問題 (此部分已在 `FEAT-BIG-TWO-Board-Card_Area-001` 或相關修復中提及，但包含在此 Commit 中)。

2.  **邏輯審查與潛在問題 (Logic Check & Issues)**
    *   **Leave vs End Room:** 將按鈕行為改為 `endRoom` 意味著任何玩家按下 "Leave" 都會試圖**銷毀**整個房間（或發送銷毀請求）。這與傳統的 "離開遊戲" (Leave) 不同。若意圖是 "解散房間" (Disband)，則命名正確；若只是 "退出"，則邏輯有誤。
        *   *假設：* 根據 Commit 內容，意圖似乎是讓當前實作的 "Leave" 按鈕具備 "結束房間" 的能力，或者這是測試階段的權宜之計。**改善建議：** 應區分 "Leave" (僅自己退出) 與 "Disband/End" (結束遊戲)。但在本 Spec 範圍內，我們先確保 `endRoom` 的實作邏輯本身是健壯的。
    *   **`end_room` Request Handling:** `FirestoreRoomStateController` 需要有對應的 `_managerRequestHandler` 來處理 `action: 'end_room'`。Commit `b578678` 僅新增了發送端的 `endRoom` 方法，**未見 `end_room` 請求的接收端處理邏輯** (即 `_managerRequestHandler` 中對 `end_room` 的 switch case)。這是一個潛在的邏輯斷裂。
        *   *修正需求：* 必須在 `FirestoreRoomStateController` 的 `_managerRequestHandler` 中實作 `end_room` 的處理：收到此請求後，應執行 `deleteRoom` 或通知所有玩家房間已結束。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **Controller:** `lib/multiplayer/firestore_room_state_controller.dart`
*   **Controller:** `lib/multiplayer/firestore_turn_based_game_controller.dart`
*   **UI:** `lib/play_session/big_two_board_widget.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `effective_dart`。

---

### **Section 3: 改善建議與邏輯檢查 (Improvement & Logic Check)**

#### **3.1 邏輯錯誤分析**
*   **嚴重遺漏：** `FirestoreRoomStateController` 發送了 `action: 'end_room'`，但在同檔案的 `_managerRequestHandler` (或相關處理函式) 中，**很可能**尚未實作對應的處理邏輯。這會導致請求堆積在 Firestore 中而無任何反應。
*   **UI 行為變更：** `BigTwoBoardWidget` 的 `leave` 按鈕現在會呼叫 `endRoom`。若房間有多人，它會發送請求；若單人，它會刪除房間。使用者體驗上，這是一個 "強制結束" 的操作。

#### **3.2 具體改善計畫**
1.  **實作 Request Handler:** 在 `FirestoreRoomStateController` 的 `_managerRequestHandler` 內新增 `case 'end_room':`，執行 `deleteRoom(request.roomId)`。
2.  **完善 `endRoom` 方法:** 確保發送請求前有適當的 Log 或防呆。

---

### **Section 4: 產出 Commit Message**

```text
feat(room): implement endRoom logic and fix CardPlayer provider disposal

- Controller: Added `endRoom` method to `FirestoreRoomStateController` and `FirestoreBigTwoController`.
- Controller: Implemented logic to delete room directly if single player, or send `end_room` request if multiplayer.
- UI: Updated `BigTwoBoardWidget` leave button to use `endRoom`.
- Fix: Fixed `CardPlayer` double disposal issue by using `ChangeNotifierProvider.value`.
- Note: Requires implementation of 'end_room' handler in `_managerRequestHandler` to fully function.
```
