import 'package:ok_multipl_poker/entities/poker_99_play_payload.dart';
import 'package:ok_multipl_poker/entities/poker_99_state.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/game_internals/card_suit.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/game_internals/poker_99_action.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';
import 'package:ok_multipl_poker/services/error_message_service.dart';
import '../entities/poker_player.dart';
import 'package:collection/collection.dart';

/// Poker 99 遊戲邏輯代理
/// 負責處理遊戲規則、狀態轉移與合法性檢查
class Poker99Delegate extends TurnBasedGameDelegate<Poker99State> {
  ErrorMessageService? _errorMessageService;

  @override
  Poker99State initializeGame(Room room) {
    final deck = PlayingCard.createDeck54();
    final players = <PokerPlayer>[];
    var seats = List<String>.from(room.seats);
    seats = room.randomizeSeats ? (seats..shuffle()) : seats;

    // 初始手牌每人 5 張
    const cardsPerPlayer = 5;

    for (int i = 0; i < seats.length; i++) {
      final uid = seats[i];
      final hand = deck.sublist(i * cardsPerPlayer, (i + 1) * cardsPerPlayer);

      String name;
      int avatarNumber;
      final participant = room.participants.firstWhere((p) => p.id == seats[i]);
      name = participant.name;
      avatarNumber = participant.avatarNumber;

      players.add(PokerPlayer(
        uid: uid,
        cards: hand.map(PlayingCard.cardToString).toList(),
        name: name,
        avatarNumber: avatarNumber,
      ));
    }

    final deckStartIndex = seats.length * cardsPerPlayer;
    final remainingDeck =
        deck.sublist(deckStartIndex).map(PlayingCard.cardToString).toList();

    return Poker99State(
      participants: players,
      seats: seats,
      currentPlayerId: seats.first,
      deckCards: remainingDeck,
      currentScore: 0,
      isReverse: false,
    );
  }

  PokerPlayer? myPlayer(String myUserId, Poker99State state) =>
      state.participants.firstWhereOrNull((p) => p.uid == myUserId);

  List<PokerPlayer> otherPlayers(String myUserId, Poker99State state) {
    final seatedPlayers = state.seatedPlayersList();
    final currentIndex = state.indexOfPlayerInSeats(myUserId, seatedPlayers: seatedPlayers);
    if (currentIndex == null) return [];

    final total = seatedPlayers.length;
    final next1Index = currentIndex + 1;
    final seatOrder = Iterable.generate(total - 1, (i) => (i + next1Index) % total);
    return seatOrder.map((offset) => state.participants[offset]).toList();
  }

  void setErrorMessageService(ErrorMessageService? service) {
    _errorMessageService = service;
  }

  @override
  Poker99State processAction(Room room, Poker99State currentState,
      String actionName, String participantId, Map<String, dynamic> payload) {
    if (currentState.winner != null && actionName != 'request_restart') {
      return currentState;
    }

    if (actionName == 'request_restart') {
      return _processRestartRequest(room, currentState, participantId);
    }

    if (currentState.currentPlayerId != participantId) return currentState;

    if (actionName == 'play_cards') {
      final playPayload = Poker99PlayPayload.fromJson(payload);
      return _playCards(currentState, participantId, playPayload);
    }

    return currentState;
  }

  Poker99State _processRestartRequest(
      Room room, Poker99State currentState, String participantId) {
    final newRequesters = List<String>.from(currentState.restartRequesters);
    if (!newRequesters.contains(participantId)) {
      newRequesters.add(participantId);
    }

    final playersCount = currentState.participants.length;

    if (currentState.seats.isNotEmpty &&
        newRequesters.length >= playersCount) {
      return initializeGame(room);
    }

    return currentState.copyWith(
      restartRequesters: newRequesters,
    );
  }

  Poker99State _playCards(
      Poker99State state, String playerId, Poker99PlayPayload payload) {
    final playerIndex = state.participants.indexWhere((p) => p.uid == playerId);
    if (playerIndex == -1) return state;
    final player = state.participants[playerIndex];

    if (payload.cards.isEmpty) return state;
    final cardStr = payload.cards.first;
    final card = PlayingCard.fromString(cardStr);

    final tempHand = List<String>.from(player.cards);
    if (!tempHand.remove(cardStr)) return state;

    // 檢查 Payload 合法性
    if (!_isValidAction(card, payload.action)) return state;

    // 1. 規則邏輯：計算分數與特殊功能
    int newScore = state.currentScore;
    bool newIsReverse = state.isReverse;
    String? nextTargetId;

    switch (payload.action) {
      case Poker99Action.increase:
      case Poker99Action.decrease:
        newScore += payload.value;
        break;
      case Poker99Action.skip:
        // 在此規則中，Skip 只是不加分，直接輪到下一家
        break;
      case Poker99Action.reverse:
        newIsReverse = !newIsReverse;
        break;
      case Poker99Action.target:
        nextTargetId = payload.targetPlayerId;
        break;
      case Poker99Action.setToZero:
        newScore = 0;
        break;
      case Poker99Action.setTo99:
        newScore = 99;
        break;
    }

    // 驗證：如果超過 99
    if (newScore > 99) return state;
    // 如果低於 0，將 score 設為 0
    if (newScore < 0) newScore = 0;

    // 2. 抽牌邏輯
    final deck = List<String>.from(state.deckCards);
    final discard = List<String>.from(state.discardCards);

    // 牌堆不會重洗，如果牌堆沒牌，則不用抽牌
    if (deck.isNotEmpty) {
      final drawnCard = deck.removeAt(0);
      tempHand.add(drawnCard);
    }

    // 更新玩家手牌
    final newPlayer = player.copyWith(cards: tempHand);
    final newParticipants = List<PokerPlayer>.from(state.participants);
    newParticipants[playerIndex] = newPlayer;

    // 3. 計算下一位玩家
    final tempStateForNext = state.copyWith(
      participants: newParticipants,
      isReverse: newIsReverse,
      currentPlayerId: playerId,
    );
    final nextId = _calculateNextPlayerId(tempStateForNext, targetId: nextTargetId);

    final newState = state.copyWith(
      participants: newParticipants,
      deckCards: deck,
      discardCards: [cardStr, ...discard],
      lastPlayedHand: [cardStr],
      lastPlayedById: playerId,
      currentScore: newScore,
      isReverse: newIsReverse,
      targetPlayerId: '',
      currentPlayerId: nextId,
    );

    // 4. 檢查淘汰與勝利
    return _checkEliminationAndWinner(newState);
  }

