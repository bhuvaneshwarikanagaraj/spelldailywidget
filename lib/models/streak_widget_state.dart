enum StreakWidgetState {
  /// Widget has not been linked with a login code yet.
  unlinked,

  /// New user or streak reset (Start Challenge)
  startChallenge,

  /// Just completed today's game (celebration view)
  justCompleted,

  /// Same day after completion (motivation view)
  completedToday,

  /// Next day of an active streak before playing (pending)
  awaitingToday,
}



