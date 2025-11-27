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
    final normalizedCode = loginCode.trim().toUpperCase();
    final payload = jsonEncode({
      'loginCode': normalizedCode,
      'state': _mapState(state),
      'streakCount': streakCount,
      'weekProgress': weekProgress,
    });

    await HomeWidget.saveWidgetData<String>('widget_payload', payload);
    await HomeWidget.saveWidgetData<String>(
      _payloadKey(normalizedCode),
      payload,
    );
    await HomeWidget.updateWidget(name: _providerName);
  }

  static Future<void> saveAssignment({
    required int widgetId,
    required String loginCode,
  }) async {
    await HomeWidget.saveWidgetData<String>(
      _assignmentKey(widgetId),
      loginCode.trim().toUpperCase(),
    );
    await HomeWidget.updateWidget(name: _providerName);
  }

  static Future<void> clearAssignment(int widgetId) async {
    await HomeWidget.saveWidgetData<String>(_assignmentKey(widgetId), null);
    await HomeWidget.updateWidget(name: _providerName);
  }

  static Future<void> clearPayload(String loginCode) async {
    final normalizedCode = loginCode.trim().toUpperCase();
    await HomeWidget.saveWidgetData<String>(
      _payloadKey(normalizedCode),
      null,
    );
  }

  static String _assignmentKey(int widgetId) =>
      'widget_assignment_${widgetId.toString()}';

  static String _payloadKey(String loginCode) =>
      'widget_payload_${loginCode.toUpperCase()}';

  static String _mapState(StreakWidgetState state) {
    return switch (state) {
      StreakWidgetState.startChallenge => 'state1',
      StreakWidgetState.justCompleted => 'state2',
      StreakWidgetState.completedToday => 'state3',
      StreakWidgetState.awaitingToday => 'state4',
    };
  }
}
