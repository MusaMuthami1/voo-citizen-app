import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

/// Service to check for app updates and force users to update
class AppUpdateService {
  // Current app version - update this when releasing new versions
  static const String currentVersion = '1.0.1';
  static const int currentVersionCode = 2;

  /// Check if an update is required
  static Future<Map<String, dynamic>> checkForUpdate() async {
    try {
      // Fetch minimum required version from Supabase
      final url = '${SupabaseService.supabaseUrl}/rest/v1/app_config?key=eq.min_version&select=value';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': SupabaseService.supabaseAnonKey,
          'Authorization': 'Bearer ${SupabaseService.supabaseAnonKey}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final minVersion = data[0]['value'];
          final isUpdateRequired = _compareVersions(currentVersion, minVersion) < 0;
          
          // Get download URL
          final urlResponse = await http.get(
            Uri.parse('${SupabaseService.supabaseUrl}/rest/v1/app_config?key=eq.download_url&select=value'),
            headers: {
              'apikey': SupabaseService.supabaseAnonKey,
              'Authorization': 'Bearer ${SupabaseService.supabaseAnonKey}',
            },
          );
          
          String downloadUrl = 'https://github.com/MuthamiM/voo-citizen-app/releases/latest';
          if (urlResponse.statusCode == 200) {
            final urlData = jsonDecode(urlResponse.body);
            if (urlData.isNotEmpty) {
              downloadUrl = urlData[0]['value'];
            }
          }

          return {
            'updateRequired': isUpdateRequired,
            'currentVersion': currentVersion,
            'minVersion': minVersion,
            'downloadUrl': downloadUrl,
          };
        }
      }

      // If we can't check, assume no update needed
      return {'updateRequired': false, 'currentVersion': currentVersion};
    } catch (e) {
      // On error, don't block the user
      return {'updateRequired': false, 'currentVersion': currentVersion, 'error': e.toString()};
    }
  }

  /// Compare version strings (e.g., "1.0.0" vs "1.0.1")
  /// Returns: negative if v1 < v2, positive if v1 > v2, 0 if equal
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) return p1 - p2;
    }
    return 0;
  }

  /// Show update dialog with Update Now or Later options
  static void showUpdateDialog(BuildContext context, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a3e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Color(0xFF6366f1), size: 28),
            SizedBox(width: 8),
            Text('Update Available', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version of VOO Citizen App is available. Update now for the best experience!',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366f1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6366f1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF6366f1), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Current: v$currentVersion',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Later',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              // Open download URL - would use url_launcher in production
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Download from: $downloadUrl'),
                  duration: const Duration(seconds: 10),
                  action: SnackBarAction(
                    label: 'Copy',
                    onPressed: () {},
                  ),
                ),
              );
            },
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text('Update Now', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
          ),
        ],
      ),
    );
  }
}
