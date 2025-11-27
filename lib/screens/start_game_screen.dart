import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../controllers/game_controller.dart';
import '../routes/app_routes.dart';
import '../services/widget_state_service.dart';

class StartGameScreen extends StatelessWidget {
  const StartGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameController = Get.find<GameController>();
    final authController = Get.find<AuthController>();

    // Check if user is logged in, if not navigate to login
    // Also check if launched from widget BEGIN button
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final code = authController.storedLoginCode;
      if (code == null || code.isEmpty) {
        Get.offAllNamed(Routes.login);
        return;
      }

      // Check if launched from widget BEGIN button (read from SharedPreferences directly)
      final prefs = await SharedPreferences.getInstance();
      final pendingWidgetId =
          prefs.getInt(WidgetStateService.pendingWidgetIdKey);
      if (pendingWidgetId != null) {
        await prefs.remove('flutter.from_widget_begin');
        Get.offAllNamed(Routes.login);
        return;
      }
      final fromWidgetBegin =
          prefs.getBool('flutter.from_widget_begin') ?? false;

      // Clear the flag after reading
      if (fromWidgetBegin) {
        await prefs.remove('flutter.from_widget_begin');
        // If from widget and logged in, open browser directly
        await gameController.startGame();
        // Stay on start game screen as browser is opened externally
      }
    });

    return Scaffold(
      backgroundColor: AppColors.purple,
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: height * 0.1),
                    // Centered logo
                    Image.asset(
                      'assets/images/logo.png',
                      width: width * 0.6,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: height * 0.15),
                    // Start Game button
                    GestureDetector(
                      onTap: () => gameController.startGame(),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: width * 0.06,
                        ),
                        decoration: AppTextStyles.buttonDecoration(
                          background: AppColors.orange,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Start Game',
                                  style: AppTextStyles.button(width * 0.07),
                                ),
                              ),
                            ),
                            SizedBox(width: width * 0.04),
                            Image.asset(
                              'assets/images/arrow.png',
                              height: width * 0.07,
                              color: AppColors.purple,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.1),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
