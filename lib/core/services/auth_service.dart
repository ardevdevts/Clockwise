import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl =
      'http://localhost:3000'; // Change this to your server URL
  static const String _sessionTokenKey = 'session_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  String? _sessionCookie;
  String? _userId;
  String? _userEmail;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Initialize auth service and load saved session
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionCookie = prefs.getString(_sessionTokenKey);
    _userId = prefs.getString(_userIdKey);
    _userEmail = prefs.getString(_userEmailKey);
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _sessionCookie != null && _userId != null;

  /// Get current user ID
  String? get userId => _userId;

  /// Get current user email
  String? get userEmail => _userEmail;

  /// Get session cookie for WebSocket connection
  String? get sessionCookie => _sessionCookie;

  /// Login with email and password
  Future<LoginResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/email/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        // Extract session cookie from response headers
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          _sessionCookie = _extractSessionCookie(cookies);

          // Parse response body to get user info
          final responseData = jsonDecode(response.body);
          _userId = responseData['userId'] ?? responseData['user']?['id'];
          _userEmail = email;

          // Save session
          await _saveSession();

          return LoginResult.success(userId: _userId!, email: email);
        } else {
          return LoginResult.failure(error: 'No session cookie received');
        }
      } else {
        final errorData = jsonDecode(response.body);
        return LoginResult.failure(error: errorData['error'] ?? 'Login failed');
      }
    } catch (e) {
      return LoginResult.failure(error: 'Network error: $e');
    }
  }

  /// Register a new user
  Future<LoginResult> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/email/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'name': name}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Extract session cookie from response headers
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          _sessionCookie = _extractSessionCookie(cookies);

          // Parse response body to get user info
          final responseData = jsonDecode(response.body);
          _userId = responseData['userId'] ?? responseData['user']?['id'];
          _userEmail = email;

          // Save session
          await _saveSession();

          return LoginResult.success(userId: _userId!, email: email);
        } else {
          return LoginResult.failure(error: 'No session cookie received');
        }
      } else {
        final errorData = jsonDecode(response.body);
        return LoginResult.failure(
          error: errorData['error'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      return LoginResult.failure(error: 'Network error: $e');
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    try {
      if (_sessionCookie != null) {
        await http.post(
          Uri.parse('$_baseUrl/api/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Cookie': _sessionCookie!,
          },
        );
      }
    } catch (e) {
      // Ignore errors during logout
    } finally {
      await _clearSession();
    }
  }

  /// Verify current session is still valid
  Future<bool> verifySession() async {
    if (!isAuthenticated) return false;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/session'),
        headers: {'Cookie': _sessionCookie!},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        await _clearSession();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Extract session cookie from Set-Cookie header
  String _extractSessionCookie(String setCookieHeader) {
    // The cookie might be in format: "session=value; Path=/; HttpOnly"
    // We need to extract just the session=value part
    final cookies = setCookieHeader.split(',');
    for (final cookie in cookies) {
      final parts = cookie.trim().split(';');
      if (parts.isNotEmpty) {
        final cookiePair = parts[0].trim();
        if (cookiePair.startsWith('session=') ||
            cookiePair.contains('auth') ||
            cookiePair.contains('token')) {
          return cookiePair;
        }
      }
    }
    // If no specific session cookie found, return the first cookie
    return cookies.first.split(';').first.trim();
  }

  /// Save session to persistent storage
  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_sessionCookie != null) {
      await prefs.setString(_sessionTokenKey, _sessionCookie!);
    }
    if (_userId != null) {
      await prefs.setString(_userIdKey, _userId!);
    }
    if (_userEmail != null) {
      await prefs.setString(_userEmailKey, _userEmail!);
    }
  }

  /// Clear session from memory and storage
  Future<void> _clearSession() async {
    _sessionCookie = null;
    _userId = null;
    _userEmail = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
  }
}

/// Result of login/register operation
class LoginResult {
  final bool success;
  final String? userId;
  final String? email;
  final String? error;

  LoginResult._({required this.success, this.userId, this.email, this.error});

  factory LoginResult.success({required String userId, required String email}) {
    return LoginResult._(success: true, userId: userId, email: email);
  }

  factory LoginResult.failure({required String error}) {
    return LoginResult._(success: false, error: error);
  }
}
