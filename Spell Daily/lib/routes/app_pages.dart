import 'package:get/get.dart';

import '../screens/app_entry_gate.dart';
import '../screens/game_screen.dart';
import '../screens/login_screen.dart';
import '../screens/result_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/start_game_screen.dart';
import 'app_routes.dart';

/// Central route table for GetX navigation.
///
/// All core dependencies are wired in `AppBindings`, so these pages
/// do not attach additional bindings unless a screen has very specific
/// scoped dependencies.
class AppPages {
  AppPages._();

  static final routes = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.splash, page: SplashScreen.new),
    GetPage(name: AppRoutes.entryGate, page: AppEntryGate.new),
    GetPage(name: AppRoutes.login, page: LoginScreen.new),
    GetPage(name: AppRoutes.startGame, page: StartGameScreen.new),
    GetPage(name: AppRoutes.game, page: GameScreen.new),
    GetPage(name: AppRoutes.result, page: ResultScreen.new),
  ];
}
