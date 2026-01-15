/// SyncUp - Social Media Application
/// A modern Flutter app combining features from TikTok and Instagram
/// with reels, stories, posts, and live streaming capabilities.
/// 
/// Built with:
/// - Flutter 3.9.2
/// - Supabase for backend (Auth, Database, Storage)
/// - Provider for state management
/// - GoRouter for navigation
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/app_router.dart';
import 'core/services/preferences_service.dart';
import 'core/services/back_navigation_settings_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/post_provider.dart';
import 'core/config/supabase_config.dart';

/// Main entry point of the application
/// Initializes all required services before launching the app:
/// 1. Supabase (Auth, Database, Storage)
/// 2. Shared Preferences for local storage
/// 3. Back navigation settings
Future<void> main() async {
  // Ensure Flutter framework is initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase client with PKCE auth flow for enhanced security
  // PKCE (Proof Key for Code Exchange) protects against authorization code interception
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // Enhanced security for OAuth flow
    ),
  );

  // Initialize Shared Preferences for local data persistence
  // Used for user preferences, cache, and offline data
  await PreferencesService.init();

  // Initialize Back Navigation Settings Service
  // Manages custom back button behavior throughout the app
  await BackNavigationSettingsService.instance.initialize();

  runApp(const App());
}

/// Root widget of the SyncUp application
/// Sets up:
/// - Global state management providers (Auth, Posts)
/// - Theme configuration (light & dark modes)
/// - Routing with GoRouter
class App extends StatelessWidget {
  const App({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Global providers accessible throughout the app
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()), // User authentication state
        ChangeNotifierProvider(create: (_) => PostProvider()),  // Posts and feed state
      ],
      child: MaterialApp.router(
        title: 'Syncup',
        theme: buildAppTheme(),
        darkTheme: buildDarkAppTheme(),
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
      ),
    );
  }
}
