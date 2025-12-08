import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'providers/theme_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SupabaseService.initialize();
  await NotificationService.initialize();
  await StorageService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const VooCitizenApp(),
    ),
  );
}

class VooCitizenApp extends StatelessWidget {
  const VooCitizenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'VOO Citizen',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          home: Consumer<AuthService>(
            builder: (context, auth, _) {
              return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}

