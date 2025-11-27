import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../routes/app_routes.dart';
import '../services/firestore_service.dart';

const String kLoginCodeKey = 'loginCode';

class AuthController extends GetxController {
  final FirestoreService _service = FirestoreService.instance;
  final GetStorage _storage = GetStorage();

  final TextEditingController codeController = TextEditingController();
  final RxBool isLoading = false.obs;

  String? get storedLoginCode => _storage.read<String>(kLoginCodeKey);

  @override
  void onInit() {
    super.onInit();
    final saved = storedLoginCode;
    if (saved != null) {
      codeController.text = saved;
    }
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
    try {
      isLoading.value = true;
      await _service.createUserIfNotExists(trimmed);
      await _storage.write(kLoginCodeKey, trimmed);
      Get.offAllNamed(Routes.startGame, arguments: {'loginCode': trimmed});
    } catch (e) {
      Get.snackbar('Login failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

