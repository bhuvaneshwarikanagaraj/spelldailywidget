import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// This file demonstrates the core flows using simplified in-memory
/// stand-ins for Firestore and local storage.

void main() {
  group('Spell Daily Lite integration-style flows (logic only)', () {
    late FakeFirestoreService firestore;
    late TestAuthController authController;
    late TestStreakController streakController;

    setUp(() {
      Get.reset();
      firestore = FakeFirestoreService();
      streakController = TestStreakController(firestore);
      authController = TestAuthController(firestore, FakeStorage(), streakController);
    });

    test('login with new code creates user document', () async {
      await authController.loginWithCode('ARU123');
      expect(authController.loginCode, 'ARU123');
      final doc = await firestore.fetchUser('ARU123');
      expect(doc.data()?['loginCode'], 'ARU123');
    });

    test('streak controller sees completion when todayStatus is completed', () async {
      await authController.loginWithCode('TES132');

      // Simulate game completion by directly updating the fake doc.
      await firestore.updateUser('TES132', {
        'streak': 0,
        'todayStatus': 'completed',
        'lastCompletedDate': '2025-11-17',
      });

      final completed = await streakController.checkTodayStatus('TES132');
      expect(completed, true);
    });
  });
}

// ===== Test doubles & minimal controllers (standalone, not used by app) =====

class FakeFirestoreService {
  final Map<String, Map<String, dynamic>> _docs = {};

  Future<void> createUserIfMissing(String loginCode) async {
    _docs.putIfAbsent(loginCode, () {
      return {
        'loginCode': loginCode,
        'userId': loginCode,
        'streak': 0,
        'lastCompletedDate': '',
        'todayStatus': 'pending',
        'createdAt': 1690000000000,
        'updatedAt': 1690000000000,
      };
    });
  }

  Future<_FakeDocSnapshot> fetchUser(String loginCode) async {
    return _FakeDocSnapshot(_docs[loginCode]);
  }

  Future<void> updateUser(String loginCode, Map<String, dynamic> data) async {
    _docs.update(loginCode, (existing) {
      existing.addAll(data);
      return existing;
    }, ifAbsent: () => data);
  }
}

class _FakeDocSnapshot {
  _FakeDocSnapshot(this._data);

  final Map<String, dynamic>? _data;

  Map<String, dynamic>? data() => _data;
}

class TestAuthController {
  TestAuthController(this._firestore, this._storage, this._streakController);

  final FakeFirestoreService _firestore;
  final FakeStorage _storage;
  final TestStreakController _streakController;

  String? _loginCode;

  String? get loginCode => _loginCode;

  Future<void> loginWithCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return;

    await _firestore.createUserIfMissing(normalized);
    _loginCode = normalized;
    await _storage.write('loginCode', normalized);
  }
}

class TestStreakController {
  TestStreakController(this._firestore);

  final FakeFirestoreService _firestore;

  int streak = 0;
  String todayStatus = 'pending';
  String lastCompletedDate = '';

  Future<bool> checkTodayStatus(String loginCode) async {
    final doc = await _firestore.fetchUser(loginCode);
    final data = doc.data();
    if (data == null) return false;
    streak = (data['streak'] ?? 0) as int;
    todayStatus = (data['todayStatus'] ?? 'pending') as String;
    lastCompletedDate = (data['lastCompletedDate'] ?? '') as String;
    return todayStatus == 'completed' && lastCompletedDate.isNotEmpty;
  }
}

class FakeStorage {
  final Map<String, dynamic> _store = {};

  T? read<T>(String key) => _store[key] as T?;

  Future<void> write(String key, dynamic value) async {
    _store[key] = value;
  }
}


