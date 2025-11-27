import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  Future<void> createUserIfNotExists(String loginCode) async {
    final doc = _users.doc(loginCode);
    final snapshot = await doc.get();
    if (snapshot.exists) return;

    final now = Timestamp.now();
    final today = _formatDate(DateTime.now());
    await doc.set({
      'loginCode': loginCode,
      'userId': loginCode,
      'streak': 0,
      'todayStatus': 'pending',
      'lastCompletedDate': today,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(
      String loginCode) async {
    return _users.doc(loginCode).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUser(
      String loginCode) {
    return _users.doc(loginCode).snapshots();
  }

  Future<void> updateTodayStatus(String loginCode, String status) async {
    await _users.doc(loginCode).update({
      'todayStatus': status,
      'updatedAt': Timestamp.now(),
      if (status == 'completed') 'lastCompletedDate': _formatDate(DateTime.now()),
    });
  }

  Future<void> updateStreak(String loginCode, int streak) async {
    await _users.doc(loginCode).update({
      'streak': streak,
      'updatedAt': Timestamp.now(),
    });
  }

  String _formatDate(DateTime dateTime) =>
      DateFormat('yyyy-MM-dd').format(dateTime.toUtc());
}

