import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../models/streak_widget_state.dart';
import '../models/widget_instance.dart';

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

  static String _instanceKey(int widgetId) =>
      'widget_instance_${widgetId.toString()}';

  static String _mapState(StreakWidgetState state) {
    return switch (state) {
      StreakWidgetState.unlinked => 'unlinked',
      StreakWidgetState.startChallenge => 'state1',
      StreakWidgetState.justCompleted => 'state2',
      StreakWidgetState.completedToday => 'state3',
      StreakWidgetState.awaitingToday => 'state4',
    };
  }

  static Future<Map<String, dynamic>?> loadPayloadForCode(
      String loginCode) async {
    final normalized = loginCode.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    final raw = await HomeWidget.getWidgetData<String>(_payloadKey(normalized));
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> loadAssignmentForWidget(int widgetId) async {
    return HomeWidget.getWidgetData<String>(_assignmentKey(widgetId));
  }

  static WidgetInstance mapPayloadToInstance({
    required int widgetId,
    required Map<String, dynamic> payload,
    String? loginCode,
  }) {
    final state = payload['state'] as String?;
    final streakCount = (payload['streakCount'] as num?)?.toInt() ?? 0;
    final weeks = payload['weekProgress'];
    final weekProgress = weeks is List
        ? weeks.map((e) => e == true).toList(growable: false)
        : List<bool>.filled(7, false);

    return WidgetInstance(
      widgetId: widgetId,
      loginCode: loginCode ?? payload['loginCode'] as String?,
      state: _stringToState(state),
      streakCount: streakCount,
      weekProgress: weekProgress,
      lastStateChange: DateTime.now(),
    );
  }

  static StreakWidgetState _stringToState(String? state) {
    return switch (state) {
      'unlinked' => StreakWidgetState.unlinked,
      'state2' => StreakWidgetState.justCompleted,
      'state3' => StreakWidgetState.completedToday,
      'state4' => StreakWidgetState.awaitingToday,
      'state1' || _ => StreakWidgetState.startChallenge,
    };
  }

  static Future<void> saveWidgetInstance(WidgetInstance instance) async {
    await HomeWidget.saveWidgetData<String>(
      _instanceKey(instance.widgetId),
      instance.toJsonString(),
    );
  }

  static Future<WidgetInstance?> loadWidgetInstance(int widgetId) async {
    final raw = await HomeWidget.getWidgetData<String>(_instanceKey(widgetId));
    if (raw == null) return null;
    try {
      return WidgetInstance.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeWidgetInstance(int widgetId) async {
    await HomeWidget.saveWidgetData<String>(_instanceKey(widgetId), null);
  }
}
