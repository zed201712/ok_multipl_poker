## AI 專案任務指示文件：建立 Message 實體

### **文件標頭 (Metadata)**

| 區塊 | 內容 | 目的/對 AI 的意義 |
| :--- | :--- | :--- |
| **任務 ID (Task ID)** | `FEAT-ENTITIES-001` | 方便追蹤和版本控制。 |
| **創建日期 (Date)** | `2025/11/29` | - |
| **目標版本 (Target Version)** | `N/A` | 新增核心功能元件。 |
| **專案名稱 (Project)** | `ok_multipl_poker` | - |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

在 `lib/entities/` 路徑下建立一個名為 `Message.dart` 的新檔案，用以定義一個 `Message` data class，此 class 將用於應用程式中的訊息傳遞，特別是與 Firestore 的互動。

#### **1.2 詳細需求 (Detailed Requirements)**

*   **檔案建立:** 建立 `lib/entities/Message.dart`。
*   **Class 定義:** 建立一個名為 `Message` 的 Dart class。
*   **序列化:** 
    *   使用 `json_annotation` (`@JsonSerializable()`) 來使其能夠被 `json_serializable` 套件處理。
    *   包含 `part 'Message.g.dart';` 指令。
    *   實現 `Message.fromJson()` factory 和 `toJson()` 方法，引用自動產生的 `_$MessageFromJson` 和 `_$MessageToJson` 函式。
*   **欄位翻譯:** 根據提供的 Swift struct 將欄位轉換為 Dart class 的屬性：
    *   `id`: `String` (應在建構子中處理，若未提供則自動生成一個 UUID)。
    *   `systemText`: `String?` (可選)。
    *   `uid`: `String` (訊息發送者的 User ID)。
    *   `targetUid`: `String?` (指定接收者的 User ID，可選)。
    *   `displayName`: `String` (發送者的顯示名稱)。
    *   `createdAt`: `DateTime?` (訊息建立時間，需能和 Firestore 的 `Timestamp` 正確轉換)。
    *   `roomId`: `String` (訊息所在的房間 ID)。
*   **特殊欄位處理:**
    *   **`data` 欄位:** 暫時**忽略**此欄位。Swift 的 `Data` 型別對應到 Dart 的 `Uint8List`，在 `json_serializable` 中需要額外的轉換器，待需求明確後再加入。
    *   **`id` 欄位:** 建構子應允許傳入 `id`，如果 `id` 為 null，則使用 `uuid` 套件自動產生一個 v4 的 UUID 字串。
    *   **`createdAt` 欄位:** 需能處理與 Firestore `Timestamp` 之間的轉換。
*   **靜態屬性:** 提供一個 `static final Message empty` 實例，用於表示一個空的或預設的訊息物件。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **新增:** `lib/entities/Message.dart`

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **語言：** Dart
*   **框架：** Flutter
*   **序列化：** `json_serializable`, `json_annotation`。
*   **UUID 生成：** `uuid` 套件。
*   **後端互動:** Cloud Firestore (需引入 `cloud_firestore` 以使用 `Timestamp` 型別)。
*   **慣例：** 遵循 `effective_dart` 程式碼風格，並參考 `lib/entities/User.dart` 的現有實作模式。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

*   **Class Constructor:** 
    `Message({String? id, this.systemText, required this.uid, this.targetUid, required this.displayName, this.createdAt, required this.roomId})`
*   **JSON 工廠:**
    `factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);`
*   **JSON 方法:**
    `Map<String, dynamic> toJson() => _$MessageToJson(this);`

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)**

1.  **執行計劃：** 簡要說明將建立 `lib/entities/Message.dart` 檔案。
2.  **程式碼輸出：** 提供新檔案 `lib/entities/Message.dart` 的完整內容。

#### **3.2 驗證步驟 (Verification Steps)**

1.  確認 `lib/entities/Message.dart` 檔案被成功建立。
2.  檔案內容符合 Dart 語法，且沒有分析錯誤 (Analyzer errors)。
3.  在專案根目錄執行 `flutter pub run build_runner build --delete-conflicting-outputs` 能夠成功產生 `lib/entities/Message.g.dart` 檔案，且沒有錯誤。

---
