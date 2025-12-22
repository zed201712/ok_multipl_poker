| **任務 ID (Task ID)** | `FEAT-BIG-TWO-DELEGATE-008` |
| **創建日期 (Date)** | `2025/12/22` |

遵循 `effective_dart` 程式碼風格

### 1. 目的 (Objective)

為了方便開發和測試，本次任務旨在建立一個僅在測試模式 (Test Mode) 下顯示的除錯工具。此工具允許開發者即時讀取 (Get) 和覆寫 (Set) 當前的遊戲狀態 (`BigTwoState`)。

1.  **新增除錯 Widget**: 建立一個名為 `DebugTextWidget` 的新組件，包含一個文字輸入框和「Get」、「Set」兩個按鈕。此 Widget 只在 `SettingsController.testModeOn` 為 `true` 時，顯示於 `BigTwoBoardWidget` 中。
2.  **增強 `BigTwoState`**: 在 `BigTwoState` 類中加入 `toJsonString()` 和 `fromJsonString()` 方法，以便與 JSON 字串進行序列化和反序列化。
3.  **整合狀態管理**: 在 `BigTwoBoardWidget` 中實現 `DebugTextWidget` 的邏輯：
    *   「Get」按鈕：將最新的 `BigTwoState` 轉換為 JSON 字串並顯示在文字輸入框中。
    *   「Set」按鈕：讀取文字輸入框中的 JSON 字串，轉換回 `BigTwoState` 物件，並透過 `FirestoreBigTwoController` 更新 Firestore 上的遊戲狀態。

### 2. 設計思路 (Design Approach)

1.  **`BigTwoState` JSON 轉換**:
    *   檔案路徑: `lib/entities/big_two_state.dart`
    *   引入 `dart:convert`。
    *   新增 `String toJsonString()` 方法，內部使用 `jsonEncode(toJson())`。
    *   新增 `factory BigTwoState.fromJsonString(String jsonString)`，內部使用 `BigTwoState.fromJson(jsonDecode(jsonString))`。

2.  **`DebugTextWidget` 實作**:
    *   新增檔案: `lib/play_session/debug_text_widget.dart`
    *   建立一個 `StatefulWidget` 以管理 `TextEditingController`。
    *   Widget 包含一個 `TextField` (多行)、一個 `Get` 按鈕和一個 `Set` 按鈕。
    *   它將接收一個 `onGet` (`VoidCallback`) 和一個 `onSet` 回呼函數 `void Function(String)` 以及一個 `TextEditingController`。當 `Set` 按鈕被點擊時，將觸發此回呼。

3.  **`BigTwoBoardWidget` 整合**:
    *   檔案路徑: `lib/play_session/big_two_board_widget.dart`
    *   在 `_BigTwoBoardWidgetState` 中，宣告一個 `TextEditingController` 給除錯工具使用。
    *   在 `build` 方法的 `StreamBuilder` 內部，保存最新的 `bigTwoState`。
    *   在 Widget 佈局的頂層 (例如 `Stack` 的最上層)，條件式地顯示 `DebugTextWidget`：
        ```dart
        if (context.watch<SettingsController>().testModeOn.value)
          _buildDebugWidget(latestBigTwoState),
        ```
    *   `Get` 邏輯: 當按鈕觸發時，將 `latestBigTwoState.toJsonString()` 的結果設定到 `_debugTextController.text`。
    *   `Set` 邏輯: 當按鈕觸發時，讀取 `_debugTextController.text`，透過 `BigTwoState.fromJsonString()` 轉換成 `BigTwoState` 物件，然後呼叫 `_gameController` 中的新方法 (例如 `debugSetState`) 來更新遠端狀態。

4.  **`FirestoreBigTwoController` 修改**:
    *   檔案路徑: `lib/multiplayer/firestore_big_two_controller.dart`
    *   新增 `Future<void> debugSetState(BigTwoState newState)` 方法。
    *   此方法會直接使用 `_roomDocRef.update()` 來覆寫 `customState` 欄位，同時為了狀態一致性，也應一併更新 `currentPlayerId`。

### 3. 核心實作

#### `lib/entities/big_two_state.dart`

```dart
import '''dart:convert''';
import '''package:collection/collection.dart''';
// ... other imports

part '''big_two_state.g.dart''';

@JsonSerializable(explicitToJson: true)
class BigTwoState {
  // ... existing properties and constructor

  factory BigTwoState.fromJson(Map<String, dynamic> json) =>
      _$BigTwoStateFromJson(json);
  
  // NEW: Factory from JSON string
  factory BigTwoState.fromJsonString(String jsonString) {
    return BigTwoState.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => _$BigTwoStateToJson(this);

  // NEW: Method to get JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // ... other methods
}
```

#### `lib/play_session/debug_text_widget.dart` (新檔案)

