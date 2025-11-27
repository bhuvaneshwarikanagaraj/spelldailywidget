import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../controllers/game_controller.dart';
import '../controllers/streak_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/streak_widget.dart';

class StartGameScreen extends StatefulWidget {
  const StartGameScreen({super.key});

  @override
  State<StartGameScreen> createState() => _StartGameScreenState();
}

class _StartGameScreenState extends State<StartGameScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final StreakController _streakController = Get.find<StreakController>();
  final GameController _gameController = Get.find<GameController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      final code = args?['loginCode'] ?? _authController.storedLoginCode;
      if (code == null) {
        Get.offAllNamed(Routes.login);
        return;
      }
      _streakController.subscribeToUser(code);
      _streakController.resetStatusIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final scale = width / 375;

          return Container(
            decoration: const BoxDecoration(
              gradient: AppColors.purpleGradient,
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * scale,
                  vertical: 16 * scale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: width * 0.35,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 12 * scale),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 20 * scale),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Ready?',
                                      style: AppTextStyles.hero(width * 0.14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12 * scale),
                                Image.asset(
                                  'assets/images/arrow.png',
                                  height: width * 0.12,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                            SizedBox(height: 20 * scale),
                            Obx(() {
                              return StreakWidget(
                                state: _streakController.widgetState.value,
                                streakCount: _streakController.streak.value,
                                weeklyProgress:
                                    _streakController.getWeeklyProgress(),
                                lastPlayedDate:
                                    _streakController.lastCompletedDate.value,
                                onBegin: () {
                                  Get.offAllNamed(Routes.login);
                                },
                              );
                            }),
                            SizedBox(height: 20 * scale),
                            GestureDetector(
                              onTap: _gameController.startGame,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: 24 * scale,
                                ),
                                decoration: AppTextStyles.buttonDecoration(
                                  background: AppColors.orange,
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Start Game',
                                      style: AppTextStyles.button(
                                        width * 0.09,
                                        color: AppColors.purple,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20 * scale),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}

