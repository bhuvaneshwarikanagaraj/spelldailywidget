import 'dart:async';

import 'package:get/get.dart';

import '../models/streak_widget_state.dart';
import '../models/widget_instance.dart';
import '../services/widget_state_service.dart';

class WidgetAdminController extends GetxController {
  WidgetAdminController();

  final WidgetStateService _service = WidgetStateService.instance;

  final RxList<WidgetInstance> widgetInstances = <WidgetInstance>[].obs;
  final RxBool isLoading = false.obs;

  StreamSubscription<List<WidgetInstance>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscription = _service.widgetInstancesStream.listen((instances) {
      widgetInstances.assignAll(instances);
    });
    refreshInstances();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  Future<void> refreshInstances() async {
    try {
      isLoading.value = true;
      final latest = await _service.listWidgetInstances();
      widgetInstances.assignAll(latest);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setWidgetState({
    required WidgetInstance instance,
    required StreakWidgetState state,
    int streakCount = 0,
    List<bool>? weekProgress,
  }) async {
    final code = instance.loginCode;
    if (code == null || code.isEmpty) {
      return;
    }
    await _service.overrideState(
      loginCode: code,
      state: state,
      streakCount: streakCount,
      weekProgress: weekProgress,
    );
  }

  Future<void> unlinkWidget(WidgetInstance instance) async {
    await _service.unlinkWidget(instance.widgetId);
  }
}

