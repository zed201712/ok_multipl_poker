### **文件標頭 (Metadata)**

| 區塊 | 內容                                       | 目的/對 AI 的意義 |
| :--- |:-----------------------------------------|:--- |
| **任務 ID (Task ID)** | `FEAT-SELECTABLE-PLAYER-HAND-WIDGET-001` | 方便追蹤和版本控制。 |
| **創建日期 (Date)** | `2025/12/14`                             | - |
| **目標版本 (Target Version)** | `N/A`                                    | 新增可選擇卡牌的玩家手牌元件。 |
| **專案名稱 (Project)** | `ok_multipl_poker`                       | - |

---

### **Section 1: 核心任務定義 (Core Task Definition)**

#### **1.1 任務目標 (Goal)**

建立一個名為 `SelectablePlayerHandWidget` 的 Flutter Widget，作為大老二類型遊戲中玩家手牌的專用元件。此 Widget 應以 `PlayerHandWidget` 為基礎，並增加卡牌選擇功能和一個可自訂的按鈕列。

#### **1.2 詳細需求 (Detailed Requirements)**

*   **檔案建立:** 在 `lib/play_session/` 目錄下建立 `selectable_player_hand_widget.dart` 檔案。
*   **基礎結構:** 複製 `@/lib/play_session/player_hand_widget.dart` 的現有程式碼作為起點。
*   **卡牌選擇功能:**
    *   Widget 應監聽一個 `Player` 物件的狀態。
    *   當使用者點擊一張手牌 (`PlayingCardWidget`) 時，該卡牌應在 `player.selectedCards` 列表中進行新增或移除。
    *   被選中的卡牌在視覺上應向上平移 10 個像素，以和未選中的牌區分。這個視覺變化應在 `PlayingCardWidget` 中實現，由一個 `isSelected` 參數控制。
    *   不要修改`PlayingCardWidget`, 在player_hand_widget.dart實現向上平移
*   **可自訂按鈕列:**
    *   類似 `@/lib/play_session/big_two_board_widget.dart` 中的 `_buildHandTypeSelector` 方法，此 Widget 應顯示一個水平的按鈕列。
    *   按鈕的內容 (例如 `Text`) 和它們的 `onPressed` 回呼函式應由 `SelectablePlayerHandWidget` 的建構子傳入，以提供最大的 flexibilidad。
*   **重構目標:** `SelectablePlayerHandWidget` 必須能夠替換 `@/lib/play_session/big_two_board_widget.dart` 中的 `PlayerHandWidget` 和 `_buildHandTypeSelector`，並且在視覺上沒有任何差異。

---

### **Section 2: 技術細節與範圍 (Technical Scope & Constraints)**

#### **2.1 受影響/新增的檔案清單 (Affected Files)**

*   **新增:** `lib/play_session/selectable_player_hand_widget.dart`
*   **修改:** `@/lib/play_session/big_two_board_widget.dart` (將被重構以使用 `SelectablePlayerHandWidget`)
*   **可能修改:** `lib/play_session/playing_card_widget.dart` (為了新增 `isSelected` 參數和相應的視覺變化)。
*   **可能修改:** `lib/game_internals/player.dart` (建議新增 `toggleCardSelection(card)` 方法來封裝選擇邏輯)。
*   **參考:** `@/lib/play_session/player_hand_widget.dart` (作為基礎模板)。

#### **2.2 程式碼風格與技術棧 (Style & Stack)**

*   **狀態管理:** 使用 `provider` 套件來獲取 `Player` 物件的狀態，與現有程式碼庫保持一致。
*   **慣例:** 遵循 `effective_dart` 程式碼風格。為 `SelectablePlayerHandWidget` 及其主要參數添加清晰的 DartDoc 註解。

---

### **Section 3: 驗證與輸出 (Verification & Output)**

#### **3.1 預期回覆格式 (Expected Output Format)**

1.  **執行計劃：** 簡要說明將建立 `selectable_player_hand_widget.dart`，並根據需求修改相關檔案 (`PlayingCardWidget`, `Player`, `BigTwoBoardWidget`) 以實現卡牌選擇和重構目標。
2.  **程式碼輸出：** 提供新檔案 `lib/play_session/selectable_player_hand_widget.dart` 的完整內容，以及 `lib/play_session/big_two_board_widget.dart` 的修改後內容。

#### **3.2 驗證步驟 (Verification Steps)**

1.  確認新檔案 `lib/play_session/selectable_player_hand_widget.dart` 被成功建立。
2.  確認點擊手牌會使其向上移動，再次點擊則會使其歸位。
3.  確認 `player.selectedCards` 列表會隨著點擊而正確更新。
4.  確認 Widget 能夠接收一個按鈕設定列表，並正確顯示這些按鈕。
5.  確認點擊這些按鈕會觸發從外部傳入的對應回呼函式。
6.  確認 `@/lib/play_session/big_two_board_widget.dart` 在重構後，UI 顯示與行為皆與重構前相同。

---

### **Section 4: 邏輯錯誤檢查與改善建議 (Logic Check & Improvement Suggestions)**

#### **4.1 邏輯錯誤檢查 (Logic Error Check)**

目前描述的需求沒有明顯的邏輯錯誤。使用 `ChangeNotifier` (`Player`) 和 `provider` 的組合來驅動 UI 更新是一個在 Flutter 中非常標準且可靠的模式。核心邏輯（UI 反應狀態變化）是正確的。

#### **4.2 改善建議 (Improvement Suggestions)**

1.  **狀態管理一致性:** 如整個專案（如 `PlayerHandWidget`, `BigTwoBoardWidget`）已廣泛使用 `provider`。為了保持一致性和可讀性，繼續使用 `provider` (`context.watch`, `context.read`) 來進行狀態管理。

2.  **封裝選擇邏輯:** 將卡牌選擇的邏輯（新增/移除 `selectedCards` 列表）從 Widget 層移至 Model 層。可以在 `Player` class 中增加一個方法：
    '''dart
    void toggleCardSelection(PlayingCard card) {
      if (selectedCards.contains(card)) {
        selectedCards.remove(card);
      } else {
        selectedCards.add(card);
      }
      notifyListeners();
    }
    '''
    這樣，Widget 的職責只剩下呼叫 `player.toggleCardSelection(card)`，使程式碼更清晰且易於測試。

3.  **分離 `PlayingCardWidget` 的關注點:** 為了讓 `PlayingCardWidget` 更具重用性，它不應該直接依賴於 `Player` 物件。建議修改其建構子，接收 `onTap` 回呼和一個 `isSelected` 布林值。
    '''dart
    // In PlayingCardWidget
    final bool isSelected;
    final VoidCallback? onTap;

    // The parent (SelectablePlayerHandWidget) would then build it like this:
    PlayingCardWidget(
      card,
      isSelected: player.selectedCards.contains(card),
      onTap: () => player.toggleCardSelection(card),
    );
    '''
    這樣，`PlayingCardWidget` 只負責顯示，而選擇的邏輯和狀態則由上層 Widget 管理。
