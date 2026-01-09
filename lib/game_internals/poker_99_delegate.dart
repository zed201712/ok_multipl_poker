import 'package:ok_multipl_poker/entities/big_two_player.dart';
import 'package:ok_multipl_poker/entities/poker_99_state.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/game_internals/card_suit.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';
import 'package:ok_multipl_poker/services/error_message_service.dart';
import 'big_two_deck_utils_mixin.dart';
import 'package:collection/collection.dart';

/// Poker 99 遊戲邏輯代理
/// 負責處理遊戲規則、狀態轉移與合法性檢查
class Poker99Delegate extends TurnBasedGameDelegate<Poker99State> with BigTwoDeckUtilsMixin {
  ErrorMessageService? _errorMessageService;

  @override
  Poker99State initializeGame(Room room) {
    final deck = PlayingCard.createDeck54();
    final players = <BigTwoPlayer>[];
    var seats = List<String>.from(room.seats);
    seats = room.randomizeSeats ? (seats..shuffle()) : seats;

    // Poker 99 通常為 4 人局，不足則補虛擬玩家
    if (seats.length < 4) {
      final virtualPlayerCount = 4 - seats.length;
      final virtualPlayers = Iterable.generate(virtualPlayerCount, (i) => i + 1)
          .map((i) => "virtual_player$i");
      seats.addAll(virtualPlayers);
    }

    // 初始手牌每人 5 張
    const cardsPerPlayer = 5;
    
    for (int i = 0; i < seats.length; i++) {
      final uid = seats[i];
      final isVirtual = uid.startsWith('virtual_player');
      final hand = deck.sublist(i * cardsPerPlayer, (i + 1) * cardsPerPlayer);
      
      String name;
      int avatarNumber;
      if (isVirtual) {
        name = 'AI $uid';
        avatarNumber = 0; // Default AI avatar
      } else {
        final participant = room.participants.firstWhere((p) => p.id == seats[i]);
        name = participant.name;
        avatarNumber = participant.avatarNumber;
      }

      players.add(BigTwoPlayer(
        uid: uid,
        name: name,
        cards: hand.map(PlayingCard.cardToString).toList(),
        hasPassed: false,
        isVirtualPlayer: isVirtual,
        avatarNumber: avatarNumber,
      ));
    }
    
    final deckStartIndex = seats.length * cardsPerPlayer;
    final remainingDeck = deck.sublist(deckStartIndex).map(PlayingCard.cardToString).toList();

    return Poker99State(
      participants: players,
      seats: seats,
      currentPlayerId: seats.first,
      deckCards: remainingDeck,
      currentScore: 0,
      isReverse: false,
    );
  }

  BigTwoPlayer? myPlayer(String myUserId, Poker99State state) => state.participants.firstWhereOrNull((p) => p.uid == myUserId);

