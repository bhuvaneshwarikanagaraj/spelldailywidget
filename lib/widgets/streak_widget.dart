import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';
import '../controllers/streak_controller.dart';

class StreakWidget extends StatelessWidget {
  const StreakWidget({
    super.key,
    required this.streak,
    required this.progress,
  });

  final int streak;
  final List<WeeklyProgress> progress;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final tileSize = (width - 80) / 7;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkPurple.withOpacity(0.75),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.white.withOpacity(0.1), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 12),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.center_focus_strong,
                  color: AppColors.purple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$streak DAY${streak == 1 ? '' : 'S'}',
                style: AppTextStyles.button(width * 0.06),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: progress
                .map(
                  (day) => _WeeklyTile(
                    label: day.label,
                    completed: day.completed,
                    size: tileSize,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _WeeklyTile extends StatelessWidget {
  const _WeeklyTile({
    required this.label,
    required this.completed,
    required this.size,
  });

  final String label;
  final bool completed;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.successGreen,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Image.asset(
          'assets/images/tick.jpg',
          width: size * 0.6,
          height: size * 0.6,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.check,
            color: AppColors.white,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.lightPurple.withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.label(size * 0.3),
      ),
    );
  }
}

