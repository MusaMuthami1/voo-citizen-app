import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'dashboard_service.dart';

class AuthService extends ChangeNotifier {
  // Supabase REST API base URL (for backwards compatibility)
  static const String baseUrl = '${SupabaseService.supabaseUrl}/rest/v1';
  
  // Session expires after 6 days of inactivity (in milliseconds)
  static const int sessionTimeoutDays = 6;
  static const int sessionTimeoutMs = sessionTimeoutDays * 24 * 60 * 60 * 1000;
  
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;

  AuthService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userData = prefs.getString('user');
    if (userData != null) _user = jsonDecode(userData);
    
    // Check for session expiry (6 days of inactivity)
    final lastActivity = prefs.getInt('last_activity');
    if (_token != null && lastActivity != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastActivity > sessionTimeoutMs) {
        // Session expired, force logout
        await logout();
        return;
      }
    }
    
    // Update last activity timestamp
    if (_token != null) {
      await prefs.setInt('last_activity', DateTime.now().millisecondsSinceEpoch);
    }
    
    notifyListeners();
  }

  // Call this method when user performs any action to keep session alive
  Future<void> updateLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_activity', DateTime.now().millisecondsSinceEpoch);
  }

  /// Set user state from Google sign-in
  Future<void> setGoogleUser(Map<String, dynamic> userData) async {
    _token = 'google_session_${DateTime.now().millisecondsSinceEpoch}';
    _user = userData;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('user', jsonEncode(_user));
    await prefs.setInt('last_activity', DateTime.now().millisecondsSinceEpoch);
    
    notifyListeners();
  }

  /// Reload user data from SharedPreferences (useful after external login)
  Future<void> reloadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userData = prefs.getString('user');
    if (userData != null) _user = jsonDecode(userData);
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try dashboard login first (new mobile user system)
      final result = await DashboardService.loginUser(username, password);

      if (result['success'] == true) {
        _user = result['user'];
        _token = result['token'] ?? 'dashboard_session_${DateTime.now().millisecondsSinceEpoch}';
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', jsonEncode(_user));
        await prefs.setInt('last_activity', DateTime.now().millisecondsSinceEpoch);
        notifyListeners();
        return {'success': true};
      } else {
        return {'success': false, 'error': result['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error. Please check your connection.'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> register(String fullName, String phone, String idNumber, String password, {String? village, String? username}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Format phone number
      String formattedPhone = phone;
      if (!phone.startsWith('+254')) {
        formattedPhone = '+254$phone';
      }

      // Use dashboard mobile registration
      final result = await DashboardService.registerUser(
        fullName: fullName,
        username: username ?? phone.replaceAll('+254', ''),
        phoneNumber: formattedPhone,
        password: password,
        nationalId: idNumber,
        village: village,
      );

      if (result['success'] == true) {
        // Don't auto-login, redirect to login screen with username pre-filled
        return {'success': true, 'username': username ?? phone.replaceAll('+254', '')};
      } else {
        return {'success': false, 'error': result['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error. Please check your connection.'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String phone,
    String? email,
    String? village,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_user == null) {
        return {'success': false, 'error': 'No user logged in'};
      }

      // Format phone number
      String formattedPhone = phone;
      if (!phone.startsWith('+254')) {
        formattedPhone = '+254$phone';
      }

      final userId = _user!['id'].toString();
      
      final result = await SupabaseService.updateUserProfile(
        userId: userId,
        fullName: fullName,
        phone: formattedPhone,
        email: email,
        village: village,
      );

      if (result['success'] == true) {
        // Update local user state if new data returned, otherwise just update fields we know changed
        if (result['user'] != null) {
          _user = result['user'];
        } else {
          // Fallback manual update if server didn't return object
          _user!['fullName'] = fullName;
          _user!['phone'] = formattedPhone;
          if (email != null) _user!['email'] = email;
          if (village != null) _user!['village'] = village;
        }

        // Persist to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user));
        
        notifyListeners();
        return {'success': true};
      } else {
        return {'success': false, 'error': result['error'] ?? 'Update failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Update failed: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_user == null) {
        return {'success': false, 'error': 'No user logged in'};
      }

      final userId = _user!['id'].toString();
      final result = await SupabaseService.deleteUser(userId);

      if (result['success'] == true) {
        // Clear local data
        await logout();
        return {'success': true};
      } else {
        return {'success': false, 'error': result['error'] ?? 'Failed to delete account'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Delete failed: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
