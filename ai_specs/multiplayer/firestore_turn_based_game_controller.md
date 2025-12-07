| **任務 ID (Task ID)** | `FEAT-TURN-BASED-CONTROLLER-001` |
| **創建日期 (Date)** | `2025/12/07` |

### 1. 目的 (Objective)

本文件旨在規劃一個**通用、可重用**的 `FirestoreTurnBasedGameController`。此 `Controller` 透過持有 `FirestoreRoomStateController` 實例，將底層的房間和網路操作，與上層的遊戲邏輯完全解耦，為各類回合制遊戲（如棋類、卡牌遊戲等）提供一個統一、穩健的開發框架。

核心目標是實現一個**委託模式 (Delegate Pattern)**。`FirestoreTurnBasedGameController` 負責處理所有通用的網路同步、請求分發、狀態更新等任務，而將所有「遊戲特定」的規則（如何開始、如何執行一個回合、誰是下一位玩家、何時結束）**委託**給一個由外部注入的 `TurnBasedGameDelegate` 來決定。

### 2. 設計模式：遊戲邏輯委託 (Game Logic Delegation)

我們將定義一個 `TurnBasedGameDelegate<T>` 接口（在 Dart 中為 `abstract class`）。任何特定的遊戲都需要實現此接口，其中 `T` 代表該遊戲自訂的狀態模型（例如 `BigTwoGameState`, `ChessGameState`）。

*   **`abstract class TurnBasedGameDelegate<T>`**: 
    *   **`T initializeGame(List<String> playerIds)`**: 根據玩家列表，創建並返回遊戲的初始狀態 `T`。
    *   **`T processAction(T currentState, String action, String playerId, Map<String, dynamic> payload)`**: 處理一個玩家的行動。接收當前狀態和玩家的請求，返回更新後的新狀態 `T`。所有遊戲規則（如出牌驗證、移動棋子、勝負判斷）都在此實現。
    *   **`T stateFromJson(Map<String, dynamic> json)`**: 將儲存在 Firestore 中的 `body` 的一部分（`customState`）反序列化為特定的遊戲狀態物件 `T`。
    *   **`Map<String, dynamic> stateToJson(T state)`**: 將遊戲狀態物件 `T` 序列化為 JSON，以便儲存。

### 3. 通用資料實體 (Generic Data Entity)

`Room` document 的 `body` 欄位將儲存一個通用的回合制遊戲狀態結構。

*   **定義 `TurnBasedGameState<T>` Class**: 
    *   `gameStatus`: `String` - 通用遊戲狀態 (e.g., `waiting`, `playing`, `finished`)。
    *   `turnOrder`: `List<String>` - 玩家 UID 的順序。
    *   `currentPlayerId`: `String?` - 當前回合的玩家 UID。
    *   `winner`: `String?` - 勝利者的 UID。
    *   `customState`: `T` - 儲存由 `Delegate` 定義的、遊戲特定的狀態物件。

### 4. Class 設計 (`FirestoreTurnBasedGameController<T>`)

*   **`FirestoreTurnBasedGameController<T>` Class**:
    *   `_roomStateController`: `final FirestoreRoomStateController` - 底層房間控制器。
    *   `_delegate`: `final TurnBasedGameDelegate<T>` - 由外部注入的遊戲規則委託。
    *   `gameStateStream`: `ValueStream<TurnBasedGameState<T>?>` - 向 UI 暴露的、包含完整解析後遊戲狀態的流。
    *   **Constructor**: `FirestoreTurnBasedGameController(this._roomStateController, this._delegate)`
        *   啟動對 `_roomStateController.roomStateStream` 的監聽，並在每次更新時調用內部的 `_onRoomStateChanged` 方法。

### 5. Public 方法 (Public Methods)

這些是 `Controller` 向外部（UI 層）提供的標準 API。

