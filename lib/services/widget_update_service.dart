import 'package:background_fetch/background_fetch.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'widget_state_service.dart';

class WidgetUpdateService {
  WidgetUpdateService._();

  static final WidgetUpdateService instance = WidgetUpdateService._();

  Future<void> init() async {
    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15,
        startOnBoot: true,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiredNetworkType: NetworkType.ANY,
      ),
      _onFetch,
      _onTimeout,
    );
    await BackgroundFetch.start();
  }

  Future<void> _onFetch(String taskId) async {
    await WidgetStateService.instance.syncAllFromFirestore();
    BackgroundFetch.finish(taskId);
  }

  void _onTimeout(String taskId) {
    BackgroundFetch.finish(taskId);
  }
}

@pragma('vm:entry-point')
void widgetBackgroundFetch(HeadlessTask task) async {
  if (task.timeout) {
    BackgroundFetch.finish(task.taskId);
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await WidgetStateService.instance.syncAllFromFirestore();
  BackgroundFetch.finish(task.taskId);
}
