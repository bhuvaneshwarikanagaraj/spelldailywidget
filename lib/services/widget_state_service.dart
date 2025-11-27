import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/streak_widget_state.dart';
import '../models/weekly_progress.dart';
import 'widget_bridge.dart';

class WidgetStateService {
  WidgetStateService._();

  static final WidgetStateService instance = WidgetStateService._();

  static const _loginCodeKey = 'flutter.loginCode';
  static const widgetAssignmentPrefix = 'flutter.widget.assignment.';
  static const pendingWidgetIdKey = 'flutter.pending_widget_id';

  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('widgetStates');

  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _listeners = {};

  Future<void> bootstrap() async {
    final codes = await _trackedLoginCodes();
    for (final code in codes) {
      await ensureDocument(code);
      await startListening(code);
      await syncOnceFromFirestore(loginCode: code);
    }
  }

  Future<void> ensureDocument(String loginCode) async {
    final normalized = loginCode.trim().toUpperCase();
    if (normalized.isEmpty) return;
    final docRef = _collection.doc(normalized);
    final snapshot = await docRef.get();
    if (snapshot.exists) return;

    await docRef.set({
      'loginCode': normalized,
      'state': 'state1',
      'streakCount': 0,
      'weekProgress': List.generate(7, (_) => false),
      'manualOverride': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> startListening(String loginCode) async {
    final normalized = loginCode.trim().toUpperCase();
    if (normalized.isEmpty) return;

    await ensureDocument(normalized);
    if (_listeners.containsKey(normalized)) return;

    final sub = _collection.doc(normalized).snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data == null) return;
      _applyDataToWidget(loginCode: normalized, data: data);
    });
    _listeners[normalized] = sub;
  }

  Future<void> stopListening(String loginCode) async {
    final normalized = loginCode.trim().toUpperCase();
    final sub = _listeners.remove(normalized);
    await sub?.cancel();
  }

  Future<void> linkWidgetToLoginCode({
    required int widgetId,
    required String loginCode,
  }) async {
    final normalized = loginCode.trim().toUpperCase();
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${widgetAssignmentPrefix}$widgetId', normalized);
    await WidgetBridge.saveAssignment(
        widgetId: widgetId, loginCode: normalized);

    await ensureDocument(normalized);
    await startListening(normalized);
    await syncOnceFromFirestore(loginCode: normalized);
  }

  Future<void> unlinkWidget(int widgetId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${widgetAssignmentPrefix}$widgetId');
    await WidgetBridge.clearAssignment(widgetId);
  }

  Future<Map<int, String>> currentAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    return _extractAssignments(prefs);
  }

  Future<void> pushLocalState({
    required String loginCode,
    required StreakWidgetState state,
    required int streakCount,
    required List<WeeklyProgress> progress,
  }) async {
    final normalized = loginCode.trim().toUpperCase();
    if (normalized.isEmpty) return;

    final docRef = _collection.doc(normalized);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (data != null && data['manualOverride'] == true) {
      return; // Let manual edits control the widget.
    }

    final weekFlags = progress.map((e) => e.completed).toList();
    final payload = {
      'loginCode': normalized,
      'state': _stateToString(state),
      'streakCount': streakCount,
      'weekProgress': weekFlags,
      'manualOverride': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await docRef.set(payload, SetOptions(merge: true));
    await WidgetBridge.update(
      loginCode: normalized,
      state: state,
      streakCount: streakCount,
      weekProgress: weekFlags,
    );
  }

  Future<void> syncOnceFromFirestore({String? loginCode}) async {
    final resolvedCode =
        (loginCode ?? await _storedLoginCode())?.trim().toUpperCase();
    if (resolvedCode == null || resolvedCode.isEmpty) return;

    final snapshot = await _collection.doc(resolvedCode).get();
    final data = snapshot.data();
    if (data == null) return;
    _applyDataToWidget(loginCode: resolvedCode, data: data);
  }

  Future<void> syncAllFromFirestore() async {
    final codes = await _trackedLoginCodes();
    for (final code in codes) {
      await syncOnceFromFirestore(loginCode: code);
    }
  }

  Future<String?> _storedLoginCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_loginCodeKey);
    if (code == null || code.isEmpty) return null;
    return code;
  }

  Future<Set<String>> _trackedLoginCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final codes = <String>{};

    final stored = prefs.getString(_loginCodeKey);
    if (stored != null && stored.isNotEmpty) {
      codes.add(stored.trim().toUpperCase());
    }

    codes.addAll(_extractAssignments(prefs).values.map(
          (code) => code.trim().toUpperCase(),
        ));

    codes.addAll(_listeners.keys);
    codes.removeWhere((code) => code.isEmpty);
    return codes;
  }

  Map<int, String> _extractAssignments(SharedPreferences prefs) {
    final result = <int, String>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(widgetAssignmentPrefix)) continue;
      final id = int.tryParse(key.substring(widgetAssignmentPrefix.length));
      if (id == null) continue;
      final value = prefs.getString(key);
      if (value == null || value.isEmpty) continue;
      result[id] = value;
    }
    return result;
  }

  void _applyDataToWidget({
    required String loginCode,
    required Map<String, dynamic> data,
  }) {
    final resolvedCode = loginCode.isNotEmpty
        ? loginCode
        : (data['loginCode'] as String? ?? '--');
    final streakCount = (data['streakCount'] as num?)?.toInt() ?? 0;
    final state = _parseState(data['state'] as String?);
    final weekProgress = _parseWeekProgress(data['weekProgress']);

    WidgetBridge.update(
      loginCode: resolvedCode,
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
