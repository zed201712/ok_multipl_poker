import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../game_internals/board_state.dart';
import '../game_internals/playing_area.dart';
import '../game_internals/playing_card.dart';

/// 負責處理本地遊戲狀態與 Firestore 之間同步的控制器。
class FirestoreController {
  static final _log = Logger('FirestoreController');

  /// Firebase Firestore 的實例。
  final FirebaseFirestore instance;

  /// 本地遊戲板的狀態。
  final BoardState boardState;

  /// 目前，只有一場遊戲。但為了未來支援遊戲配對（match-making）功能，
  /// 我們將其放在一個名為 'matches' 的 Firestore 集合中。
  late final _matchRef = instance.collection('matches').doc('match_1');

  /// 指向第一個遊戲區域的 Firestore 文件參考。
  /// 使用 `withConverter` 來自動轉換資料格式。
  late final _areaOneRef = _matchRef
      .collection('areas')
      .doc('area_one')
      .withConverter<List<PlayingCard>>(
        fromFirestore: _cardsFromFirestore,
        toFirestore: _cardsToFirestore,
      );

  /// 指向第二個遊戲區域的 Firestore 文件參考。
  /// 使用 `withConverter` 來自動轉換資料格式。
  late final _areaTwoRef = _matchRef
      .collection('areas')
      .doc('area_two')
      .withConverter<List<PlayingCard>>(
        fromFirestore: _cardsFromFirestore,
        toFirestore: _cardsToFirestore,
      );

  StreamSubscription<void>? _areaOneFirestoreSubscription;
  StreamSubscription<void>? _areaTwoFirestoreSubscription;

  StreamSubscription<void>? _areaOneLocalSubscription;
  StreamSubscription<void>? _areaTwoLocalSubscription;

  FirestoreController({required this.instance, required this.boardState}) {
    // 訂閱遠端（來自 Firestore）的變更。
    _areaOneFirestoreSubscription = _areaOneRef.snapshots().listen((snapshot) {
      _updateLocalFromFirestore(boardState.areaOne, snapshot);
    });
    _areaTwoFirestoreSubscription = _areaTwoRef.snapshots().listen((snapshot) {
      _updateLocalFromFirestore(boardState.areaTwo, snapshot);
    });

    // 訂閱本地遊戲狀態的變更。
    _areaOneLocalSubscription = boardState.areaOne.playerChanges.listen((_) {
      _updateFirestoreFromLocalAreaOne();
    });
    _areaTwoLocalSubscription = boardState.areaTwo.playerChanges.listen((_) {
      _updateFirestoreFromLocalAreaTwo();
    });

    _log.fine('Initialized');
  }

  /// 釋放資源，取消所有監聽。
  void dispose() {
    _areaOneFirestoreSubscription?.cancel();
    _areaTwoFirestoreSubscription?.cancel();
    _areaOneLocalSubscription?.cancel();
    _areaTwoLocalSubscription?.cancel();

    _log.fine('Disposed');
  }

  /// 從 Firestore 傳來的原始 JSON 快照，並嘗試將其轉換為 [PlayingCard] 列表。
  List<PlayingCard> _cardsFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()?['cards'] as List?;

    if (data == null) {
      _log.info('No data found on Firestore, returning empty list');
      return [];
    }

    final list = List.castFrom<Object?, Map<String, Object?>>(data);

    try {
      return list.map((raw) => PlayingCard.fromJson(raw)).toList();
    } catch (e) {
      throw FirebaseControllerException(
        '從 Firestore 解析資料失敗: $e',
      );
    }
  }

  /// 將 [PlayingCard] 列表轉換為可儲存到 Firestore 的 JSON 物件。
  Map<String, Object?> _cardsToFirestore(
    List<PlayingCard> cards,
    SetOptions? options,
  ) {
    return {'cards': cards.map((c) => c.toJson()).toList()};
  }

  /// 使用 [area] 的本地狀態更新 Firestore。
  void _updateFirestoreFromLocal(
    PlayingArea area,
    DocumentReference<List<PlayingCard>> ref,
  ) async {
    try {
      _log.fine('Updating Firestore with local data (${area.cards}) ...');
      await ref.set(area.cards);
      _log.fine('... done updating.');
    } catch (e) {
      throw FirebaseControllerException(
        'Failed to update Firestore with local data (${area.cards}): $e',
      );
    }
  }

  /// 將 [boardState.areaOne] 的本地狀態傳送到 Firestore。
  void _updateFirestoreFromLocalAreaOne() {
    _updateFirestoreFromLocal(boardState.areaOne, _areaOneRef);
  }

  /// 將 [boardState.areaTwo] 的本地狀態傳送到 Firestore。
  void _updateFirestoreFromLocalAreaTwo() {
    _updateFirestoreFromLocal(boardState.areaTwo, _areaTwoRef);
  }

  /// 使用來自 Firestore 的資料更新 [area] 的本地狀態。
  void _updateLocalFromFirestore(
    PlayingArea area,
    DocumentSnapshot<List<PlayingCard>> snapshot,
  ) {
    _log.fine('Received new data from Firestore (${snapshot.data()})');

    final cards = snapshot.data() ?? [];

    if (listEquals(cards, area.cards)) {
      _log.fine('No change');
    } else {
      _log.fine('Updating local data with Firestore data ($cards)');
      area.replaceWith(cards);
    }
  }
}

/// Firestore 控制器相關的例外。
class FirebaseControllerException implements Exception {
  final String message;

  FirebaseControllerException(this.message);

  @override
  String toString() => 'FirebaseControllerException: $message';
}
