import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../services/firestore_service.dart';
import 'auth_controller.dart';
import 'streak_controller.dart';

class GameController extends GetxController {
  final FirestoreService _service = FirestoreService.instance;
  final AuthController _authController = Get.find<AuthController>();
  final StreakController _streakController = Get.find<StreakController>();

  void startGame() {
    final code = _authController.storedLoginCode;
    if (code == null) {
      Get.offAllNamed(Routes.login);
      return;
    }
    Get.toNamed(Routes.webviewGame, arguments: {'loginCode': code});
  }

  Future<void> onWebViewClosed() async {
    final code = _authController.storedLoginCode;
    if (code == null) {
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
}

