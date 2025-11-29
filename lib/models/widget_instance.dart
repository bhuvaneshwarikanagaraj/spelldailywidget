import 'dart:convert';

import 'streak_widget_state.dart';

class WidgetInstance {
  WidgetInstance({
    required this.widgetId,
    required this.state,
    this.loginCode,
    this.streakCount = 0,
    List<bool>? weekProgress,
    this.lastStateChange,
    this.pendingTenMinuteWorkId,
    this.pendingNextDayWorkId,
  }) : weekProgress = weekProgress ?? List<bool>.filled(7, false);

  factory WidgetInstance.fromJson(Map<String, dynamic> json) {
    return WidgetInstance(
      widgetId: json['widgetId'] as int,
      loginCode: json['loginCode'] as String?,
      state: _stringToState(json['state'] as String?),
      streakCount: (json['streakCount'] as num?)?.toInt() ?? 0,
      weekProgress: (json['weekProgress'] as List?)
              ?.map((e) => e == true)
              .toList(growable: false) ??
          List<bool>.filled(7, false),
      lastStateChange: (json['lastStateChange'] as int?) != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastStateChange'] as int)
          : null,
      pendingTenMinuteWorkId: json['pendingTenMinuteWorkId'] as String?,
      pendingNextDayWorkId: json['pendingNextDayWorkId'] as String?,
    );
  }

  static StreakWidgetState _stringToState(String? state) {
    return switch (state) {
      'unlinked' => StreakWidgetState.unlinked,
      'state1' => StreakWidgetState.startChallenge,
      'state2' => StreakWidgetState.justCompleted,
      'state3' => StreakWidgetState.completedToday,
      'state4' => StreakWidgetState.awaitingToday,
      _ => StreakWidgetState.unlinked,
    };
  }

  factory WidgetInstance.fromJsonString(String payload) =>
      WidgetInstance.fromJson(jsonDecode(payload) as Map<String, dynamic>);

  final int widgetId;
  final String? loginCode;
  final StreakWidgetState state;
  final int streakCount;
  final List<bool> weekProgress;
  final DateTime? lastStateChange;
  final String? pendingTenMinuteWorkId;
  final String? pendingNextDayWorkId;

  WidgetInstance copyWith({
    String? loginCode,
    StreakWidgetState? state,
    int? streakCount,
    List<bool>? weekProgress,
    DateTime? lastStateChange,
    String? pendingTenMinuteWorkId,
    String? pendingNextDayWorkId,
  }) {
    return WidgetInstance(
      widgetId: widgetId,
      loginCode: loginCode ?? this.loginCode,
      state: state ?? this.state,
      streakCount: streakCount ?? this.streakCount,
      weekProgress: weekProgress ?? this.weekProgress,
      lastStateChange: lastStateChange ?? this.lastStateChange,
      pendingTenMinuteWorkId:
          pendingTenMinuteWorkId ?? this.pendingTenMinuteWorkId,
      pendingNextDayWorkId: pendingNextDayWorkId ?? this.pendingNextDayWorkId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'widgetId': widgetId,
      'loginCode': loginCode,
      'state': _stateToString(state),
      'streakCount': streakCount,
      'weekProgress': weekProgress,
      'lastStateChange': lastStateChange?.millisecondsSinceEpoch,
      'pendingTenMinuteWorkId': pendingTenMinuteWorkId,
      'pendingNextDayWorkId': pendingNextDayWorkId,
    };
  }

  static String _stateToString(StreakWidgetState state) {
    return switch (state) {
      StreakWidgetState.unlinked => 'unlinked',
      StreakWidgetState.startChallenge => 'state1',
      StreakWidgetState.justCompleted => 'state2',
      StreakWidgetState.completedToday => 'state3',
      StreakWidgetState.awaitingToday => 'state4',
    };
  }

  String toJsonString() => jsonEncode(toJson());
}

