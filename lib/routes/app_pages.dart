import 'package:get/get.dart';

import '../screens/login_screen.dart';
import '../screens/result_screen.dart';
import '../screens/start_game_screen.dart';
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
  ];
}