  List<BigTwoPlayer> otherPlayers(String myUserId, Poker99State state) {
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
  Poker99State processAction(
      Room room, Poker99State currentState, String actionName, String participantId, Map<String, dynamic> payload) {
    
    if (currentState.winner != null && actionName != 'request_restart') return currentState;

    if (actionName == 'request_restart') {
      return _processRestartRequest(room, currentState, participantId);
    }

    if (currentState.currentPlayerId != participantId) return currentState;

    if (actionName == 'play_cards') {
      final cardsStr = List<String>.from(payload['cards'] ?? []);
      return _playCards(currentState, participantId, cardsStr, payload);
    }
    
    return currentState;
  }

  Poker99State _processRestartRequest(Room room, Poker99State currentState, String participantId) {
     final newRequesters = List<String>.from(currentState.restartRequesters);
      if (!newRequesters.contains(participantId)) {
        newRequesters.add(participantId);
      }

      final realPlayersCount = currentState.participants.where((p) => !p.isVirtualPlayer).length;
      
      if (currentState.seats.isNotEmpty && newRequesters.length >= realPlayersCount) {
        return initializeGame(room);
      }

      return currentState.copyWith(
        restartRequesters: newRequesters,
      );
  }

  Poker99State _playCards(Poker99State state, String playerId, List<String> cardsPlayed, Map<String, dynamic> payload) {
    final playerIndex = state.participants.indexWhere((p) => p.uid == playerId);
    if (playerIndex == -1) return state;
    final player = state.participants[playerIndex];
    
    if (cardsPlayed.isEmpty) return state;
    final cardStr = cardsPlayed.first;
    final card = PlayingCard.fromString(cardStr);
    
    final tempHand = List<String>.from(player.cards);
    if (!tempHand.remove(cardStr)) return state;

    // 1. 規則邏輯：計算分數與特殊功能
    int newScore = state.currentScore;
    bool newIsReverse = state.isReverse;
    String? nextTargetId;
    bool skipNext = false;

    switch (card.value) {
      case 1: // Ace: +1
        newScore += 1;
        break;
      case 4: // Reverse: 迴轉
        newIsReverse = !newIsReverse;
        break;
      case 5: // Assign: 指定 (payload 中帶 targetPlayerId)
        nextTargetId = payload['targetPlayerId'] as String?;
        break;
      case 10: // +/- 10
        int val = payload['value'] as int? ?? 10;
        newScore += val;
        break;
      case 11: // Jack: Skip 跳過
        skipNext = true;
        break;
      case 12: // Queen: +/- 20
        int val = payload['value'] as int? ?? 20;
        newScore += val;
        break;
      case 13: // King: 直接設為 99
        newScore = 99;
        break;
      default: // 一般牌: 依面值加分
        newScore += card.value;
    }

    // 驗證：如果超過 99 且非可調控牌型導致，則為無效移動 (理論上 UI 會擋)
    if (newScore > 99 || newScore < 0) return state;

    // 2. 抽牌邏輯
    final deck = List<String>.from(state.deckCards);
    final discard = List<String>.from(state.discardCards);
    
    if (deck.isEmpty && discard.isNotEmpty) {
      // 洗牌將棄牌堆補回牌堆
      final newDeck = List<String>.from(discard)..shuffle();
      deck.addAll(newDeck);
      discard.clear();
    }

    if (deck.isNotEmpty) {
      final drawnCard = deck.removeAt(0);
      tempHand.add(drawnCard);
    }

    // 更新玩家手牌
    final newPlayer = player.copyWith(cards: tempHand);
    final newParticipants = List<BigTwoPlayer>.from(state.participants);
    newParticipants[playerIndex] = newPlayer;

    // 3. 計算下一位玩家
    final tempStateForNext = state.copyWith(
      participants: newParticipants,
      isReverse: newIsReverse,
      currentPlayerId: playerId,
    );
    final nextId = _calculateNextPlayerId(tempStateForNext, skip: skipNext, targetId: nextTargetId);

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

  String _calculateNextPlayerId(Poker99State state, {bool skip = false, String? targetId}) {
    final seats = state.seats;
    final currentIndex = seats.indexOf(state.currentPlayerId);
    
    // 處理指定 (Assign)
    if (targetId != null && seats.contains(targetId)) {
      final target = state.participants.firstWhere((p) => p.uid == targetId);
      if (!target.hasPassed) return targetId;
    }

    int step = state.isReverse ? -1 : 1;
    if (skip) step *= 2;

    int nextIdx = (currentIndex + step) % seats.length;
    if (nextIdx < 0) nextIdx += seats.length;

    // 尋找下一個未淘汰玩家
    while (state.participants.firstWhere((p) => p.uid == seats[nextIdx]).hasPassed) {
      nextIdx = (nextIdx + (state.isReverse ? -1 : 1)) % seats.length;
      if (nextIdx < 0) nextIdx += seats.length;
      if (nextIdx == currentIndex) break;
    }
    
    return seats[nextIdx];
  }

  Poker99State _checkEliminationAndWinner(Poker99State state) {
    var currentState = state;
    
    // 檢查當前玩家 (剛輪到的人) 是否還有牌可出
    while (true) {
      final currentPlayer = currentState.participants.firstWhere((p) => p.uid == currentState.currentPlayerId);
      if (currentPlayer.hasPassed) {
         // 已淘汰，跳到下一個 (理論上不會走到這)
         currentState = currentState.copyWith(
           currentPlayerId: _calculateNextPlayerId(currentState),
         );
         continue;
      }

      final playable = getPlayableCards(currentState, currentPlayer.cards.toPlayingCards());
      if (playable.isEmpty) {
        // 淘汰該玩家
        final pIdx = currentState.participants.indexWhere((p) => p.uid == currentState.currentPlayerId);
        final updatedParticipants = List<BigTwoPlayer>.from(currentState.participants);
        updatedParticipants[pIdx] = currentPlayer.copyWith(hasPassed: true);
        
        currentState = currentState.copyWith(participants: updatedParticipants);

        // 檢查是否只剩一人
        final activePlayers = updatedParticipants.where((p) => !p.hasPassed).toList();
        if (activePlayers.length == 1) {
          return currentState.copyWith(winner: activePlayers.first.uid);
        }

        // 切換到下一個未淘汰的人
        currentState = currentState.copyWith(
          currentPlayerId: _calculateNextPlayerId(currentState),
        );
      } else {
        // 有牌可出，停止檢查
        break;
      }
    }

    return currentState;
  }

  /// 獲取玩家手牌中目前可出的卡片 (不會導致總分超過 99)
  List<PlayingCard> getPlayableCards(Poker99State state, List<PlayingCard> handCards) {
    return handCards.where((card) {
      switch (card.value) {
        case 10: // 10 可以減，所以總能出
        case 12: // Q 可以減，所以總能出
        case 4:  // 功能牌點數不變
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
  Poker99State stateFromJson(Map<String, dynamic> json) => Poker99State.fromJson(json);

  @override
  Map<String, dynamic> stateToJson(Poker99State state) => state.toJson();
}
