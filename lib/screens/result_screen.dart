import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final success = args?['success'] ?? false;

    return success ? _SuccessView(onContinue: _goHome) : _FailureView(onRetry: _tryAgain);
  }

  void _goHome() {
    Get.offAllNamed(Routes.startGame);
  }

  void _tryAgain() {
    // Navigate directly to webview game to try again
    final authController = Get.find<AuthController>();
    final loginCode = authController.storedLoginCode;
    if (loginCode != null) {
      Get.offAllNamed(Routes.webviewGame, arguments: {'loginCode': loginCode});
    } else {
      Get.offAllNamed(Routes.login);
    }
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = width / 375;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            final children = [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      color: AppColors.purple,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(24 * scale),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: constraints.maxHeight * 0.05),
                              Flexible(
                                child: Image.asset(
                                  'assets/images/start_game.png',
                                  height: constraints.maxHeight * 0.35,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(height: 20 * scale),
                              ElevatedButton(
                                onPressed: onContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.orange,
                                  foregroundColor: AppColors.purple,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 18 * scale,
                                    horizontal: 32 * scale,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Play Tomorrow',
                                    style: AppTextStyles.button(width * 0.05,
                                        color: AppColors.purple),
                                  ),
                                ),
                              ),
                              SizedBox(height: constraints.maxHeight * 0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isCompact)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: constraints.maxHeight * 0.1,
                        child: ClipPath(
                          clipper: _HorizontalWaveClipper(),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: AppColors.orangeWave,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      color: AppColors.orange,
                      padding: EdgeInsets.all(24 * scale),
                      child: Center(
                        child: SingleChildScrollView(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Did you just do that?!\nUnbelievable work!',
                              style: AppTextStyles.hero(width * 0.09)
                                  .copyWith(color: AppColors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!isCompact)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: constraints.maxWidth * 0.1,
                        child: ClipPath(
                          clipper: _VerticalWaveClipper(),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.purple, AppColors.darkPurple],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ];

            return isCompact
                ? Column(children: children)
                : Row(children: children);
          },
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.purple,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Game not completed yet',
                    style: AppTextStyles.hero(width * 0.09),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    width: double.infinity,
                    decoration: AppTextStyles.buttonDecoration(
                      background: AppColors.orange,
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Try Again',
                          style: AppTextStyles.button(width * 0.07,
                              color: AppColors.purple),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final waveHeight = size.height * 0.15;
    final startY = 0.0; // Top of the orange section
    
    // Start from top-left
    path.moveTo(0, startY);
    
    // Create horizontal wave pattern at the top of orange section (matching login screen style)
    path.quadraticBezierTo(
      size.width * 0.25,
      startY + waveHeight,
      size.width * 0.5,
      startY,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      startY - waveHeight * 0.5,
      size.width,
      startY + waveHeight * 0.3,
    );
    
    // Complete the path to cover the entire orange section
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _VerticalWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final waveWidth = size.width * 0.15;
    final startX = 0.0; // Left edge of the orange section
    
    // Start from top-left
    path.moveTo(startX, 0);
    
    // Create vertical wave pattern at the left edge of orange section (horizontal wave rotated 90 degrees)
    path.quadraticBezierTo(
      startX + waveWidth,
      size.height * 0.25,
      startX,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      startX - waveWidth * 0.5,
      size.height * 0.75,
      startX + waveWidth * 0.3,
      size.height,
    );
    
    // Complete the path
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

