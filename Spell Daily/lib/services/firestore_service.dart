import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore data access layer focused on a single user document keyed by login code.
class FirestoreService {
  FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> userDoc(String loginCode) =>
      _usersCollection.doc(loginCode);

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchUser(String loginCode) {
    return userDoc(loginCode).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToUser(
    String loginCode,
  ) {
    return userDoc(loginCode).snapshots();
  }

  Future<void> createUserIfMissing(String loginCode) async {
    final doc = await fetchUser(loginCode);
    if (doc.exists) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await userDoc(loginCode).set({
      'loginCode': loginCode,
      'userId': loginCode,
      'streak': 0,
      'lastCompletedDate': '',
      'todayStatus': 'pending',
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> updateUser(String loginCode, Map<String, dynamic> data) async {
    await userDoc(loginCode).set(
      {
        ...data,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      SetOptions(merge: true),
    );
  }
}
