import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../models/streak_widget_state.dart';
import '../models/weekly_progress.dart';

class WidgetBridge {
  WidgetBridge._();

  static const _providerName = 'StreakWidgetProvider';

  static Future<void> update({
    required StreakWidgetState state,
    required int streakCount,
    required List<WeeklyProgress> progress,
  }) async {
    final payload = jsonEncode({
      'state': _mapState(state),
      'streakCount': streakCount,
      'weekProgress':
          progress.map((day) => day.completed).toList(growable: false),
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

