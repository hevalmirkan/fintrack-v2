import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/di/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('tr_TR', null);

  final prefs = await SharedPreferences.getInstance();

  try {
    final savedUserId = prefs.getString('anonymous_user_id');

    if (savedUserId != null) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null || currentUser.uid != savedUserId) {
        await FirebaseAuth.instance.signInAnonymously();
        final newUserId = FirebaseAuth.instance.currentUser?.uid;
        if (newUserId != null) {
          await prefs.setString('anonymous_user_id', newUserId);
        }
      }
    } else {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      await FirebaseAuth.instance.signInAnonymously();

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await prefs.setString('anonymous_user_id', userId);
      }
    }
  } catch (e) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await prefs.setString('anonymous_user_id', userId);
      }
    } catch (_) {
      // Silent fail - app will work without authentication
    }
  }

  // 4. App'i başlat

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FinTrack',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      locale: const Locale('tr', 'TR'),
    );
  }
}
