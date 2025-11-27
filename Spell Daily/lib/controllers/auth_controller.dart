import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../routes/app_routes.dart';
import '../services/firestore_service.dart';
import 'game_controller.dart';
import 'streak_controller.dart';

/// Handles login-code based pseudo auth (no Firebase Auth for this MVP).
///
/// - Each user is a document under `users/{loginCode}`.
/// - On first login with a code, the document is created with the default schema.
/// - The `loginCode` is persisted locally via `GetStorage` so the user
///   remains "logged in" across app launches.
class AuthController extends GetxController {
  AuthController(this._firestoreService, this._storage);

  final FirestoreService _firestoreService;
  final GetStorage _storage;

  final RxnString _loginCode = RxnString();
  final RxBool isLoading = false.obs;
  // Holds the current user's Firestore document data; `null` when not loaded.
  final Rx<Map<String, dynamic>?> userDoc = Rx<Map<String, dynamic>?>(null);

  String? get loginCode => _loginCode.value;

  @override
  void onInit() {
    super.onInit();
    _loginCode.value = _storage.read<String>('loginCode');
  }

  /// Logs in with a permanent code and backs it with a Firestore document.
  ///
  /// Behavior:
  /// - Normalizes the code to uppercase.
  /// - If `users/{code}` exists, fetches it.
  /// - Else creates it with the default fields (see `FirestoreService`).
  /// - Stores the current code in local storage for future sessions.
  Future<void> loginWithCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      Get.snackbar('Error', 'Please enter a valid login code');
      return;
    }

    isLoading.value = true;
    try {
      await _firestoreService.createUserIfMissing(normalized);
      final doc = await _firestoreService.fetchUser(normalized);
      userDoc.value = doc.data() ?? {};
      _loginCode.value = normalized;
      await _storage.write('loginCode', normalized);

      // Start listening for streak changes for this user.
      Get.find<StreakController>().subscribeToFirestore(normalized);

      // Navigate to start game screen
      await Get.offAllNamed(AppRoutes.startGame);
      
      // Auto-start the game after a short delay to open browser directly
      await Future.delayed(const Duration(milliseconds: 500));
      Get.find<GameController>().startGame();
    } catch (e) {
      Get.snackbar('Login Error', 'Failed to login: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
