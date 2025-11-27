import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app_colors.dart';
import 'controllers/auth_controller.dart';
import 'controllers/game_controller.dart';
import 'controllers/streak_controller.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init();
  
  runApp(const MyApp());
}

class InitialBinding extends Bindings {
  InitialBinding();

  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<StreakController>(StreakController(), permanent: true);
    Get.put<GameController>(GameController(), permanent: true);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Check for widget launch after the app initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleWidgetLaunch();
    });
  }

  Future<void> _handleWidgetLaunch() async {
    try {
      const platform = MethodChannel('com.company.spelldaily/navigation');
      final dynamic result = await platform.invokeMethod('getInitialArguments');
      if (result is Map && result['route'] != null) {
        final route = result['route'] as String;
        if (route == Routes.webviewGame) {
          // Navigate directly to webview game
          final loginCode = result['loginCode'] as String?;
          Get.offAllNamed(
            Routes.webviewGame,
            arguments: loginCode != null ? {'loginCode': loginCode} : null,
          );
        }
      }
    } catch (e) {
      // Widget navigation not available or failed, continue with normal flow
      debugPrint('Widget navigation check: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Spell Daily',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      initialRoute: Routes.login,
      getPages: AppPages.pages,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.purple,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.purple,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.purple,
          primary: AppColors.purple,
          secondary: AppColors.orange,
          brightness: Brightness.dark,
        ),
        useMaterial3: false,
      ),
    );
  }
}

