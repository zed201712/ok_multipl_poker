## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                |
| :--- |:----------------------------------|
| **任務 ID (Task ID)** | `FEAT-DEMO-ROOM-STATE-WIDGET-003` |
| **創建日期 (Date)** | `2025/12/05`                      |
| **目標版本 (Target Version)** | `N/A`                             |
| **專案名稱 (Project)** | `ok_multipl_poker`                |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 加強 `demo_room_state_widget.dart` 的功能。在管理者（Manager）成功建立一個新房間後，程式應自動將其加入該房間，並監聽與顯示該房間的詳細資訊。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

*   **修改 `lib/demo/demo_room_state_widget.dart`：**
    1.  **自動加入房間：**
        *   在 `_createRoom` 函式中，當 `_roomController.createRoom()` 成功返回新房間的 `roomId` 後，應立即讓管理者自動加入該房間。
    2.  **顯示房間詳情：**
        *   成功加入房間後，UI 應自動切換，開始監聽並顯示該房間的詳細狀態，例如房間 ID、標題、成員列表等。
        *   這將需要一個新的 Widget 或更新現有狀態來展示房間詳情，類似於一個已加入房間的普通成員所看到的畫面。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/demo/demo_room_state_widget.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   在 `_DemoRoomStateWidgetState` 中，修改 `_createRoom` 的非同步流程。
*   使用 `setState` 或對應的狀態管理機制來觸發 UI 更新，以顯示房間詳情。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **`lib/demo/demo_room_state_widget.dart` -> `_DemoRoomStateWidgetState`:**
    *   **修改 `_createRoom()` 方法 (示意):**
        ```dart
        Future<void> _createRoom() async {
          // ... (原有的獲取 title 邏輯)
          final String? newRoomId = await _roomController.createRoom(title: title);

          if (newRoomId != null && mounted) {
            // 新增：自動以管理者身份加入房間
            await _roomController.joinRoom(newRoomId, isManager: true);

            // 新增：更新狀態以顯示房間詳情
            setState(() {
              // 假設有一個狀態來追蹤當前房間
              _currentRoomId = newRoomId; 
            });
          }
          // ... (錯誤處理)
        }
        ```
    *   **修改 `build()` 方法：**
        *   根據 `_currentRoomId` 的狀態，條件性地顯示「建立/加入房間」的 UI 或是「房間詳情」的 UI。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

1.  **執行計劃：**
    1.  修改 `lib/demo/demo_room_state_widget.dart` 中的 `_createRoom` 方法，在成功建立房間後，自動將管理者加入該房間。
    2.  更新 `build` 方法，根據當前是否已加入房間，顯示不同的 UI（房間控制台 vs. 房間詳情）。
2.  **程式碼輸出：** 輸出 `demo_room_state_widget.dart` 的 **完整程式碼內容**。

#### **3.2 驗證步驟 (Verification Steps)**

1.  **啟動 Demo Widget**：確認 UI 正常顯示「建立/加入房間」的介面。
2.  **使用者 A (管理者) 建立房間**：
    *   輸入房間標題。
    *   點擊「Create Room」按鈕。
3.  **驗證 UI 轉換**：
    *   確認 UI 自動切換到「房間詳情」畫面，並顯示新房間的 ID、標題及成員列表。
    *   確認成員列表中包含使用者 A，且其身份為管理者。
4.  **功能持續性**：確認房間詳情畫面中的其他互動功能（如果有的話）可以正常運作。
