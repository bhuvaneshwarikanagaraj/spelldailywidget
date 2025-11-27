import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final code = _authController.loginCode;
    if (code != null && code.isNotEmpty) {
      Get.offAllNamed(AppRoutes.startGame);
    } else {
      Get.offAllNamed(AppRoutes.entryGate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 140, height: 140),
            const SizedBox(height: 24),
            Text('Spell Daily — Lite', style: AppTextStyles.logoStyle),
            const SizedBox(height: 12),
            const CircularProgressIndicator(color: AppColors.orange),
          ],
        ),
      ),
    );
  }
}
