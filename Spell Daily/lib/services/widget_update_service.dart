import 'dart:async';

import 'package:background_fetch/background_fetch.dart' as bg_fetch;
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart' as wm;

import '../controllers/streak_controller.dart';

/// Coordinates background refreshes for the homescreen widget on both Android and iOS.
/// Android: schedules Workmanager one-off tasks.
/// iOS: uses BackgroundFetch + WidgetKit via home_widget.
class WidgetUpdateService {
  WidgetUpdateService();

  static const String _androidTask = 'spellDailyWidgetRefresh';

  Future<void> init() async {
    await wm.Workmanager().initialize(_callbackDispatcher, isInDebugMode: false);
    await bg_fetch.BackgroundFetch.configure(
      bg_fetch.BackgroundFetchConfig(
        minimumFetchInterval: 15,
        startOnBoot: true,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiredNetworkType: bg_fetch.NetworkType.ANY,
      ),
      _onBackgroundFetch,
      _onBackgroundTimeout,
    );
  }

  Future<void> scheduleDelayedRefresh(Duration delay) async {
    await wm.Workmanager().registerOneOffTask(
      DateTime.now().millisecondsSinceEpoch.toString(),
      _androidTask,
      initialDelay: delay,
      constraints: wm.Constraints(networkType: wm.NetworkType.connected),
    );
  }

  static void _callbackDispatcher() {
    wm.Workmanager().executeTask((task, inputData) async {
      await HomeWidget.updateWidget(name: 'StreakWidgetProvider');
      return true;
    });
  }

  Future<void> _onBackgroundFetch(String taskId) async {
    final streakController = Get.find<StreakController>();
    await streakController.checkTodayStatus();
    await HomeWidget.updateWidget(name: 'StreakWidgetProvider');
    bg_fetch.BackgroundFetch.finish(taskId);
  }

  void _onBackgroundTimeout(String taskId) {
    bg_fetch.BackgroundFetch.finish(taskId);
  }
}
