import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../services/widget_update_service.dart';
import 'streak_controller.dart';

/// Orchestrates the WebView play session and result transitions.
///
/// Responsibilities:
/// - navigate to the in-app WebView with the correct query string
/// - when user closes the WebView, re-check Firestore and decide whether
///   the game is marked as completed for today
/// - if completed, forward to Result screen and trigger streak + widget updates
class GameController extends GetxController {
  GameController(this._streakController, this._widgetUpdateService);

  final StreakController _streakController;
  final WidgetUpdateService _widgetUpdateService;

  /// True while the game WebView is on screen.
  final RxBool isGameActive = false.obs;

  /// Launches the in-app WebView screen.
  ///
  /// The WebView itself constructs the URL as:
  /// `https://app.spelldaily.com/?code={loginCode}`.
  void startGame() {
    if (_streakController.loginCode == null) {
      Get.snackbar('Login required', 'Please enter your code first.');
      return;
    }
    try {
      isGameActive.value = true;
      Get.toNamed(AppRoutes.game);
    } catch (e) {
      isGameActive.value = false;
      Get.snackbar('Error', 'Failed to open game: ${e.toString()}');
    }
  }

  /// Called when the WebView screen is popped (e.g., back gesture).
  ///
  /// Flow:
  /// 1. Re-reads `users/{loginCode}` from Firestore.
  /// 2. If `todayStatus == "completed"` and `lastCompletedDate == today`,
  ///    increments streak via `StreakController.updateStreakIfCompleted()`.
  /// 3. Schedules a one-off background widget refresh in ~10 minutes.
  /// 4. Navigates to the Result screen with success/failure flag.
  Future<void> onWebViewClosed() async {
    isGameActive.value = false;
    final completed = await _streakController.checkTodayStatus();
    if (completed) {
      await _streakController.updateStreakIfCompleted();
      await _widgetUpdateService.scheduleDelayedRefresh(
        const Duration(minutes: 10),
      );
      Get.offAllNamed(AppRoutes.result, arguments: {'success': true});
    } else {
      Get.offAllNamed(AppRoutes.result, arguments: {'success': false});
    }
  }
}
