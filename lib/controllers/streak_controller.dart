import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/streak_widget_state.dart';
import '../models/weekly_progress.dart';
import '../services/firestore_service.dart';
import '../services/widget_state_service.dart';

class StreakController extends GetxController {
  final FirestoreService _service = FirestoreService.instance;

  final RxInt streak = 0.obs;
  final RxString todayStatus = 'pending'.obs;
  final RxString lastCompletedDate = ''.obs;
  final Rx<StreakWidgetState> widgetState =
      StreakWidgetState.startChallenge.obs;

  DateTime? _lastUpdatedAt;

  StreamSubscription? _subscription;
  Timer? _stateRefreshTimer;
  String? _loginCode;
  String? get loginCode => _loginCode;

  void subscribeToUser(String loginCode) {
    if (_loginCode == loginCode && _subscription != null) return;
    _subscription?.cancel();
    _loginCode = loginCode;
    _subscription = _service.streamUser(loginCode).listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? {};
      streak.value = (data['streak'] ?? 0) as int;
      todayStatus.value = (data['todayStatus'] ?? 'pending') as String;
      lastCompletedDate.value =
          (data['lastCompletedDate'] ?? _formatDate(DateTime.now())) as String;
      final timestamp = data['updatedAt'];
      if (timestamp is Timestamp) {
        _lastUpdatedAt = timestamp.toDate().toUtc();
      }
      _syncDerivedState();
      resetStatusIfNeeded();
    });
  }

  bool isNewDay() {
    final today = _formatDate(DateTime.now());
    return lastCompletedDate.value != today;
  }

  Future<void> resetStatusIfNeeded() async {
    final code = _loginCode;
    if (code == null) return;
    if (isNewDay() && todayStatus.value != 'pending') {
      await _service.updateTodayStatus(code, 'pending');
      todayStatus.value = 'pending';
      _lastUpdatedAt = DateTime.now().toUtc();
      _syncDerivedState();
    }
  }

  Future<void> updateStreakAfterCompletion() async {
    final code = _loginCode;
    if (code == null) return;
    final today = _formatDate(DateTime.now());
    if (todayStatus.value == 'completed' && lastCompletedDate.value == today) {
      return;
    }
    final newStreak = isNewDay() ? streak.value + 1 : streak.value;
    await _service.updateTodayStatus(code, 'completed');
    await _service.updateStreak(code, newStreak);
    streak.value = newStreak;
    todayStatus.value = 'completed';
    lastCompletedDate.value = today;
    _lastUpdatedAt = DateTime.now().toUtc();
    _syncDerivedState();
  }

  List<WeeklyProgress> getWeeklyProgress() {
    final today = DateTime.now().toUtc();
    final start = today.subtract(const Duration(days: 6));
    final completedKeys = _completedDayKeys();
    final todayKey = _formatDate(today);

    return List.generate(7, (index) {
      final day = start.add(Duration(days: index));
      final label = DateFormat('EEE').format(day).substring(0, 3).toUpperCase();
      final key = _formatDate(day);
      return WeeklyProgress(
        label: label,
        completed: completedKeys.contains(key),
        isToday: key == todayKey,
      );
    });
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _stateRefreshTimer?.cancel();
    super.onClose();
  }

  String _formatDate(DateTime dateTime) =>
      DateFormat('yyyy-MM-dd').format(dateTime.toUtc());

  void _syncDerivedState() {
    widgetState.value = _determineState();
    _stateRefreshTimer?.cancel();
    if (widgetState.value == StreakWidgetState.justCompleted) {
      _stateRefreshTimer = Timer(const Duration(minutes: 5), () {
        _stateRefreshTimer = null;
        widgetState.value = _determineState();
        final code = _loginCode;
        if (code != null) {
          unawaited(
            WidgetStateService.instance.pushLocalState(
              loginCode: code,
              state: widgetState.value,
              streakCount: streak.value,
              progress: getWeeklyProgress(),
            ),
          );
        }
      });
    }
    final code = _loginCode;
    if (code != null) {
      unawaited(
        WidgetStateService.instance.pushLocalState(
          loginCode: code,
          state: widgetState.value,
          streakCount: streak.value,
          progress: getWeeklyProgress(),
        ),
      );
    }
  }

  StreakWidgetState _determineState() {
    final daysGap = _daysSinceLastPlay();
    final playedToday = hasPlayedToday;

    if (streak.value <= 0 ||
        lastCompletedDate.value.isEmpty ||
        (daysGap != null && daysGap > 7)) {
      return StreakWidgetState.startChallenge;
    }

    if (playedToday) {
      return _isRecentCompletion
          ? StreakWidgetState.justCompleted
          : StreakWidgetState.completedToday;
    }

    if (daysGap == 1 && streak.value > 0) {
      return StreakWidgetState.awaitingToday;
    }

    if (daysGap != null && daysGap > 1) {
      return StreakWidgetState.startChallenge;
    }

    return StreakWidgetState.awaitingToday;
  }

  int? _daysSinceLastPlay() {
    final lastDate = _parseDate(lastCompletedDate.value);
    if (lastDate == null) return null;
    final today = DateTime.now().toUtc();
    return today.difference(lastDate).inDays;
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    try {
      return DateFormat('yyyy-MM-dd').parseUtc(value);
    } catch (_) {
      return null;
    }
  }

  bool get hasPlayedToday =>
      todayStatus.value == 'completed' && lastCompletedDate.value == _todayKey;

  bool get _isRecentCompletion {
    if (!hasPlayedToday || _lastUpdatedAt == null) return false;
    final now = DateTime.now().toUtc();
    return now.difference(_lastUpdatedAt!).inMinutes < 5;
  }

  Set<String> _completedDayKeys() {
    final lastDate = _parseDate(lastCompletedDate.value);
    if (lastDate == null) return {};
    final keys = <String>{};
    for (int i = 0; i < streak.value && i < 7; i++) {
      final day = lastDate.subtract(Duration(days: i));
      keys.add(_formatDate(day));
    }
    return keys;
  }

  String get _todayKey => _formatDate(DateTime.now());
}

