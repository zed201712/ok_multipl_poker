## AI 專案任務指示文件（高標準模板）

### **文件標頭 (Metadata)**

| 區塊 | 內容                    | 目的/對 AI 的意義 |
| :--- |:----------------------| :--- |
| **任務 ID (Task ID)** | `FEAT-DEMO-ROOM-SCREEN-001` | 方便追蹤和版本控制。AI 在回覆時應引用此 ID。 |
| **創建日期 (Date)** | `2025/12/02`          | - |
| **目標版本 (Target Version)** | `N/A`                 | 讓 AI 了解這次修改的專案範圍。 |
| **專案名稱 (Project)** | `ok_multipl_poker`    | - |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

這是告訴 AI **「要做什麼」**。

#### **1.1 任務目標 (Goal)** **【必填】**

* **說明：** 分析現有的 `/lib/play_session/RoomDemoScreen.dart` 檔案，並依據其內容產生一份符合 `ai_dev_spec_template.md` 風格的技術規格文件。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

* **說明：** 本文件旨在記錄 `RoomDemoScreen.dart` 的現有功能與架構。
* **功能：**
    *   **匿名認證：** 進入畫面時，若使用者未登入，則自動執行 Firebase 匿名登入以獲取 `userId`。
    *   **房間建立 (`_createRoom`)：**
        *   使用者可透過 UI 輸入房間標題、人數上限等資訊。
        *   點擊按鈕後，會在 Firestore 的 `rooms` collection 中建立一個新 document。
        *   房間 ID (`roomId`) 若未填寫，則由 Firestore 自動生成。
    *   **加入房間 (`_joinRoom`)：**
        *   使用者可在指定 `roomId` 的情況下，將自己的資訊（如 `status`）寫入 `rooms/{roomId}/participants/{userId}` 的 document 中。
    *   **實時數據顯示：**
        *   `RoomsStreamWidget`: 實時監聽並顯示 `rooms` collection 中的所有房間列表。
        *   `ParticipantStreamWidget`: 實時監聽並顯示目前使用者在特定房間內的 `participant` 文件內容。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

這是告訴 AI **「如何去做」**，以及**「在哪裡做」**。

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

* **說明：** 此任務是分析和文件化，而非修改。
* **分析對象：** `/lib/play_session/RoomDemoScreen.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

* **說明：** 描述 `RoomDemoScreen.dart` 中使用的技術。
* **語言：** Dart
* **框架：** Flutter
* **後端與資料庫：** Firebase (Authentication, Cloud Firestore)
* **架構：**
    *   使用 `StatefulWidget` 管理頁面狀態。
    *   直接在 Widget State 中呼叫 Firebase SDK 進行資料操作。
    *   透過 `StreamBuilder` 來處理來自 Firestore 的實時數據流，並更新 UI。
* **慣例：**
    *   UI 元件和業務 logique 混合在同一個檔案中。
    *   將實時監聽的列表（`RoomsStreamWidget`）和單一文件（`ParticipantStreamWidget`）拆分成獨立的子 Widget。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

* **說明：** 列出檔案中的主要函式和 Widget。
* **`_RoomDemoWidgetState` 主要函式：**
    *   `_initUser()`: `Future<void>` - 初始化 Firebase 使用者。
    *   `_createRoom()`: `Future<void>` - 處理建立房間的邏輯。
    *   `_joinRoom()`: `Future<void>` - 處理加入房間的邏輯。
* **主要 Widgets:**
    *   `RoomDemoScreen`: `StatelessWidget` - 頁面的進入點，包含 AppBar 和主體。
    *   `RoomDemoWidget`: `StatefulWidget` - 包含所有互動 UI 和狀態管理。
    *   `RoomsStreamWidget`: `StatelessWidget` - 接收 `FirebaseFirestore` 實例，顯示所有房間。
    *   `ParticipantStreamWidget`: `StatelessWidget` - 接收 `firestore`, `roomId`, `userId`，顯示特定參與者資訊。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

這是告訴 AI **「要如何回覆」**，以方便您審核。

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

* **說明：** AI 應根據本分析，產生一份新的 `.md` 文件。
* **執行計劃：**
    1.  讀取 `/lib/play_session/RoomDemoScreen.dart` 的內容。
    2.  分析其架構、功能和使用的技術。
    3.  依照 `ai_dev_spec_template.md` 的格式，填寫以上分析結果。
    4.  將最終的 Markdown 內容寫入到 `ai_specs/room_demo_screen_spec.md`。

#### **3.2 驗證步驟 (Verification Steps)**

* **說明**：描述如何驗證 `RoomDemoScreen.dart` 的功能是否正常運作。
    1.  啟動應用程式，導航至 `RoomDemoScreen`。
    2.  確認畫面下方顯示 "目前 userId" 且有值。
    3.  在 "房間名稱" 等欄位填入測試資料，點擊「建立房間」。
    4.  驗證下方 "所有 rooms (實時)" 區塊中出現剛剛建立的房間，且資料正確。
    5.  複製新房間的 `roomId` 到最上方的 "Room ID" 輸入框。
    6.  點擊「加入房間 / 更新 participant」。
    7.  驗證下方 "目前 participant doc (實時)" 區塊顯示對應的 participant 資料。

---

### **Section 4: 上一輪回饋 (Previous Iteration Feedback) (可選)**

* **說明：** N/A. 此為首次文件生成任務。