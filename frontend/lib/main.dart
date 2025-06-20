/**
 * Sherlock - AI-Powered Deepfake Video Detection App
 * 
 * Main application entry point that sets up the app configuration,
 * theme, routing, and state management providers.
 * 
 * Architecture:
 * - Uses Provider for state management
 * - GoRouter for navigation
 * - Material 3 design system
 * - Responsive design patterns
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/video_upload_provider.dart';
import 'providers/results_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/results_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/constants.dart';
import 'utils/themes.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const SherlockApp());
}

class SherlockApp extends StatelessWidget {
  const SherlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // State management providers
        ChangeNotifierProvider(create: (_) => VideoUploadProvider()),
        ChangeNotifierProvider(create: (_) => ResultsProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            
            // Theme configuration
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: settings.themeMode,
            
            // Routing configuration
            routerConfig: _router,
            
            // Global app settings
            builder: (context, child) {
              return MediaQuery(
                // Ensure text doesn't scale beyond reasonable limits
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: MediaQuery.of(context)
                      .textScaleFactor
                      .clamp(0.8, 1.2),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}

/// App routing configuration using GoRouter
final GoRouter _router = GoRouter(
  routes: [
    // Home route
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    
    // Upload route
    GoRoute(
      path: '/upload',
      name: 'upload',
      builder: (context, state) => const UploadScreen(),
    ),
    
    // Results route with task ID parameter
    GoRoute(
      path: '/results/:taskId',
      name: 'results',
      builder: (context, state) {
        final taskId = state.pathParameters['taskId']!;
        return ResultsScreen(taskId: taskId);
      },
    ),
    
    // History route
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (context, state) => const HistoryScreen(),
    ),
    
    // Settings route
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
  
  // Error handling
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(
      title: const Text('Page Not Found'),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Page not found: ${state.uri}',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
  
  // Redirect logic (if needed)
  redirect: (context, state) {
    // Add any authentication or conditional routing logic here
    return null; // No redirect needed for now
  },
); 