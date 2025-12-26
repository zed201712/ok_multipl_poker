## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容 |
|:---|:---|
| **任務 ID (Task ID)** | `FEAT-SETTINGS-QRCODE-001` |
| **標題 (Title)** | `ADD QR CODE DISPLAY TO SETTINGS SCREEN` |
| **創建日期 (Date)** | `2025/12/26` |
| **目標版本 (Target Version)** | `N/A` |
| **專案名稱 (Project)** | `ok_multipl_poker` |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

*   **說明：** 在設定畫面 (`SettingsScreen`) 底部新增一個 QR Code 顯示區塊。
*   **目的：**
    1.  **功能擴充 (Feature Expansion)：** 展示整合 `qr_flutter` 套件的能力，用於未來可能的朋友分享或房間加入功能。
    2.  **視覺豐富 (Visual Enrichment)：** 在 QR Code 中央嵌入頭像圖片，增加識別度。

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1.  **位置與佈局**
    *   **位置：** `lib/settings/settings_screen.dart` 的 `ListView` 列表最底部 (在 Back 按鈕之上，但在 Scroll View 內部)。
    *   **間距：** 需與上方元件保持適當距離 (使用 `_gap`)。
    *   **置中：** QR Code 應水平置中顯示。

2.  **QR Code 規格**
    *   **套件：** 使用 `qr_flutter`。
    *   **數據 (Data)：** 固定字串 `"123"`。
    *   **尺寸：** 自適應或固定大小 (例如 200x200)，需確保清晰可見。
    *   **嵌入圖片 (Embedded Image)：**
        *   **圖片來源：** `assets/images/goblin_cards/goblin_1_009.png`。
        *   **尺寸：** 100x100 (顯示尺寸)。
        *   **裁切/縮放：** `BoxFit.cover`。
    *   **樣式：** 建議使用 `QrImageView` widget，並設定 `embeddedImage` 與 `embeddedImageStyle` 屬性。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

*   **修改：** `lib/settings/settings_screen.dart`

#### **2.2 程式碼風格 (Style)**

*   遵循 `Effective Dart`。
*   使用 `QrImageView` (來自 `qr_flutter` 4.0+ 版本)。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  **UI 檢查：** 進入設定頁面，捲動到底部，確認看到 QR Code。
2.  **內容檢查：** 確認 QR Code 中央有顯示指定的 Goblin 圖片。
3.  **掃描測試 (選用)：** 使用手機相機掃描，確認內容為 "123"。

---

### **Section 4: 改善建議與邏輯檢查 (Review & Suggestions)**

#### **4.1 邏輯檢查與建議**

*   **QR Code 錯誤處理：** 若嵌入圖片路徑錯誤，`QrImageView` 可能會拋出異常或顯示空白。確保圖片路徑正確存在於 `pubspec.yaml` 中 (已確認 `assets/images/goblin_cards/` 有宣告)。

#### **4.2 提交訊息 (Commit Message)**

```text
feat: add qr code to settings screen

Task: FEAT-SETTINGS-QRCODE-001

- Added QrImageView to the bottom of SettingsScreen.
- Configure QR code with data "123" and embedded goblin image.
```