  bool _isValidAction(PlayingCard card, Poker99Action action) {
    if (card.isJoker()) {
      // 鬼牌可以選擇多種功能
      return [
        Poker99Action.skip,
        Poker99Action.reverse,
        Poker99Action.target,
        Poker99Action.setToZero,
        Poker99Action.setTo99
      ].contains(action);
    }

    // 黑桃 1 (Spades Ace) 可以歸零
    if (card.suit == CardSuit.spades && card.value == 1) {
      if (action == Poker99Action.setToZero) return true;
    }

    switch (card.value) {
      case 1: // Ace (非黑桃)
        return action == Poker99Action.increase;
      case 4: // Reverse
        return action == Poker99Action.reverse;
      case 5: // Assign
        return action == Poker99Action.target;
      case 10: // +/- 10
        return action == Poker99Action.increase ||
            action == Poker99Action.decrease;
      case 11: // Jack (Skip/Pass)
        return action == Poker99Action.skip;
      case 12: // Queen (+/- 20)
        return action == Poker99Action.increase ||
            action == Poker99Action.decrease;
      case 13: // King (99)
        return action == Poker99Action.setTo99;
      default: // 一般牌
        return action == Poker99Action.increase;
    }
  }

  String _calculateNextPlayerId(Poker99State state, {String? targetId}) {
    final seats = state.seats;
    final currentIndex = seats.indexOf(state.currentPlayerId);

    // 處理指定 (Assign)
    if (targetId != null && seats.contains(targetId)) {
      final target = state.participants.firstWhereOrNull((p) => p.uid == targetId);
      if (target != null && target.cards.isNotEmpty) return targetId;
    }

    int step = state.isReverse ? -1 : 1;

    int nextIdx = (currentIndex + step) % seats.length;
    if (nextIdx < 0) nextIdx += seats.length;

    // 尋找下一個未淘汰玩家
    while (state.participants
        .firstWhere((p) => p.uid == seats[nextIdx])
        .cards.isEmpty) {
      nextIdx = (nextIdx + (state.isReverse ? -1 : 1)) % seats.length;
      if (nextIdx < 0) nextIdx += seats.length;
      if (nextIdx == currentIndex) break;
    }

    return seats[nextIdx];
  }

  Poker99State _checkEliminationAndWinner(Poker99State state) {
    // 當所有人都出完手牌，則所有人獲勝
    final allPlayersOut = state.participants.every((p) => p.cards.isEmpty);
    if (allPlayersOut) {
      final winners = state.participants.map((p) => p.name).join(', ');
      return state.copyWith(winner: winners);
    }

    final currentPlayer = state.participants
        .firstWhereOrNull((p) => p.uid == state.currentPlayerId);

    // 如果輪到下個必須出牌的玩家，但他出的所有牌都會超過 99，則此人為輸家
    if (currentPlayer != null && currentPlayer.cards.isNotEmpty) {
      final playable =
          getPlayableCards(state, currentPlayer.cards.toPlayingCards());
      if (playable.isEmpty) {
        // 此人為輸家，將所有其他玩家的名字設定到 winner
        final winners = state.participants
            .where((p) => p.uid != state.currentPlayerId)
            .map((p) => p.name)
            .join(', ');
        return state.copyWith(winner: winners);
      }
    }

    return state;
  }

  /// 獲取玩家手牌中目前可出的卡片 (不會導致總分超過 99)
  List<PlayingCard> getPlayableCards(
      Poker99State state, List<PlayingCard> handCards) {
    return handCards.where((card) {
      if (card.isJoker()) return true; // 鬼牌總是可以出

      // 黑桃 Ace 可以歸零，所以總是可以出
      if (card.suit == CardSuit.spades && card.value == 1) return true;

      switch (card.value) {
        case 10: // 10 可以減，所以總能出
        case 12: // Q 可以減，所以總能出
        case 4: // 功能牌點數不變
        case 5:
        case 11:
        case 13: // K 直接設為 99
          return true;
        case 1: // Ace (+1)
          return state.currentScore + 1 <= 99;
        default: // 一般牌
          return state.currentScore + card.value <= 99;
      }
    }).toList();
  }

  @override
  String? getCurrentPlayer(Poker99State state) => state.currentPlayerId;

  @override
  String? getWinner(Poker99State state) => state.winner;

  @override
  Poker99State stateFromJson(Map<String, dynamic> json) =>
      Poker99State.fromJson(json);

  @override
  Map<String, dynamic> stateToJson(Poker99State state) => state.toJson();
}
