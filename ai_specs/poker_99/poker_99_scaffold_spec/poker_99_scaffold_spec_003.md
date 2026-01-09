## AI 專案任務指示文件 (Feature Task)

| 區塊 | 內容                                          |
|:---|:--------------------------------------------|
| **任務 ID (Task ID)** | `FEAT-POKER-99-UI-003`                      |
| **標題 (Title)** | `REFINE POKER 99 UI & TRANSLATIONS`         |
| **創建日期 (Date)** | `2026/01/10`                                |
| **目標版本 (Target Version)** | `N/A`                                       |
| **專案名稱 (Project)** | `ok_multipl_poker`                          |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

*   **說明：** 優化 Poker 99 的 UI 互動體驗與多語言支援。
*   **目的：** 提供更精確的「指定 (Target)」操作，確保 UI 佈局穩定，並完善在地化設定。

#### **1.2 詳細需求 (Detailed Requirements)**

1.  **多語言設定更新**:
    *   在 `zh-TW.json`, `ja.json`, `en.json` 中新增 `poker_99` 區塊。
    *   新增 `target` (指定), `reverse` (反轉), `skip` (跳過), `next_turn` (下個出牌), `current_score` (目前分數) 等鍵值。
    *   將程式碼中 `poker_99.play` 的引用改為既有的 `play_action`。

2.  **UI 佈局穩定性**:
    *   修改 `_buildActionButtons`: 當無牌被選中時，回傳一個 `SizedBox(height: 48)` (或其他固定高度)，避免下方手牌區域因按鈕出現/消失而產生跳動。

3.  **指定 (Target) 邏輯優化**:
    *   修改 `_buildActionButtons`: 
        *   當選中 `5` 或 `Joker` 並點擊原本的「指定」邏輯時，應改為顯示「指定 [玩家名稱]」的多個按鈕。
        *   按鈕應遍歷 `otherPlayers` 列表，僅顯示尚未淘汰（手牌數 > 0）的玩家。
        *   點擊對應按鈕後，將 `targetPlayerId` 設為該玩家的 `uid` 並送出 `playCards`。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **修改：** `assets/translations/zh-TW.json`
*   **修改：** `assets/translations/ja.json`
*   **修改：** `assets/translations/en.json`
*   **修改：** `lib/play_session/poker_99_board_widget.dart`

#### **2.2 重要邏輯細節**

*   `Poker99State` 已有 `nextPlayerId()` 方法，但在手動指定時，應允許玩家選擇除自己外的任何存活對手。
*   `Poker99AI` 的邏輯目前是自動選擇上家，UI 層則提供玩家手動選擇的能力。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1.  確認翻譯檔案正確載入，按鈕文字顯示正確。
2.  點擊 5 或 Joker 時，會出現對應人數的指定按鈕。
3.  確認點擊指定按鈕後，目標玩家 ID 正確帶入 Payload。
4.  確認未選牌時，下方手牌區域高度保持不變。

#### **3.2 邏輯檢查與改善建議**

*   **邏輯檢查**：
    *   如果存活對手過多，按鈕橫向排列可能超出螢幕。建議在 `_buildActionButtons` 回傳時外層包覆 `SingleChildScrollView` 或使用 `Wrap`。
*   **改善建議**：
    *   針對 `Joker` 的指定功能，若按鈕過多，可考慮二階段操作：第一階段選「指定」，第二階段才出現人名按鈕，以節省空間。但目前依需求直接展開。

---

### **Section 4: 產出 Commit Message**

```text
feat(poker_99): enhance UI interactions and localization

- Update translations for Poker 99 actions and game status
- Add fixed-height placeholder for action buttons to stabilize UI layout
- Implement per-player targeting buttons for card '5' and 'Joker'
- Refactor _buildActionButtons to handle multi-player targeting logic
- Include Task Specification: FEAT-POKER-99-UI-003
```
