import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../controllers/game_controller.dart';
import '../routes/app_routes.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user already has a stored login code and navigate accordingly
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final code = controller.storedLoginCode;
      if (code != null && code.isNotEmpty) {
        // Check if launched from widget BEGIN button (read from SharedPreferences directly)
        final prefs = await SharedPreferences.getInstance();
        final fromWidgetBegin = prefs.getBool('flutter.from_widget_begin') ?? false;
        
        // Clear the flag after reading
        if (fromWidgetBegin) {
          await prefs.remove('flutter.from_widget_begin');
          // If from widget and logged in, open browser directly
          final gameController = Get.find<GameController>();
          await gameController.startGame();
          // Stay on login screen as browser is opened externally
        } else {
          // Normal flow: go to start game page
          Get.offAllNamed(Routes.startGame, arguments: {'loginCode': code});
        }
      }
    });
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final spacing = width * 0.08;
          final inputHeight = 64.0 + (width - 320).clamp(0, 80) * 0.2;

          return Stack(
            children: [
              Container(color: AppColors.purple),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: height * 0.55,
                child: ClipPath(
                  clipper: _SineWaveClipper(
                    amplitude: height * 0.06,
                    waves: 1.5,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.orangeWave,
                    ),
                  ),
                ),
              ),
              // Top section (Purple) - Logo and Login text
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: height * 0.45,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing,
                      vertical: height * 0.04,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: width * 0.45,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: height * 0.02),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Login',
                              style: AppTextStyles.hero(width * 0.1),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom section (Orange) - Type code, input, and button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: height * 0.55,
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing,
                        vertical: height * 0.04,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: height * 0.02),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Type code',
                              style: AppTextStyles.hero(width * 0.12).copyWith(
                                color: AppColors.purple,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: height * 0.03),
                          Container(
                            height: inputHeight,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: TextField(
                              controller: controller.codeController,
                              textCapitalization: TextCapitalization.characters,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.label(
                                width * 0.08,
                                color: AppColors.purple,
                              ).copyWith(letterSpacing: 12),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'ARU123',
                                hintStyle: TextStyle(
                                  color: AppColors.lightPurple,
                                  letterSpacing: 8,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.03),
                          Obx(
                            () => GestureDetector(
                              onTap: controller.isLoading.value
                                  ? null
                                  : () => controller.loginWithCode(
                                      controller.codeController.text),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: width * 0.06,
                                ),
                                decoration: AppTextStyles.buttonDecoration(
                                  background: AppColors.purple,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          controller.isLoading.value
                                              ? 'Loading...'
                                              : 'Get In',
                                          style: AppTextStyles.button(width * 0.07),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: width * 0.04),
                                    Image.asset(
                                      'assets/images/arrow.png',
                                      height: width * 0.07,
                                      color: AppColors.orange,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SineWaveClipper extends CustomClipper<Path> {
  _SineWaveClipper({
    required this.amplitude,
    this.waves = 1.5,
  });

  final double amplitude;
  final double waves;

  @override
  Path getClip(Size size) {
    final path = Path();
    final step = size.width / 40;

    path.moveTo(0, amplitude);
    for (double x = 0; x <= size.width; x += step) {
      final normalized = x / size.width;
      final y = amplitude +
          amplitude *
              math.sin(normalized * waves * 2 * math.pi);
      path.lineTo(x, y.clamp(0.0, size.height));
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

