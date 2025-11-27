import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../models/streak_widget_state.dart';

class WidgetBridge {
  WidgetBridge._();

  static const _providerName = 'StreakWidgetProvider';

  static Future<void> update({
    required String loginCode,
    required StreakWidgetState state,
    required int streakCount,
    required List<bool> weekProgress,
  }) async {
    final payload = jsonEncode({
      'loginCode': loginCode,
      'state': _mapState(state),
      'streakCount': streakCount,
      'weekProgress': weekProgress,
    });

    await HomeWidget.saveWidgetData<String>('widget_payload', payload);
    await HomeWidget.updateWidget(name: _providerName);
  }

  static String _mapState(StreakWidgetState state) {
    return switch (state) {
      StreakWidgetState.startChallenge => 'state1',
      StreakWidgetState.justCompleted => 'state2',
      StreakWidgetState.completedToday => 'state3',
      StreakWidgetState.awaitingToday => 'state4',
    };
  }
}


