根據 @firestore_message_controller_spec.md 生成程式碼
_____

用 @big_two_delegate_spec_012.md 的風格, 寫1個spec
| **任務 ID (Task ID)** | `FEAT-BIG-TWO-Board-Card_Area-001` |
| **創建日期 (Date)** | `2025/12/25` |

狀態管理, 使用Provider
遵循 `effective_dart` 程式碼風格

目的:
參考 @demo_room_widget.dart
製作一個demo_room_state_widget

檢查有無邏輯錯誤, 並提供改善建議

然後給這個spec 接下來要寫的程式碼, 1個commit message
_____
我review了, @firestore_turn_based_game_controller_spec_003.md的修改
並對下列檔案進行了修改
@firestore_turn_based_game_controller.dart
@draw_card_game_demo_page.dart

對它們進行git diff, 分析相關內容
整理容易理解的文字內容, 而不是程式碼, 並寫回到firestore_turn_based_game_controller_spec_003.md檔案
_____

參考 @demo_room_state_widget_spec.md 寫1個spec檔案

| **任務 ID (Task ID)** | `FEAT-DEMO-TIC-TAC-TOE-GAME-PAGE-001` |
| **創建日期 (Date)** | `2025/12/11` |

目的:
分析下列檔案相關內容
整理容易理解的文字內容, 而不是程式碼

風格: 遵循 `effective_dart` 程式碼風格，並為新的類別和公共方法添加 DartDoc 註解。
_____
依據 @big_two_delegate_spec_012.md 的風格
並依據 commit c42328b96486f06e2f23ada5b4267ef02707b9ff 的內容 產生 big_two_delegate_spec_010.md檔案
建立spec檔案 big_two_delegate_spec_010.md

| **任務 ID (Task ID)** | `FEAT-BIG-TWO-DELEGATE-010` |
| **創建日期 (Date)** | `2025/12/25` |

然後給commit message
-----

寫提示詞, 用來產生 @ai_dev_spec_template.md 風格的 spec
我要製作一個4人poker card遊戲, bigtwo操作頁面的bigtwo_board_widget.dart
提示詞要怎麼寫
_____

寫提示詞, 用來產生 @ai_dev_spec_template.md 風格的 spec, 放在@ai_specs/game_internals
目的: 發牌功能, 修改PlayingCard
新增一個static List<PlayingCard> func, 產生不重複的52張撲克牌
1~13 clubs
1~13 spades
1~13 hearts
1~13 diamonds
然後洗牌

並且在test新增一個 test的dart檔案, 來測試這個功能, 並新增測試項目
