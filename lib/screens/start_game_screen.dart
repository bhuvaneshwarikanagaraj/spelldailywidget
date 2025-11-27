import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app_colors.dart';
import '../controllers/auth_controller.dart';
import '../controllers/streak_controller.dart';
import '../routes/app_routes.dart';

class StartGameScreen extends StatefulWidget {
  const StartGameScreen({super.key});

  @override
  State<StartGameScreen> createState() => _StartGameScreenState();
}

class _StartGameScreenState extends State<StartGameScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final StreakController _streakController = Get.find<StreakController>();

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
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: width * 0.35,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}

