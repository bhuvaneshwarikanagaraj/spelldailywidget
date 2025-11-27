import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../services/firestore_service.dart';

class WeeklyProgress {
  WeeklyProgress({
    required this.label,
    required this.completed,
  });

  final String label;
  final bool completed;
}

class StreakController extends GetxController {
  final FirestoreService _service = FirestoreService.instance;

  final RxInt streak = 0.obs;
  final RxString todayStatus = 'pending'.obs;
  final RxString lastCompletedDate = ''.obs;

  StreamSubscription? _subscription;
  String? _loginCode;

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
  }

  List<WeeklyProgress> getWeeklyProgress() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final completedDate = lastCompletedDate.value;
    final today = _formatDate(now);

    return List.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      final label = DateFormat('EEE').format(day).substring(0, 3).toUpperCase();
      final dayKey = _formatDate(day);
      final isToday = dayKey == today;
      final completed = (isToday && todayStatus.value == 'completed') ||
          (!isToday && dayKey == completedDate);
      return WeeklyProgress(label: label, completed: completed);
    });
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  String _formatDate(DateTime dateTime) =>
      DateFormat('yyyy-MM-dd').format(dateTime.toUtc());
}

