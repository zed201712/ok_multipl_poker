import 'package:ok_multipl_poker/entities/big_two_player.dart';
import 'package:ok_multipl_poker/entities/poker_99_state.dart';
import 'package:ok_multipl_poker/entities/room.dart';
import 'package:ok_multipl_poker/game_internals/playing_card.dart';
import 'package:ok_multipl_poker/multiplayer/turn_based_game_delegate.dart';
import 'package:ok_multipl_poker/services/error_message_service.dart';
import 'big_two_deck_utils_mixin.dart';
import 'package:collection/collection.dart';

// 暫時沿用 BigTwoDeckUtilsMixin，後續若有需要可建立 Poker99DeckUtilsMixin
class Poker99Delegate extends TurnBasedGameDelegate<Poker99State> with BigTwoDeckUtilsMixin {
  ErrorMessageService? _errorMessageService;

  @override
  Poker99State initializeGame(Room room) {
    final deck = PlayingCard.createDeck();
    final players = <BigTwoPlayer>[];
    var seats = List<String>.from(room.seats);
    seats = room.randomizeSeats ? (seats..shuffle()) : seats;

    // Add Virtual Player
    if (seats.length <= 2) {
      final virtualPlayerCount = 4 - seats.length; // Poker 99 通常 4 人
      final virtualPlayers = Iterable.generate(virtualPlayerCount, (i) => i + 1)
          .map((i) => "virtual_player$i");
      seats.addAll(virtualPlayers);
    }

    // Poker 99 初始手牌每人 5 張
    final cardsPerPlayer = 5;
    
    // Create initial players with cards
    for (int i = 0; i < seats.length; i++) {
      final uid = seats[i];
      final isVirtual = uid.startsWith('virtual_player');
      final hand = deck.sublist(i * cardsPerPlayer, (i + 1) * cardsPerPlayer);
      
      String name;
      int avatarNumber;
      if (isVirtual) {
        name = uid;
        avatarNumber = room.participants.first.avatarNumber;
      } else {
        final participant = room.participants.firstWhere((p) => p.id == seats[i]);
        name = participant.name;
        avatarNumber = participant.avatarNumber;
      }

      players.add(BigTwoPlayer(
        uid: uid,
        name: name,
        cards: hand.map(PlayingCard.cardToString).toList(),
        hasPassed: isVirtual,
        isVirtualPlayer: isVirtual,
        avatarNumber: avatarNumber,
      ));
    }
    
    // 剩餘牌作為牌堆
    final deckStartIndex = seats.length * cardsPerPlayer;
    final remainingDeck = deck.sublist(deckStartIndex).map(PlayingCard.cardToString).toList();

    return Poker99State(
      participants: players,
      seats: seats,
      currentPlayerId: seats.first, // 簡單預設第一位為起始玩家
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
    
    // 0. 基礎檢查
    if (currentState.winner != null && actionName != 'request_restart') return currentState;

    // 1. 處理重開局
    if (actionName == 'request_restart') {
      return _processRestartRequest(room, currentState, participantId);
    }

    // 2. 輪次檢查
    if (currentState.currentPlayerId != participantId) return currentState;

    // 3. 分派動作
    if (actionName == 'play_cards') {
      final cardsStr = List<String>.from(payload['cards'] ?? []);
      return _playCards(currentState, participantId, cardsStr);
    } else if (actionName == 'pass_turn') {
      // Poker 99 通常不能 Pass，除非淘汰，這裡暫時保留
      return _passTurn(currentState, participantId);
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

  Poker99State _playCards(Poker99State state, String playerId, List<String> cardsPlayed) {
    // 1. Validate
    final playerIndex = state.participants.indexWhere((p) => p.uid == playerId);
    if (playerIndex == -1) return state;
    final player = state.participants[playerIndex];
    
    // Check if player has the cards
    final tempHand = List<String>.from(player.cards);
    if (cardsPlayed.isEmpty) return state;
    final cardToPlay = cardsPlayed.first; // Poker 99 一次出一張
    if (!tempHand.remove(cardToPlay)) return state;

    // 2. Logic (TODO: Implement Value Calculation)
    // 暫時僅移除手牌並抽一張牌
    
    // Draw Card logic
    final deck = List<String>.from(state.deckCards);
    String? drawnCard;
    if (deck.isNotEmpty) {
      drawnCard = deck.removeAt(0); // Draw from top
      tempHand.add(drawnCard);
    }

    final newPlayer = player.copyWith(cards: tempHand);
    final newParticipants = List<BigTwoPlayer>.from(state.participants);
    newParticipants[playerIndex] = newPlayer;

    // Update State
    // TODO: Update currentScore based on cardToPlay
    // TODO: Check if busted (score > 99) -> elimination

    return state.copyWith(
      participants: newParticipants,
      deckCards: deck,
      lastPlayedHand: [cardToPlay],
      lastPlayedById: playerId,
      currentPlayerId: state.nextPlayerId() ?? state.seats.first,
    );
  }

  Poker99State _passTurn(Poker99State state, String playerId) {
    // Poker 99 通常不允許 Pass，此處為暫時實作以防卡住
    return state.copyWith(
       currentPlayerId: state.nextPlayerId() ?? state.seats.first,
    );
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
