import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/game_controller.dart';
import '../controllers/streak_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/streak_widget.dart';

/// Start screen shown after login.
///
/// - Highlights the current streak.
/// - Provides a single primary CTA to launch today's game.
class StartGameScreen extends StatelessWidget {
  const StartGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameController = Get.find<GameController>();
    final streakController = Get.find<StreakController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Today\'s Game', style: AppTextStyles.headline),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Keep your streak alive by completing today\'s game.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),
            Obx(
              () => StreakWidget(
                loginCode: streakController.loginCode ?? '--',
                streak: streakController.streak.value,
                lastCompletedDate: streakController.lastCompletedDate.value,
                state: _mapToWidgetState(streakController),
              ),
            ),
            const Spacer(),
            Obx(
              () => ElevatedButton(
                onPressed: gameController.isGameActive.value
                    ? null
                    : gameController.startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text('START GAME', style: AppTextStyles.buttonStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  StreakWidgetState _mapToWidgetState(StreakController controller) {
    if (controller.todayStatus.value == 'completed' &&
        controller.lastCompletedDate.value ==
            controller
                .lastCompletedDate.value) // simplified; full logic in controller
    {
      return StreakWidgetState.completed;
    }
    return StreakWidgetState.pending;
  }
}


