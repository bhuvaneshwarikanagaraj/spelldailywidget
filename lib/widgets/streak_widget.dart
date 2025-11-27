import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';

/// Visual states for the streak widget.
///
/// These map to the Figma variants 1–4:
/// - pending   → "Complete today's game"
/// - inProgress → "Playing now"
/// - completed → "Game Completed"
/// - reminder  → "Come back at midnight"
enum StreakWidgetState { pending, inProgress, completed, reminder }

/// Reusable streak card widget.
///
/// This is intentionally self-contained so it can be reused both in-app
/// and inside a future multi-user homescreen widget.
class StreakWidget extends StatelessWidget {
  const StreakWidget({
    super.key,
    required this.loginCode,
    required this.streak,
    required this.lastCompletedDate,
    required this.state,
  });

  final String loginCode;
  final int streak;
  final String lastCompletedDate;
  final StreakWidgetState state;

  Color get _stateColor => switch (state) {
        StreakWidgetState.completed => AppColors.orange,
        StreakWidgetState.inProgress => AppColors.purple,
        StreakWidgetState.reminder => AppColors.darkPurple,
        StreakWidgetState.pending => AppColors.lightPurple,
      };

  String get _stateLabel => switch (state) {
        StreakWidgetState.completed => 'Game Completed',
        StreakWidgetState.inProgress => 'Playing now',
        StreakWidgetState.reminder => 'Come back at midnight',
        StreakWidgetState.pending => 'Complete today\'s game',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkPurple.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _stateColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Code: $loginCode', style: AppTextStyles.body(16)),
          const SizedBox(height: 8),
          Text('Streak: $streak days', style: AppTextStyles.hero(24)),
          const SizedBox(height: 8),
          Text(
            lastCompletedDate.isEmpty
                ? 'Last completion: —'
                : 'Last completion: $lastCompletedDate',
            style: AppTextStyles.body(16),
          ),
          const SizedBox(height: 12),
          Chip(
            backgroundColor: _stateColor,
            label: Text(
              _stateLabel,
              style: AppTextStyles.button(14),
            ),
          ),
        ],
      ),
    );
  }
}