*   **`Future<String> matchAndJoinRoom(...)`**: 匹配或創建一個遊戲房間。直接調用 `_roomStateController.matchRoom()`。
*   **`Future<void> leaveRoom()`**: 離開房間。直接調用 `_roomStateController.leaveRoom()`。
*   **`Future<void> startGame()`**: 發起開始遊戲的請求。內部調用 `_roomStateController.sendRequest(body: {'action': 'start_game'})`。
*   **`Future<void> sendGameAction(String action, {Map<String, dynamic>? payload})`**: 玩家發起一個遊戲內的行動（如出牌、下棋）。這會被包裝成一個標準請求，由房主端的 `Delegate` 處理。
    *   **實現**: `_roomStateController.sendRequest(body: {'action': 'game_action', 'name': action, 'payload': payload ?? {}})`

### 6. 核心處理邏輯 (Core Processing Logic)

所有核心邏輯都由房主 (Manager) 權威執行，並透過 `Delegate` 實現。

*   **`_onRoomStateChanged(RoomState roomState)`** (房主端運行):
    1.  **解析通用狀態**: 從 `roomState.room?.body` 解析出 `TurnBasedGameState<T>`。解析 `customState` 時，調用 `_delegate.stateFromJson()`。
    2.  **推送狀態流**: 將解析後的 `TurnBasedGameState` 推送到 `gameStateStream`，供所有玩家的 UI 訂閱。
    3.  **身份驗證**: 檢查自己是否為房主 (`managerUid`)。如果不是，則終止後續操作。
    4.  **遍歷並委託請求**: 遍歷 `roomState.requests`，根據請求的 `action` 執行相應操作：
        *   **`case 'start_game'`**: 
            1.  調用 `_delegate.initializeGame(room.participants)` 來獲取初始遊戲狀態 `T`。
            2.  將其包裝成一個新的 `TurnBasedGameState`。
            3.  序列化整個 `TurnBasedGameState`，並調用 `_roomStateController.updateRoom()` 更新 `body`。
        *   **`case 'game_action'`**: 
            1.  從請求中解構出 `action`, `payload` 和發起者 `playerId`。
            2.  調用 `_delegate.processAction(currentState.customState, action, playerId, payload)`，獲取更新後的遊戲狀態 `T`。
            3.  更新 `TurnBasedGameState` 的其他通用欄位（如 `currentPlayerId`， `winner` 等，這些也由 `Delegate` 在 `processAction` 中決定）。
            4.  序列化並更新 `body`。

### 7. 邏輯檢查與優勢分析

*   **高度抽象與重用**: 此設計是成功的。`FirestoreTurnBasedGameController` 完全不知道也不關心上層是什麼遊戲。開發一個新的回合制遊戲，工作量將主要集中在實現 `TurnBasedGameDelegate` 接口，而無需重寫任何網路同步代碼。
*   **清晰的職責劃分**: 
    *   `FirestoreRoomStateController`: 處理最底層的 Document、Collection、玩家列表、房主心跳和移交機制。
    *   `FirestoreTurnBasedGameController`: 扮演「中間件」角色，管理通用的遊戲流程（開始、行動），並作為房主權威和 `Delegate` 之間的中介。
    *   `YourGameDelegate`: 實現所有「商業邏輯」——遊戲規則。
*   **滿足用戶需求**: `bool isMyTurn` 的邏輯可以簡單地在 UI 層透過 `gameStateStream.map((state) => state?.currentPlayerId == myUserId)` 來實現。`Delegate` 負責決定 `currentPlayerId` 是誰，框架負責將這個資訊可靠地同步給所有玩家，完美實現了用戶的初衷。
*   **健壯性**: 自動繼承了 `FirestoreRoomStateController` 的所有優點，包括房主斷線後的自動、有序接管。新房主將自動開始運行遊戲邏輯的權威，確保遊戲不會中斷。


### 執行
執行 @firestore_turn_based_game_controller.md, 然後搭配 @playing_card.dart, 實現一個抽牌比大小的demo widget