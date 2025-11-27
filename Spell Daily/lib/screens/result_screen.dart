import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

/// Result screen shown after the WebView is closed and Firestore is checked.
///
/// Expects a `bool success` flag in `Get.arguments`.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final bool success = args['success'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              size: 96,
              color: success ? AppColors.orange : AppColors.textLightPurple,
            ),
            const SizedBox(height: 24),
            Text(
              success ? 'Nice work!' : 'Not yet completed',
              style: AppTextStyles.headline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              success
                  ? 'Your streak has been updated. See you again tomorrow.'
                  : 'We couldn\'t confirm today\'s completion. Try again to keep your streak alive.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Get.offAllNamed(AppRoutes.startGame);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                minimumSize: const Size.fromHeight(56),
              ),
              child: Text(
                success ? 'Back to Home' : 'Try Again',
                style: AppTextStyles.buttonStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


