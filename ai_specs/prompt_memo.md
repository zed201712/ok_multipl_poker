根據 @firestore_message_controller_spec.md 生成程式碼
_____

根據 @firestore_room_state_controller_spec.md 寫一個spec
| **任務 ID (Task ID)** | `FEAT-DEMO-ROOM-STATE-WIDGET-001` |
| **創建日期 (Date)** | `2025/12/05` |

目的:
參考 @demo_room_widget.dart
製作一個demo_room_state_widget

檢查有無邏輯錯誤, 並提供改善建議
_____
我review了, @firestore_turn_based_game_controller_spec_003.md的修改
並對下列檔案進行了修改
@firestore_turn_based_game_controller.dart
@draw_card_game_demo_page.dart

對它們進行git diff, 分析相關內容
整理容易理解的文字內容, 而不是程式碼, 並寫回到firestore_turn_based_game_controller_spec_003.md檔案
_____

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
