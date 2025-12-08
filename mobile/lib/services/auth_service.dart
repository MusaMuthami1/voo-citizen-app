import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  // Supabase REST API base URL (for backwards compatibility)
  static const String baseUrl = '${SupabaseService.supabaseUrl}/rest/v1';
  
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
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Format phone number
      String formattedPhone = phone;
      if (!phone.startsWith('+254')) {
        formattedPhone = '+254$phone';
      }

      final result = await SupabaseService.login(
        phone: formattedPhone,
        password: password,
      );

      if (result['success'] == true) {
        _user = result['user'];
        _token = 'supabase_session_${DateTime.now().millisecondsSinceEpoch}';
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', jsonEncode(_user));
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

  Future<Map<String, dynamic>> register(String fullName, String phone, String idNumber, String password, {String? village}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Format phone number
      String formattedPhone = phone;
      if (!phone.startsWith('+254')) {
        formattedPhone = '+254$phone';
      }

      final result = await SupabaseService.register(
        fullName: fullName,
        phone: formattedPhone,
        idNumber: idNumber,
        password: password,
        village: village,
      );

      if (result['success'] == true) {
        _user = result['user'];
        _token = 'supabase_session_${DateTime.now().millisecondsSinceEpoch}';
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', jsonEncode(_user));
        notifyListeners();
        return {'success': true};
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

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
