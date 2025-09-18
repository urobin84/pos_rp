import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _sessionTokenKey = 'session_token';

  /// Saves the session token to local storage.
  /// This should be called after a successful login API call.
  Future<void> saveSession(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionTokenKey, token);
    } catch (e) {
      debugPrint("Error saving session: $e");
    }
  }

  /// Retrieves the session token from local storage.
  Future<String?> getSessionToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_sessionTokenKey);
    } catch (e) {
      debugPrint("Error getting session token: $e");
      return null;
    }
  }

  /// Checks if a user session is active.
  /// For robust security, this should also verify the token with your backend.
  Future<bool> isLoggedIn() async {
    final token = await getSessionToken();
    if (token == null) {
      return false;
    }

    // **IMPORTANT**: Add a call to your backend here to verify the token is still valid.
    // For example: final isValid = await myApi.verifyToken(token);
    // return isValid;

    // For this example, we'll just check for the token's existence.
    return true;
  }

  /// Clears the session from local storage.
  /// This should be called on logout.
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionTokenKey);
      // **IMPORTANT**: Also call your backend's logout endpoint here
      // to invalidate the session on the server side.
      // For example: await myApi.logout(token);
    } catch (e) {
      debugPrint("Error during logout: $e");
    }
  }
}
