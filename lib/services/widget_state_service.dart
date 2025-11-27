import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/streak_widget_state.dart';
import '../models/weekly_progress.dart';
import 'widget_bridge.dart';

class WidgetStateService {
  WidgetStateService._();

  static final WidgetStateService instance = WidgetStateService._();

  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('widgetStates');

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _stateSubscription;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('flutter.loginCode');
    if (code != null && code.isNotEmpty) {
      await ensureDocument(code);
      await startListening(code);
      await syncOnceFromFirestore(loginCode: code);
    }
  }

  Future<void> ensureDocument(String loginCode) async {
    final docRef = _collection.doc(loginCode);
    final snapshot = await docRef.get();
    if (snapshot.exists) return;

    await docRef.set({
      'loginCode': loginCode,
      'state': 'state1',
      'streakCount': 0,
      'weekProgress': List.generate(7, (_) => false),
      'manualOverride': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> startListening(String loginCode) async {
    await ensureDocument(loginCode);
    await _stateSubscription?.cancel();
    _stateSubscription = _collection.doc(loginCode).snapshots().listen(
      (snapshot) {
        final data = snapshot.data();
        if (data == null) return;
        _applyDataToWidget(data);
      },
    );
  }

  Future<void> pushLocalState({
    required String loginCode,
    required StreakWidgetState state,
    required int streakCount,
    required List<WeeklyProgress> progress,
  }) async {
    final docRef = _collection.doc(loginCode);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (data != null && data['manualOverride'] == true) {
      return; // Let manual edits control the widget.
    }

    final weekFlags = progress.map((e) => e.completed).toList();
    final payload = {
      'loginCode': loginCode,
      'state': _stateToString(state),
      'streakCount': streakCount,
      'weekProgress': weekFlags,
      'manualOverride': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await docRef.set(payload, SetOptions(merge: true));
    await WidgetBridge.update(
      loginCode: loginCode,
      state: state,
      streakCount: streakCount,
      weekProgress: weekFlags,
    );
  }

  Future<void> syncOnceFromFirestore({String? loginCode}) async {
    final resolvedCode = loginCode ?? await _storedLoginCode();
    if (resolvedCode == null) return;
    final snapshot = await _collection.doc(resolvedCode).get();
    final data = snapshot.data();
    if (data == null) return;
    _applyDataToWidget(data);
  }

  Future<String?> _storedLoginCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('flutter.loginCode');
    if (code == null || code.isEmpty) return null;
    return code;
  }

  void _applyDataToWidget(Map<String, dynamic> data) {
    final loginCode = (data['loginCode'] as String?) ?? '--';
    final streakCount = (data['streakCount'] as num?)?.toInt() ?? 0;
    final state = _parseState(data['state'] as String?);
    final weekProgress = _parseWeekProgress(data['weekProgress']);

    WidgetBridge.update(
      loginCode: loginCode,
      state: state,
      streakCount: streakCount,
      weekProgress: weekProgress,
    );
  }

  StreakWidgetState _parseState(String? raw) {
    switch (raw) {
      case 'state2':
        return StreakWidgetState.justCompleted;
      case 'state3':
        return StreakWidgetState.completedToday;
      case 'state4':
        return StreakWidgetState.awaitingToday;
      case 'state1':
      default:
        return StreakWidgetState.startChallenge;
    }
  }

  String _stateToString(StreakWidgetState state) {
    return switch (state) {
      StreakWidgetState.startChallenge => 'state1',
      StreakWidgetState.justCompleted => 'state2',
      StreakWidgetState.completedToday => 'state3',
      StreakWidgetState.awaitingToday => 'state4',
    };
  }

  List<bool> _parseWeekProgress(dynamic raw) {
    final result = List<bool>.filled(7, false);
    if (raw is List) {
      for (var i = 0; i < result.length && i < raw.length; i++) {
        result[i] = raw[i] == true;
      }
    }
    return result;
  }
}

