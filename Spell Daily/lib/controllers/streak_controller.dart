import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../services/firestore_service.dart';
import 'auth_controller.dart';

/// Owns streak calculations, Firestore listeners, and midnight reset logic.
///
/// The Firestore document is the single source of truth. This controller
/// keeps local reactive state in sync for the UI and widget update service.
class StreakController extends GetxController {
  StreakController(this._firestoreService);

  final FirestoreService _firestoreService;

  final RxInt streak = 0.obs;
  final RxString todayStatus = 'pending'.obs;
  final RxString lastCompletedDate = ''.obs;
  final RxBool isSubscribed = false.obs;

  StreamSubscription? _userSubscription;

  String? get loginCode => Get.find<AuthController>().loginCode;

  @override
  void onClose() {
    _userSubscription?.cancel();
    super.onClose();
  }

  /// Sets up a real-time listener to keep the UI + widgets in sync.
  ///
  /// If [code] is omitted, it uses the current `loginCode`.
  void subscribeToFirestore([String? code]) {
    final effectiveCode = code ?? loginCode;
    if (effectiveCode == null) return;

    _userSubscription?.cancel();
    _userSubscription = _firestoreService.listenToUser(effectiveCode).listen(
      (snapshot) {
        final data = snapshot.data();
        if (data == null) return;
        streak.value = (data['streak'] ?? 0) as int;
        todayStatus.value = (data['todayStatus'] ?? 'pending') as String;
        lastCompletedDate.value = (data['lastCompletedDate'] ?? '') as String;
        _resetIfMidnightPassed();
      },
    );
    isSubscribed.value = true;
  }

  /// Manually checks the Firestore doc once (used after WebView closes).
  ///
  /// Returns `true` if:
  /// - `todayStatus == "completed"` and
  /// - `lastCompletedDate` equals today's local date.
  Future<bool> checkTodayStatus() async {
    final code = loginCode;
    if (code == null) return false;
    final doc = await _firestoreService.fetchUser(code);
    final data = doc.data();
    if (data == null) return false;
    streak.value = (data['streak'] ?? 0) as int;
    todayStatus.value = (data['todayStatus'] ?? 'pending') as String;
    lastCompletedDate.value = (data['lastCompletedDate'] ?? '') as String;
    return _isTodayCompleted();
  }

  /// Increments streak only once per local day if today's game is completed.
  Future<void> updateStreakIfCompleted() async {
    if (!_isTodayCompleted()) return;
    final code = loginCode;
    if (code == null) return;
    await _firestoreService.updateUser(code, {
      'streak': streak.value + 1,
      'lastCompletedDate': _todayIso(),
      'todayStatus': 'completed',
    });
  }

  bool _isTodayCompleted() {
    return todayStatus.value == 'completed' &&
        lastCompletedDate.value == _todayIso();
  }

  /// Simple midnight reset: if `lastCompletedDate` is not today, we treat
  /// the day as pending. This drives widget + in-app messaging.
  void _resetIfMidnightPassed() {
    if (lastCompletedDate.value != _todayIso()) {
      todayStatus.value = 'pending';
    }
  }

  String _todayIso() => DateFormat('yyyy-MM-dd').format(DateTime.now());
}