```dart
import '''package:flutter/material.dart''';

class DebugTextWidget extends StatefulWidget {
  final VoidCallback onGet;
  final Function(String) onSet;
  final TextEditingController controller;

  const DebugTextWidget({
    super.key,
    required this.onGet,
    required this.onSet,
    required this.controller,
  });

  @override
  State<DebugTextWidget> createState() => _DebugTextWidgetState();
}

class _DebugTextWidgetState extends State<DebugTextWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.black.withOpacity(0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('''Debug State Editor''', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: TextField(
              controller: widget.controller,
              maxLines: null,
              expands: true,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: widget.onGet,
                child: const Text('''Get'''),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => widget.onSet(widget.controller.text),
                child: const Text('''Set'''),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

#### `lib/play_session/big_two_board_widget.dart`

```dart
// ... imports
import '''package:ok_multipl_poker/play_session/debug_text_widget.dart''';
import '''package:provider/provider.dart''';
import '''../settings/settings.dart''';

class _BigTwoBoardWidgetState extends State<BigTwoBoardWidget> {
  // ... existing properties
  final _debugTextController = TextEditingController();
  
  // ... initState, dispose

  @override
  void dispose() {
    _debugTextController.dispose();
    // ... other disposals
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>(); // watch for changes

    return Provider<CardPlayer>(
      create: (_) => _player,
      child: StreamBuilder<TurnBasedGameState<BigTwoState>?>(
        stream: _gameController.gameStateStream,
        builder: (context, snapshot) {
          // ... (Pre-game checks)
          
          final gameState = snapshot.data!;
          final bigTwoState = gameState.customState;

          // ... (rest of the build method)

          return Scaffold(
            body: Stack(
              children: [
                // ... All existing widgets
                
                // --- 除錯工具 ---
                if (settings.testModeOn.value)
                  Positioned(
                    top: 40,
                    left: 20,
                    right: 20,
                    child: Material( // Added material for better theming
                      type: MaterialType.transparency,
                      child: DebugTextWidget(
                        controller: _debugTextController,
                        onGet: () {
                          _debugTextController.text = bigTwoState.toJsonString();
                        },
                        onSet: (jsonString) {
                          try {
                            final newState = BigTwoState.fromJsonString(jsonString);
                            _gameController.debugSetState(newState);
                          } catch (e) {
                            // 顯示錯誤提示
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('''Error parsing state: $e''')),
                            );
                          }
                        },
                      ),
                    )
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

#### `lib/multiplayer/firestore_big_two_controller.dart`

```dart
// ... imports
import '''package:flutter/foundation.dart''';

class FirestoreBigTwoController {
  // ... existing properties and methods

  Future<void> debugSetState(BigTwoState newState) async {
    if (_roomDocRef == null) return;
    try {
      await _roomDocRef!.update({
        '''customState''': newState.toJson(),
        '''currentPlayerId''': newState.currentPlayerId,
      });
    } catch (e) {
      // Handle potential errors, e.g., logging
      debugPrint("Failed to set debug state: $e");
    }
  }
}
```

### 4. 邏輯檢查與改善建議

1.  **安全性**: 此功能賦予客戶端極大的權限，可以直接修改遊戲核心狀態。將其限制在 `testModeOn == true` 的條件下是正確且必要的，確保在正式發布的應用中此功能是關閉的。
2.  **錯誤處理**: 在 `onSet` 的邏輯中，`BigTwoState.fromJsonString` 可能會因為 JSON 格式錯誤或欄位不匹配而拋出異常。目前已使用 `try-catch` 區塊來捕捉錯誤並透過 `SnackBar` 提示用戶，這是很好的實踐。
3.  **狀態一致性**: 當透過 `debugSetState` 更新 `customState` 時，同時更新 `TurnBasedGameState` 中的頂層欄位 (如 `currentPlayerId`) 是非常重要的。目前的設計已經考慮到了這一點，可以確保遊戲流程的控制器能夠正確反應狀態變化。
4.  **UI/UX**: `DebugTextWidget` 被放置在 `Stack` 的頂層，並帶有半透明黑色背景，這能讓它在不完全遮擋遊戲畫面的情況下清晰可見。使用 `Positioned` 控制其位置是合理的。在 `big_two_board_widget.dart` 中，建議將 `DebugTextWidget` 包裹在一個 `Material` widget 中，以確保 `TextField` 等組件能正確繼承 `ThemeData`。

整體邏輯正確，且已考慮到關鍵的風險點。此設計能有效達成除錯目的。

### 5. Commit Message

```
feat(debug): Add widget to get/set BigTwo game state in test mode

Implements a debug panel, visible only when `testModeOn` is enabled.

This feature includes:
- A new `DebugTextWidget` with get/set functionality for game state.
- `toJsonString()` and `fromJsonString()` helpers in `BigTwoState` for easy serialization.
- A `debugSetState` method in `FirestoreBigTwoController` to update the game state on Firestore.

This tool allows for rapid testing and debugging of various game scenarios by directly manipulating the `BigTwoState`.
```