import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class AppEntryGate extends StatelessWidget {
  const AppEntryGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome to', style: AppTextStyles.headline),
            Text('Spell Daily — Lite', style: AppTextStyles.logoStyle),
            const SizedBox(height: 24),
            Text(
              'Launch the lite experience. Enter your login code to track streaks.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Get.toNamed(AppRoutes.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                minimumSize: const Size.fromHeight(56),
              ),
              child: Text('Enter Login Code', style: AppTextStyles.buttonStyle),
            ),
          ],
        ),
      ),
    );
  }
}
