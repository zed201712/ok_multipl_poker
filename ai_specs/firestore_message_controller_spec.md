## AI 專案任務指示文件：建立 Firestore Message Controller

### **文件標頭 (Metadata)**

| 區塊 | 內容 | 目的/對 AI 的意義 |
| :--- | :--- | :--- |
| **任務 ID (Task ID)** | `FEAT-CTRL-MSG-001` | 方便追蹤和版本控制。 |
| **創建日期 (Date)** | `2025/11/29` | - |
| **目標版本 (Target Version)** | `N/A` | 新增核心功能元件。 |
| **專案名稱 (Project)** | `ok_multipl_poker` | - |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

建立一個名為 `FirestoreMessageController` 的 Dart class，仿照現有的 `FirestoreController` 架構，專門負責處理與 Firestore 之間的 `Message` 物件的即時同步與傳送。

#### **1.2 詳細需求 (Detailed Requirements)**

*   **檔案建立:** 在 `lib/multiplayer/` 路徑下建立一個名為 `firestore_message_controller.dart` 的新檔案。
*   **Class 定義:** 建立一個名為 `FirestoreMessageController` 的 Dart class。
*   **建構子 (Constructor):** 
    *   `FirestoreMessageController` 的建構子需要接收 `FirebaseFirestore` 的實例和一個 `roomId` 字串。
    *   `FirestoreMessageController({required this.instance, required this.roomId});`
*   **Firestore 路徑:** 
    *   Controller 內部應根據傳入的 `roomId`，建立一個指向特定比賽房間訊息集合的 `CollectionReference`。
    *   路徑應為：`matches/{roomId}/messages`。
    *   使用 `withConverter` 將此 `CollectionReference` 轉換為 `CollectionReference<Message>`，並提供 `Message.fromJson` 和 `Message.toJson` 作為轉換函式。
*   **訊息接收 (Stream):**
    *   Controller 內部應使用 `StreamSubscription` 來監聽上述 `CollectionReference` 的 `snapshots()`。
    *   它應公開 (expose) 一個 `Stream<List<Message>>`，讓外部（例如 UI 層）可以訂閱，以接收即時的訊息列表。
*   **訊息發送 (sendMessage):**
    *   提供一個公開的 `Future<void> sendMessage(Message message)` 方法。
    *   此方法會將傳入的 `Message` 物件新增 (add) 到 Firestore 的訊息集合中。
    *   此方法應包含錯誤處理機制 (try-catch)。
*   **資源管理 (dispose):**
    *   提供一個 `dispose()` 方法，用來取消內部的 `StreamSubscription`，以避免記憶體洩漏。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **新增:** `lib/multiplayer/firestore_message_controller.dart`
*   **參考:** `lib/multiplayer/firestore_controller.dart` (需仿照其非同步處理、Stream 訂閱和 `dispose` 的模式)。
*   **參考:** `lib/entities/message.dart` (將使用此 data class 進行 `withConverter` 的型別轉換)。

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **語言：** Dart
*   **框架：** Flutter
*   **後端互動:** Cloud Firestore (`cloud_firestore` package)。
*   **日誌:** 使用 `logging` package 記錄重要的操作或錯誤，與 `FirestoreController` 風格保持一致。
*   **慣例：** 遵循 `effective_dart` 程式碼風格，類別和方法應加上適當的 DartDoc 註解。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)**

1.  **執行計劃：** 簡要說明將建立 `lib/multiplayer/firestore_message_controller.dart` 檔案，並實作規格中定義的各個部分。
2.  **程式碼輸出：** 提供新檔案 `lib/multiplayer/firestore_message_controller.dart` 的完整內容。

#### **3.2 驗證步驟 (Verification Steps)**

1.  確認 `lib/multiplayer/firestore_message_controller.dart` 檔案被成功建立。
2.  檔案內容符合 Dart 語法，且沒有分析錯誤 (Analyzer errors)。
3.  `sendMessage` 方法能夠將一個 `Message` 物件序列化並寫入 Firestore。
4.  Controller 能夠監聽 Firestore 集合的變更，並將其反序列化為 `Message` 物件列表，再透過公開的 Stream 發送出來。
5.  呼叫 `dispose()` 方法後，Firestore 的監聽應被取消。

---

### **Section 4: 上一輪回饋 (Previous Iteration Feedback)**

* **說明：** 這是迭代修改，sendMessage, 需要加上createAt的處理, 像iOS中加上FieldValue.serverTimestamp(), 要求填入serverTimestamp
