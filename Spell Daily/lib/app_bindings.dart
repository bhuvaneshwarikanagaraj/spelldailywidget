import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'controllers/auth_controller.dart';
import 'controllers/game_controller.dart';
import 'controllers/streak_controller.dart';
import 'services/firestore_service.dart';
import 'services/widget_update_service.dart';

/// Global dependency graph for Spell Daily — Lite.
///
/// This is executed once in `main.dart` and provides:
/// - a singleton `FirebaseFirestore` instance
/// - a singleton `GetStorage` instance for local persistence
/// - app-level services (`FirestoreService`, `WidgetUpdateService`)
/// - feature controllers (`AuthController`, `StreakController`, `GameController`)
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Core singletons
    Get.put<FirebaseFirestore>(FirebaseFirestore.instance, permanent: true);
    Get.put<GetStorage>(GetStorage(), permanent: true);

    // Services
    Get.put<FirestoreService>(
      FirestoreService(Get.find<FirebaseFirestore>()),
      permanent: true,
    );
    Get.put<WidgetUpdateService>(
      WidgetUpdateService(),
      permanent: true,
    );

    // Controllers
    Get.put<AuthController>(
      AuthController(Get.find<FirestoreService>(), Get.find<GetStorage>()),
      permanent: true,
    );
    Get.put<StreakController>(
      StreakController(Get.find<FirestoreService>()),
      permanent: true,
    );
    Get.put<GameController>(
      GameController(Get.find<StreakController>(), Get.find<WidgetUpdateService>()),
      permanent: true,
    );

    // Kick off background/widget infrastructure (no-op on unsupported platforms).
    Get.find<WidgetUpdateService>().init();
  }
}
