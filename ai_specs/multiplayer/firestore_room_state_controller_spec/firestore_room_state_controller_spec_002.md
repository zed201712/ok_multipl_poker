## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                |
| :--- |:----------------------------------| 
| **任務 ID (Task ID)** | `FEAT-DEMO-ROOM-STATE-WIDGET-002` |
| **創建日期 (Date)** | `2025/12/05`                      |
| **目標版本 (Target Version)** | `N/A`                             |
| **專案名稱 (Project)** | `ok_multipl_poker`                |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 增強 `demo_room_state_widget.dart` 的功能，加入一個可互動的房間列表，讓使用者可以方便地瀏覽、選擇並請求加入現有的房間。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **修改 `demo_room_state_widget.dart`：**
    1.  **新增可點擊的房間列表 Widget：**
        *   在 `DemoRoomStateWidget` 中，建立一個名為 `RoomsListWidget` 的新內部 Widget。
        *   這個 Widget 的 UI 和行為應類似於 `@/lib/demo/demo_room_widget.dart` 中的 `RoomsStreamWidget`。
        *   `RoomsListWidget` 將監聽 `_roomController.roomsStream()` 來顯示所有公開的房間。
        *   列表中的每一個房間項目都應是**可點擊**的。

    2.  **實作點擊互動：**
        *   當使用者點擊 `RoomsListWidget` 中的任一房間時，該房間的 `roomId` 和 `title` 應自動填入對應的 `_roomIdController` 和 `_roomTitleController` 中。

    3.  **整合加入流程：**
        *   保留現有的「Request to Join Room」按鈕。在點擊列表項目填入房間資訊後，使用者可以透過此按鈕發送加入請求。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/demo/demo_room_state_widget.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **UI 風格:** 新增的 `RoomsListWidget` 應使用 `StreamBuilder`、`ListView` 和 `Card` 或 `ListTile`，並透過 `InkWell` 或 `GestureDetector` 來處理點擊事件。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`lib/demo/demo_room_state_widget.dart` -> `RoomsListWidget` (示意):**
    ```dart
    class RoomsListWidget extends StatelessWidget {
      final Stream<List<Room>>? roomsStream;
      final Function(Room room) onRoomTap;

      const RoomsListWidget({Key? key, required this.roomsStream, required this.onRoomTap}) : super(key: key);

      @override
      Widget build(BuildContext context) {
        // ... StreamBuilder logic ...
        // ListView.builder -> ListTile with onTap -> onRoomTap(room)
      }
    }
    ```

*   **`lib/demo/demo_room_state_widget.dart` -> `_DemoRoomStateWidgetState`:**
    *   在 `build` 方法中，將 `RoomsListWidget` 加入到 UI 佈局中。
    *   實作一個 `_handleRoomTap(Room room)` 方法，用來更新 `_roomIdController` 和 `_roomTitleController` 的文本。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  修改 `lib/demo/demo_room_state_widget.dart`，加入新的 `RoomsListWidget`。
    2.  在 `_DemoRoomStateWidgetState` 中整合 `RoomsListWidget` 的點擊事件處理。
2.  **程式碼輸出：** 輸出 `demo_room_state_widget.dart` 的 **完整程式碼內容**。

#### **3.2 驗證步驟 (Verification Steps)**

1.  **啟動 Demo Widget**：確認 UI 正常顯示，並出現一個「All Rooms (Live)」的區塊。
2.  **使用者 A 建立房間**：確認由使用者 A 建立的新房間出現在「All Rooms (Live)」列表中。
3.  **使用者 B 點擊房間**：
    *   在另一裝置或模擬器上，點擊列表中的房間項目。
    *   確認上方的「Room ID」和「Room Title」輸入框已自動填入正確的資訊。
4.  **使用者 B 請求加入**：
    *   點擊「Request to Join Room」按鈕。
    *   確認加入請求的流程（發送請求 -> 管理員核准）與之前一致且能正常運作。
```