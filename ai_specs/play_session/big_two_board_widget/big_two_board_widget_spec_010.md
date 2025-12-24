## AI 專案任務指示文件 (Feature Task)

| 區塊                        | 內容                                                 |
| :------------------------ | :------------------------------------------------- |
| **任務 ID (Task ID)**       | `FEAT-BIG-TWO-UI-010`                              |
| **標題 (Title)**            | `UNIFY TABLE CARD DISPLAY WITH SINGLE WRAP WIDGET` |
| **創建日期 (Date)**           | `2025/12/24`                                       |
| **目標版本 (Target Version)** | `N/A`                                              |
| **專案名稱 (Project)**        | `ok_multipl_poker`                                 |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)** **【必填】**

* **說明：**
  重構 Big Two 桌面牌區 UI，將「上一次出的牌 (Last Played Hand)」與「桌面 / 牌堆 (Deck Cards)」整合為**單一 `Wrap` 版面配置**，以提升桌面視覺一致性與 UI 語意清晰度。

* **目的：**

    1. **語意提升 (Semantic Clarity)：**
       建立 `TableCardWrapWidget` 作為桌面牌區的單一責任元件，避免由外層 `Column` 拼接多個卡牌區塊。
    2. **視覺一致性 (Visual Consistency)：**
       所有桌面牌皆存在於同一個 Wrap 流動平面中，更符合卡牌遊戲的「桌面感」。
    3. **擴充性 (Extensibility)：**
       未來可在同一 Wrap 中加入動畫、標示、分組或互動效果，而不需調整外部佈局結構。

---

#### **1.2 詳細需求 (Detailed Requirements)** **【必填】**

1. **新增桌面牌區 Widget**

    * 新增 `TableCardWrapWidget`：

        * 接收以下參數：

            * `List<PlayingCard> lastPlayedCards`
            * `String lastPlayedTitle`
            * `List<PlayingCard> deckCards`
        * 使用 **單一 `Wrap`** 作為主要佈局容器。

2. **Last Played 區塊內聚**

    * 新增 `_LastPlayedWidget`：

        * 負責顯示：

            * 上一次出牌標示（`_LastPlayedLabel`）
            * 上一次出牌的卡牌區域
        * 作為 **Wrap 的第一個 child** 出現（若 `lastPlayedCards` 非空）。

3. **Deck Cards 呈現方式**

    * `deckCards` 直接以卡牌 widget 形式追加至 Wrap 中：

        * 不再使用 `ShowOnlyCardAreaWidget`
        * 確保 Deck 與 Last Played 位於同一流動平面。

4. **標示元件抽離**

    * `_LastPlayedLabel`：

        * 僅負責顯示「Last Played: {title}」
        * 樣式具備視覺提示效果（背景色、邊框、圓角）

5. **既有 Widget 保留**

    * `ShowOnlyCardAreaWidget` 僅保留於 `_LastPlayedWidget` 內部使用，不再由外層 UI 直接組裝。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)** **【必填】**

* **新增 / 修改：**

    * `lib/ui/widgets/table_card_wrap_widget.dart`（或既有 UI widget 檔案）
* **修改：**

    * 使用桌面牌區的畫面（原本以 `Column + ShowOnlyCardAreaWidget` 組成者）

---

#### **2.2 程式碼風格 (Style)**

* 遵循 `Effective Dart`。
* Widget 命名以「語意責任」為主，而非佈局細節：

    * `TableCardWrapWidget`
    * `_LastPlayedWidget`
    * `_LastPlayedLabel`
* 避免在呼叫端組合 UI 區塊，改由高階 Widget 內聚。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 驗證步驟 (Verification Steps)**

1. **UI 行為確認**

    * 當 `lastPlayedCards` 為空：

        * Wrap 僅顯示 Deck Cards。
    * 當 `lastPlayedCards` 不為空：

        * Wrap 第一個 child 為 Last Played 區塊，其後接續 Deck Cards。

2. **視覺確認**

    * Last Played 標示與卡牌群組清楚可辨。
    * Wrap 換行行為正常，不因 Column 嵌套導致斷裂。

---

### **Section 4: Commit 程式碼分析與審查 (Analysis & Review)**

#### **4.1 潛在影響分析**

* **UI 結構調整：**

    * 桌面牌區由「多區塊 Column」轉為「單一 Wrap 流動版面」。
* **風險評估：**

    * 屬於顯示層變更，不影響遊戲邏輯與狀態管理。
* **可維護性提升：**

    * 減少畫面層級耦合，未來新增桌面牌型或動畫更容易。

---

#### **4.2 審查結論**

* 此重構成功將桌面牌區的 UI 語意集中於單一 Widget，
* 符合 **Single Responsibility Principle** 與 **Declarative UI** 的設計精神，
* 為後續桌面動畫與互動設計奠定良好基礎。