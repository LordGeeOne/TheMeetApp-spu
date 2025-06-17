import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:the_meet_app/providers/auth_provider.dart';
import 'package:the_meet_app/providers/config_provider.dart';
import 'package:the_meet_app/providers/meet_provider.dart';
import 'package:the_meet_app/providers/user_provider.dart';
import 'package:the_meet_app/providers/theme_provider.dart';
import 'package:the_meet_app/providers/safe_button_provider.dart'; // Import SafeButtonProvider
import 'package:the_meet_app/providers/panic_button_provider.dart'; // Import PanicButtonProvider
import 'package:the_meet_app/services/panic_button_service.dart'; // Import PanicButtonService
import 'package:the_meet_app/services/global_safewalk_service.dart'; // Import GlobalSafeWalkService
import 'package:the_meet_app/screens/login_screen.dart';
import 'package:the_meet_app/screens/map_screen.dart';
import 'package:the_meet_app/screens/profile_page.dart';
import 'package:the_meet_app/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:the_meet_app/models/meet.dart';
import 'package:the_meet_app/widgets/main_navigation_bar.dart';
import 'package:the_meet_app/services/service_locator.dart';
import 'package:the_meet_app/services/firebase_options.dart';
import 'package:the_meet_app/providers/chat_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Add this import
import 'package:flutter/foundation.dart'; // Import for kDebugMode

void main() async {
  // This ensures Flutter is properly initialized before we do anything else
  WidgetsFlutterBinding.ensureInitialized();

  // Show a loading app while Firebase initializes
  runApp(const LoadingApp());

  try {
    // Initialize Firebase in a non-blocking way
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase App Check
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug, 
      appleProvider: AppleProvider.debug,     
    );
    print('Firebase App Check activated with debug providers.');

    // Explicitly get and print the Android debug token if in debug mode and on Android
    if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
      String? token = await FirebaseAppCheck.instance.getToken(true);
      print('ANDROID DEBUG TOKEN (if this is Android): $token');
    }

    // Enable Firestore offline persistence with 10MB cache size
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true, 
      cacheSizeBytes: 10485760,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue anyway - Firebase might already be initialized
  }
  
  // Initialize config provider (keep this lightweight)
  final configProvider = ConfigProvider();
  await configProvider.initialize();
  
  // Initialize ServiceLocator with the config provider
  ServiceLocator.setup(configProvider);

  // Preload theme before app starts to avoid theme flicker
  final themeProvider = await ThemeProvider.preloadTheme();  // Now run the actual app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => configProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider(configProvider, delayInit: true)),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MeetProvider(configProvider: configProvider)),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SafeButtonProvider()),
        ChangeNotifierProvider(create: (_) => PanicButtonProvider()),
        ChangeNotifierProvider.value(value: themeProvider), // Use the preloaded theme provider
      ],
      child: const MyApp(),
    ),
  );
}

// Simple loading screen while Firebase initializes
class LoadingApp extends StatelessWidget {
  const LoadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF121212),
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF8C00),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFFFF8C00),
        ),
      ),
      home: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Delay initialization to next frame to avoid blocking the UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }  Future<void> _initializeProviders() async {
    if (_initialized) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Trigger auth initialization now that the UI is ready
      await authProvider.initializeAsync();
        // Only after auth is initialized, initialize user provider
      if (mounted && authProvider.isAuthenticated && authProvider.user != null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.loadUserData(authProvider.user!.uid);
      }
        // Initialize panic button service
      if (mounted) {
        final safeButtonProvider = Provider.of<SafeButtonProvider>(context, listen: false);
        
        // Initialize the panic button service with dependencies
        PanicButtonService().initialize(safeButtonProvider, context);
        
        // Initialize global SafeWalk monitoring service
        GlobalSafeWalkService().initialize(authProvider);
      }
      
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      print('Error during app initialization: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the theme from the ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'The Meet App',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.theme, // Use the theme from ThemeProvider
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Show a loading indicator if auth is still initializing
          if (!_initialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return authProvider.isAuthenticated
              ? const MainNavigationBar()
              : const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainNavigationBar(),
        '/map': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Meet) {
            return MapScreen(meet: args);
          }
          return const Scaffold(body: Center(child: Text('No meet provided.')));
        },
        '/profile': (context) => const ProfilePage(),
        '/settings': (context) => const SettingsScreen(), // Add SettingsScreen route
      },
    );
  }
}