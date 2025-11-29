import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../routes/app_routes.dart';
import '../services/firestore_service.dart';
import '../services/widget_state_service.dart';

const String kLoginCodeKey = 'loginCode';

class AuthController extends GetxController {
  final FirestoreService _service = FirestoreService.instance;
  final GetStorage _storage = GetStorage();

  final TextEditingController codeController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxnInt pendingWidgetId = RxnInt();

  String? get storedLoginCode => null; // Never store login code globally

  @override
  void onInit() {
    super.onInit();
    refreshPendingWidgetLink();
  }

  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }

  Future<void> loginWithCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) {
      Get.snackbar('Code required', 'Please type your magic code to enter.');
      return;
    }

    await refreshPendingWidgetLink();
    final widgetId = pendingWidgetId.value;
    if (widgetId != null) {
      await _linkWidget(widgetId: widgetId, loginCode: trimmed);
      return;
    }

    try {
      isLoading.value = true;
      await _service.createUserIfNotExists(trimmed);
      // Do NOT save login code globally - only pass it as argument
      // Navigate to start game with login code in arguments
      Get.offAllNamed(Routes.startGame, arguments: {'loginCode': trimmed});
    } catch (e) {
      Get.snackbar('Login failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPendingWidgetLink() async {
    final prefs = await SharedPreferences.getInstance();
    final widgetId = prefs.getInt(WidgetStateService.pendingWidgetIdKey);
    if (widgetId != null) {
      pendingWidgetId.value = widgetId;
      codeController.clear();
    } else {
      pendingWidgetId.value = null;
    }
  }

  Future<void> _linkWidget({
    required int widgetId,
    required String loginCode,
  }) async {
    try {
      isLoading.value = true;
      await _service.createUserIfNotExists(loginCode);
      await WidgetStateService.instance
          .linkWidgetToLoginCode(widgetId: widgetId, loginCode: loginCode);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(WidgetStateService.pendingWidgetIdKey);
      await prefs.remove('from_widget_begin');

      pendingWidgetId.value = null;
      Get.snackbar(
        'Widget linked',
        'Widget #$widgetId now shows $loginCode.',
      );
    } catch (e) {
      Get.snackbar('Link failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
