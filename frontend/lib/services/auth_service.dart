import 'package:pocketbase/pocketbase.dart';
import '../constants/app_constants.dart';
import '../models/app_user.dart';
import 'pocketbase_service.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Service for handling user authentication.
/// Uses the shared PocketBaseService client so auth state is visible
/// to ChoreService and any other services on the same client.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  PocketBase get _pb => PocketBaseService().client;

  bool get isLoggedIn => _pb.authStore.isValid;
  String? get currentUserId => _pb.authStore.record?.id;

  String? get currentUserName {
    final record = _pb.authStore.record;
    if (record == null) return null;
    return AppUser.fromRecord(record).displayName;
  }

  Future<void> login(String email, String password) async {
    try {
      await _pb.collection(Collections.users).authWithPassword(email, password);
    } on ClientException catch (e) {
      if (e.statusCode == 400) {
        throw const AuthException('Incorrect email or password. Please try again.');
      } else if (e.statusCode == 0) {
        throw const AuthException('Cannot connect to the server. Check your network.');
      }
      throw AuthException('Login failed: ${e.response['message'] ?? e}');
    }
  }

  void logout() => _pb.authStore.clear();

  AppUser? getCurrentUser() {
    final record = _pb.authStore.record;
    if (record == null) return null;
    return AppUser.fromRecord(record);
  }
}