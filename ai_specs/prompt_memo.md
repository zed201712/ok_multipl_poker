根據 @firestore_message_controller_spec.md 生成程式碼
_____

根據 @ai_dev_spec_template.md 寫一個spec

目的: 寫一個 firestore_message_controller.dart
仿照 @firestore_controller.dart 的做法, (StreamSubscription, DocumentSnapshot等

以message為單位, 做資訊的收發, 並寫一個void sendMessage用來作範例
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