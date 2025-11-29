import 'package:get/get.dart';

import '../controllers/widget_admin_controller.dart';
import '../screens/login_screen.dart';
import '../screens/result_screen.dart';
import '../screens/start_game_screen.dart';
import '../screens/widget_admin_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: Routes.startGame,
      page: () => const StartGameScreen(),
    ),
    GetPage(
      name: Routes.result,
      page: () => const ResultScreen(),
    ),
    GetPage(
      name: Routes.widgetAdmin,
      page: () => const WidgetAdminScreen(),
      binding: BindingsBuilder.put(() => WidgetAdminController()),
    ),
  ];
}

