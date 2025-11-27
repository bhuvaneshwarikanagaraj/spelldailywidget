import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app_bindings.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'utils/app_colors.dart';
import 'utils/app_text_styles.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init();
  runApp(const SpellDailyLiteApp());
}

class SpellDailyLiteApp extends StatelessWidget {
  const SpellDailyLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Spell Daily — Lite',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      initialBinding: AppBindings(),
      getPages: AppPages.routes,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryPurple),
        textTheme: TextTheme(
          displayLarge: AppTextStyles.logoStyle,
          bodyMedium: AppTextStyles.body,
        ),
      ),
    );
  }
}
