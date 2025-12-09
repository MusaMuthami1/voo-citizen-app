import 'dart:convert';
import 'package:http/http.dart' as http;

/// Dashboard API Service - Connects mobile app to USSD Dashboard
/// Uses the citizen portal endpoints for shared data (issues, bursaries, announcements)
class DashboardService {
  // Production dashboard URL
  static const String dashboardUrl = 'https://voo-ward-ussd-1.onrender.com';
  static const String apiBase = '$dashboardUrl/api/citizen';
  
  // Session token (obtained after login)
  static String? _sessionToken;
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_sessionToken != null) 'Authorization': 'Bearer $_sessionToken',
  };

  // ============ AUTH ============
  
  /// Request OTP for login
  static Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': 'Request failed: $e'};
    }
  }

  /// Verify OTP and login
  static Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber, 'otp': otp}),
      );
      
      final data = jsonDecode(res.body);
      if (data['success'] == true && data['token'] != null) {
        _sessionToken = data['token'];
      }
      return data;
    } catch (e) {
      return {'success': false, 'error': 'Login failed: $e'};
    }
  }

  /// Set session token (for when using Supabase auth but dashboard API)
  static void setToken(String token) {
    _sessionToken = token;
  }

  /// Clear session
  static void clearSession() {
    _sessionToken = null;
  }

  // ============ ANNOUNCEMENTS (PUBLIC) ============
  
  /// Get announcements - PUBLIC, no auth required
  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBase/announcements'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('Get announcements error: $e');
      return [];
    }
  }

  // ============ ISSUES ============
  
  /// Get user's issues
  static Future<List<Map<String, dynamic>>> getMyIssues() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBase/issues'),
        headers: _headers,
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('Get issues error: $e');
      return [];
    }
  }

  /// Submit new issue with images via mobile endpoint (PUBLIC - no auth required)
  /// Uses /api/citizen/mobile/issues endpoint which accepts base64 images
  static Future<Map<String, dynamic>> submitMobileIssue({
    required String phoneNumber,
    required String title,
    required String category,
    required String description,
    String? location,
    List<String>? images, // base64 encoded images
    String? userId,
    String? fullName,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/mobile/issues'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'title': title,
          'category': category,
          'description': description,
          'location': location,
          'images': images ?? [],
          'userId': userId,
          'fullName': fullName,
        }),
      );
      
      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        return {'success': true, ...data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Submit failed'};
      }
    } catch (e) {
      print('Submit mobile issue error: $e');
      return {'success': false, 'error': 'Submit failed: $e'};
    }
  }

  /// Legacy submitIssue (requires citizen portal auth)
  static Future<Map<String, dynamic>> submitIssue({
    required String title,
    required String category,
    required String description,
    String? location,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/issues'),
        headers: _headers,
        body: jsonEncode({
          'title': title,
          'category': category,
          'description': description,
          'location': location,
        }),
      );
      
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': 'Submit failed: $e'};
    }
  }


  // ============ BURSARY ============
  
  /// Get user's bursary applications
  static Future<List<Map<String, dynamic>>> getMyBursaryApplications() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBase/bursaries'),
        headers: _headers,
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('Get bursaries error: $e');
      return [];
    }
  }

  /// Submit bursary application via mobile endpoint (PUBLIC - no auth required)
  /// Uses /api/citizen/mobile/bursaries endpoint which stores directly to MongoDB
  static Future<Map<String, dynamic>> applyForBursary({
    required String institutionName,
    required String course,
    required String yearOfStudy,
    String? institutionType,
    String? reason,
    double? amountRequested,
    String? phoneNumber,
    String? userId,
    String? fullName,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/mobile/bursaries'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'institutionName': institutionName,
          'course': course,
          'yearOfStudy': yearOfStudy,
          'institutionType': institutionType,
          'reason': reason,
          'amountRequested': amountRequested,
          'phoneNumber': phoneNumber,
          'userId': userId,
          'fullName': fullName,
        }),
      );
      
      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        return {'success': true, ...data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Application failed'};
      }
    } catch (e) {
      print('Apply bursary error: $e');
      return {'success': false, 'error': 'Application failed: $e'};
    }
  }
}
