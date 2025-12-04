根據 @firestore_message_controller_spec.md 生成程式碼
_____

根據 @firestore_room_state_controller_spec.md 寫一個spec
| **任務 ID (Task ID)** | `FEAT-DEMO-ROOM-STATE-WIDGET-001` |
| **創建日期 (Date)** | `2025/12/05` |

目的:
參考 @demo_room_widget.dart
製作一個demo_room_state_widget

@firestore_room_state_controller.dart
增加一個function updateRoomBody

createRoom的裝置, listen room_request, 接收到新的request, 會將room的body改成 'updated: $ManagerId, requesterId: $request.participantId'

當另一個participant 請求join room, 不再建立collection room/{participant}, 而是participant 用FirestoreRoomStateController sendRequest, body: 'join'
roomManager會將participantId加入, updateRoom 將participantId加入 room的participants
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
_____
產生 @ai_dev_spec_template.md 風格的 spec
分析 @RoomDemoScreen.dart 的內容, 產生 room_demo_screen_spec.md
