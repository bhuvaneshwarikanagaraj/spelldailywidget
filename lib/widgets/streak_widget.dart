import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';
import '../models/streak_widget_state.dart';
import '../models/weekly_progress.dart';

class StreakWidget extends StatelessWidget {
  const StreakWidget({
    super.key,
    required this.state,
    required this.streakCount,
    required this.weeklyProgress,
    required this.lastPlayedDate,
    required this.onBegin,
  });

  final StreakWidgetState state;
  final int streakCount;
  final List<WeeklyProgress> weeklyProgress;
  final String lastPlayedDate;
  final VoidCallback onBegin;

  static const _quotes = [
    'Momentum is on your side. Come back tomorrow!',
    'You already locked in today—rest, recover, repeat.',
    'Legends are made one day at a time. See you tonight!',
    'Keep the flame alive. Tomorrow’s challenge awaits.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C0F9B), Color(0xFF2A0054)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 10),
            blurRadius: 30,
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildStateContent(),
      ),
    );
  }

  Widget _buildStateContent() {
    switch (state) {
      case StreakWidgetState.startChallenge:
        return _StartChallengeView(onBegin: onBegin);
      case StreakWidgetState.justCompleted:
        return _CelebrationView(
          streakCount: streakCount,
          weeklyProgress: weeklyProgress,
        );
      case StreakWidgetState.completedToday:
        return _CompletedTodayView(
          streakCount: streakCount,
          quote: _quotes[streakCount % _quotes.length],
        );
      case StreakWidgetState.awaitingToday:
        return _AwaitingTodayView(
          streakCount: streakCount,
          weeklyProgress: weeklyProgress,
          lastPlayedDate: lastPlayedDate,
        );
    }
  }
}

class _StartChallengeView extends StatelessWidget {
  const _StartChallengeView({required this.onBegin});

  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('start'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start Challenge',
          style: AppTextStyles.hero(28),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap begin to enter your code and start building a streak.',
          style: AppTextStyles.body(16),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onBegin,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: AppTextStyles.buttonDecoration(
              background: AppColors.orange,
            ),
            child: Center(
              child: Text(
                'Begin',
                style: AppTextStyles.button(20, color: AppColors.purple),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CelebrationView extends StatelessWidget {
  const _CelebrationView({
    required this.streakCount,
    required this.weeklyProgress,
  });

  final int streakCount;
  final List<WeeklyProgress> weeklyProgress;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('celebration'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔥 $streakCount-Day Streak',
          style: AppTextStyles.hero(28),
        ),
        const SizedBox(height: 12),
        Text(
          'Today is locked in. Enjoy the glow and keep the momentum.',
          style: AppTextStyles.body(16),
        ),
        const SizedBox(height: 20),
        _WeeklyProgressRow(weeklyProgress: weeklyProgress),
      ],
    );
  }
}

class _CompletedTodayView extends StatelessWidget {
  const _CompletedTodayView({
    required this.streakCount,
    required this.quote,
  });

  final int streakCount;
  final String quote;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('completed'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$streakCount-Day Streak secured',
          style: AppTextStyles.hero(26),
        ),
        const SizedBox(height: 12),
        Text(
          quote,
          style: AppTextStyles.body(16),
        ),
      ],
    );
  }
}

class _AwaitingTodayView extends StatelessWidget {
  const _AwaitingTodayView({
    required this.streakCount,
    required this.weeklyProgress,
    required this.lastPlayedDate,
  });

  final int streakCount;
  final List<WeeklyProgress> weeklyProgress;
  final String lastPlayedDate;

  @override
  Widget build(BuildContext context) {
    final labelDate = lastPlayedDate.isEmpty ? 'yesterday' : lastPlayedDate;
    return Column(
      key: const ValueKey('awaiting'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keep it going',
          style: AppTextStyles.hero(28),
        ),
        const SizedBox(height: 6),
        Text(
          '$labelDate is locked 🔒. Start today to push it to ${streakCount + 1}.',
          style: AppTextStyles.body(16),
        ),
        const SizedBox(height: 20),
        _WeeklyProgressRow(weeklyProgress: weeklyProgress),
      ],
    );
  }
}

class _WeeklyProgressRow extends StatelessWidget {
  const _WeeklyProgressRow({required this.weeklyProgress});

  final List<WeeklyProgress> weeklyProgress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weeklyProgress
          .map(
            (day) => _WeekDayBubble(progress: day),
          )
          .toList(),
    );
  }
}

class _WeekDayBubble extends StatelessWidget {
  const _WeekDayBubble({required this.progress});

  final WeeklyProgress progress;

  @override
  Widget build(BuildContext context) {
    final size = 38.0;
    final background = progress.completed
        ? AppColors.orange
        : AppColors.white.withOpacity(progress.isToday ? 0.25 : 0.08);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(
              color: progress.isToday ? AppColors.white : Colors.transparent,
              width: progress.isToday ? 2 : 0,
            ),
          ),
          alignment: Alignment.center,
          child: progress.completed
              ? const Icon(Icons.check, color: AppColors.purple, size: 20)
              : Text(
                  progress.label.isEmpty
                      ? ''
                      : progress.label.substring(0, 1),
                  style: AppTextStyles.label(14),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          progress.label,
          style: AppTextStyles.label(
            12,
            color: AppColors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

