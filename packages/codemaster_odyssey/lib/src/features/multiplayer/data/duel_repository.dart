import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [DuelRepository] instance.
final duelProvider = NotifierProvider<DuelRepository, DuelState>(
  DuelRepository.new,
);

/// Repository responsible for managing real-time code duels between users.
class DuelRepository extends Notifier<DuelState> {
  @override
  DuelState build() {
    return const DuelState(status: DuelStatus.finished); // Default to idle
  }

  /// Starts searching for an opponent for a code duel.
  void startSearch() {
    state = state.copyWith(status: DuelStatus.searching);
    Future.delayed(const Duration(seconds: 3), () {
      state = state.copyWith(
        status: DuelStatus.starting,
        opponentName: 'Dark Apprentice X',
      );
    });
  }

  /// Updates the scores for the [player] and their opponent.
  void updateScores(int player, int opponent) {
    state = state.copyWith(playerScore: player, opponentScore: opponent);
  }
}

/// Represents the current state of a code duel.
class DuelState {
  /// The current status of the duel.
  final DuelStatus status;

  /// The name of the opponent, if matched.
  final String? opponentName;

  /// The current score of the local player.
  final int playerScore;

  /// The current score of the opponent.
  final int opponentScore;

  /// The remaining time in seconds for the duel.
  final int timeLeft;

  /// Creates a [DuelState] instance.
  const DuelState({
    required this.status,
    this.opponentName,
    this.playerScore = 0,
    this.opponentScore = 0,
    this.timeLeft = 60,
  });

  /// Creates a copy of this [DuelState] with the given fields replaced by new values.
  DuelState copyWith({
    DuelStatus? status,
    String? opponentName,
    int? playerScore,
    int? opponentScore,
    int? timeLeft,
  }) {
    return DuelState(
      status: status ?? this.status,
      opponentName: opponentName ?? this.opponentName,
      playerScore: playerScore ?? this.playerScore,
      opponentScore: opponentScore ?? this.opponentScore,
      timeLeft: timeLeft ?? this.timeLeft,
    );
  }
}

/// Status of a code duel session.
enum DuelStatus {
  /// The system is currently searching for an available opponent.
  searching,

  /// An opponent has been found and the duel is about to start.
  starting,

  /// The duel is currently active.
  ongoing,

  /// The duel has completed.
  finished,
}
