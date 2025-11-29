import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes/app_routes.dart';
import '../services/firestore_service.dart';
import 'auth_controller.dart';
import 'streak_controller.dart';

class GameController extends GetxController {
  final FirestoreService _service = FirestoreService.instance;
  final AuthController _authController = Get.find<AuthController>();
  final StreakController _streakController = Get.find<StreakController>();

  Future<void> startGame({String? loginCode}) async {
    final code = loginCode ?? _authController.storedLoginCode;
    if (code == null || code.isEmpty) {
      Get.offAllNamed(Routes.login);
      return;
    }
    
    final url = 'https://app.spelldaily.com/?code=$code';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not launch browser');
    }
  }

  /// Checks game completion status and navigates to result screen.
  /// 
  /// This can be called manually to check if the game was completed
  /// after opening it in the external browser.
  Future<void> checkGameCompletion({String? loginCode}) async {
    final code = loginCode ?? _authController.storedLoginCode;
    if (code == null || code.isEmpty) {
      Get.offAllNamed(Routes.login);
      return;
    }

    final snapshot = await _service.getUser(code);
    final data = snapshot.data() ?? {};
    final success = (data['todayStatus'] ?? 'pending') == 'completed';
    if (success) {
      await _streakController.updateStreakAfterCompletion();
    }
    Get.offAllNamed(Routes.result, arguments: {'success': success});
  }

  @Deprecated('Use checkGameCompletion() instead. This method is kept for backward compatibility.')
  Future<void> onWebViewClosed() async {
    return checkGameCompletion();
  }
}

