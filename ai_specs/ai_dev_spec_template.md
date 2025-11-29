## AI 專案任務指示文件（高標準模板）

### **文件標頭 (Metadata)**

| 區塊 | 內容 | 目的/對 AI 的意義 |
| :--- | :--- | :--- |
| **任務 ID (Task ID)** | `FEAT-20251129-001` | 方便追蹤和版本控制。AI 在回覆時應引用此 ID。 |
| **創建日期 (Date)** | `2025/11/29` | - |
| **目標版本 (Target Version)** | `V1.5.0 Beta` | 讓 AI 了解這次修改的專案範圍。 |
| **專案名稱 (Project)** | `MyApp iOS/Android` | - |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

這是告訴 AI **「要做什麼」**。

#### **1.1 任務目標 (Goal)** **【必填】**

* **說明：** 用一句話概括本次工作的最終結果。
* **範例：** *「在使用者登出後，清除本地儲存的快取資料，並導航回歡迎畫面。」*

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

* **說明：** 列點說明具體的功能行為和邏輯。這是 AI 撰寫程式碼的主要依據。
* **範例：**
    * **邏輯：** 當 `logout()` 函式成功執行後，需依序呼叫 `clearKeychain()` 和 `clearUserDefaults()`。
    * **資料：** 必須清除 **KeyChain** 中儲存的 `auth_token` 和 **UserDefaults** 中的 `user_settings`。
    * **互動 (UI/UX)：** 清除完成後，必須使用 **`RootCoordinator`** 的 **`resetToWelcome()`** 函式，切換 App 的根視圖。
    * **錯誤處理：** 如果 `clearKeychain()` 失敗，必須將錯誤記錄到 `Logger.shared`，但**不應阻擋**後續的 `clearUserDefaults()` 和 UI 導航。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

這是告訴 AI **「如何去做」**，以及**「在哪裡做」**。

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

* **說明：** 精確列出 AI 必須讀取（作為上下文）和修改的檔案路徑。
* **範例：**
    * **修改：** `MyApp/Sources/Services/AuthService.swift`
    * **修改：** `MyApp/Sources/Coordinators/RootCoordinator.swift` (新增 `resetToWelcome` 函式)
    * **參考：** `MyApp/Sources/Utils/KeychainManager.swift` (AI 需參考其中已存在的 `clearKeychain` 簽名)

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

* **說明：** 確保 AI 遵守專案的程式碼慣例。
* **範例：**
    * **語言：** Kotlin (Android)
    * **架構：** MVVM + Coroutines。
    * **慣例：** 必須使用 `val` 宣告不可變 (immutable) 變數，只有狀態變數才使用 `var`。
    * **備註：** 在所有修改的函式頂部，新增一個 `// Modified by AI Task ID: [ID]` 的註解。

#### **2.3 函式簽名或元件使用規範 (Function Signatures/Components)**

* **說明：** 強制 AI 使用指定的 API 介面，避免它發明新的不一致的 API。
* **範例：**
    * `AuthService.swift` 中的 `logout` 函式簽名必須保持為：`func logout() async -> Bool`。
    * UI 導航必須使用現有的 DI 容器提供的 `RootCoordinator` 實例。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

這是告訴 AI **「要如何回覆」**，以方便您審核。

#### **3.1 預期回覆格式 (Expected Output Format)** **【必填】**

* **說明：** 規定 AI 提交成果的方式。
* **範例：**
    1.  **執行計劃：** 列點說明將在 2.1 節提到的檔案中，具體修改/新增哪些程式碼區塊或函式。
    2.  **程式碼輸出：** 輸出每個受影響檔案的**完整修改後內容**。如果修改行數超過 100 行，請改為提供 **Unified Diff** 格式的輸出。

#### **3.2 驗證步驟 (Verification Steps)**

* **說明：** 列出您將如何測試 AI 的修改，讓 AI 在內部「自我驗證」其程式碼。
* **範例：**
    1.  編譯並運行專案，確認無編譯錯誤。
    2.  在模擬器中登入成功。
    3.  點擊「登出」按鈕。
    4.  檢查 KeyChain 是否已清空 (假設您有方法檢查)。
    5.  驗證畫面是否已跳轉到 Welcome 畫面。

---

### **Section 4: 上一輪回饋 (Previous Iteration Feedback) (可選)**

* **說明：** 如果這是迭代修改，記錄上次 AI 的錯誤點和您要求的修正。
* **範例：** *「上次 AI 在 `AuthService` 中忘記將錯誤拋出，導致 UI 層無法捕捉到登入失敗。本次請確保使用 `try throw` 機制。」*

### **總結**

這份模板涵蓋了**目的、範圍、程式碼、約束**和**輸出格式**。當您每次給 AI 一份這樣的文件時，它就能在極少需要澄清的情況下，開始其程式碼生成的工作。