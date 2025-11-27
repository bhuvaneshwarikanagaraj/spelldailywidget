import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';
import '../routes/app_routes.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final success = args?['success'] ?? false;

    return success ? _SuccessView(onContinue: _goHome) : _FailureView(onRetry: _goHome);
  }

  void _goHome() {
    Get.offAllNamed(Routes.startGame);
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
                child: Container(
                  color: AppColors.purple,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/start_game.png',
                        height: constraints.maxHeight * 0.4,
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
                        child: Text(
                          'Play Tomorrow',
                          style: AppTextStyles.button(width * 0.05,
                              color: AppColors.purple),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: AppColors.orange,
                  padding: EdgeInsets.all(24 * scale),
                  child: Center(
                    child: Text(
                      'Did you just do that?!\nUnbelievable work!',
                      style: AppTextStyles.hero(width * 0.09)
                          .copyWith(color: AppColors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Game not completed yet',
                style: AppTextStyles.hero(width * 0.09),
                textAlign: TextAlign.center,
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
                    child: Text(
                      'Try Again',
                      style: AppTextStyles.button(width * 0.07,
                          color: AppColors.purple),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

