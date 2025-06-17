import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeType {
  dark,
  light,
  blackAmoled,
  blueDark,
  bluishLight,
  greenLight
}

class ThemeProvider with ChangeNotifier {
  ThemeType _currentTheme = ThemeType.dark;
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  
  // Cached theme data to avoid rebuilding
  ThemeData? _darkTheme;
  ThemeData? _lightTheme;
  ThemeData? _blackAmoledTheme;
  ThemeData? _blueDarkTheme;
  ThemeData? _bluishLightTheme;
  ThemeData? _greenLightTheme;

  ThemeType get currentTheme => _currentTheme;
  bool get isInitialized => _isInitialized;

  // Static method to preload theme before app starts
  static Future<ThemeProvider> preloadTheme() async {
    final provider = ThemeProvider(loadSync: true);
    await provider._loadThemeSync();
    return provider;
  }

  // Search bar color getter based on theme
  Color get searchBarColor {
    switch (_currentTheme) {
      case ThemeType.dark:
      case ThemeType.blackAmoled:
      case ThemeType.blueDark:
        return Colors.grey[800]!;
      case ThemeType.light:
      case ThemeType.bluishLight:
      case ThemeType.greenLight:
        return Colors.white;
    }
  }

  // Search bar icon color getter based on theme
  Color get searchBarIconColor {
    switch (_currentTheme) {
      case ThemeType.dark:
      case ThemeType.blackAmoled:
      case ThemeType.blueDark:
        return Colors.grey[400]!;
      case ThemeType.light:
      case ThemeType.bluishLight:
      case ThemeType.greenLight:
        return Colors.grey[600]!;
    }
  }

  // Background color for filter chips
  Color get filterChipBackgroundColor {
    switch (_currentTheme) {
      case ThemeType.dark:
        return Colors.grey[700]!;
      case ThemeType.blackAmoled:
        return Colors.grey[900]!;
      case ThemeType.blueDark:
        return const Color(0xFF223050);
      case ThemeType.light:
        return Colors.grey[300]!;
      case ThemeType.bluishLight:
        return const Color(0xFFD4E6F9);
      case ThemeType.greenLight:
        return const Color(0xFFDCEDC8);
    }
  }

  // Secondary text color
  Color get secondaryTextColor {
    switch (_currentTheme) {
      case ThemeType.dark:
      case ThemeType.blackAmoled:
        return Colors.grey[400]!;
      case ThemeType.blueDark:
        return Colors.grey[400]!;
      case ThemeType.light:
      case ThemeType.bluishLight:
      case ThemeType.greenLight:
        return Colors.grey[700]!;
    }
  }

  // Card background color
  Color get cardBackgroundColor {
    switch (_currentTheme) {
      case ThemeType.dark:
        return Colors.grey[850]!;
      case ThemeType.blackAmoled:
        return const Color(0xFF121212);
      case ThemeType.blueDark:
        return const Color(0xFF223050);
      case ThemeType.light:
      case ThemeType.bluishLight:
      case ThemeType.greenLight:
        return Colors.white;
    }
  }

  // Secondary background color
  Color get secondaryBackgroundColor {
    switch (_currentTheme) {
      case ThemeType.dark:
        return Colors.grey[800]!;
      case ThemeType.blackAmoled:
        return Colors.grey[900]!;
      case ThemeType.blueDark:
        return const Color(0xFF1E2746);
      case ThemeType.light:
        return Colors.grey[200]!;
      case ThemeType.bluishLight:
        return const Color(0xFFEBF5FE);
      case ThemeType.greenLight:
        return const Color(0xFFF1F8E9);
    }
  }

  // Card border color
  Color get cardBorderColor {
    switch (_currentTheme) {
      case ThemeType.dark:
      case ThemeType.blueDark:
        return Colors.grey[800]!;
      case ThemeType.blackAmoled:
        return Colors.transparent;
      case ThemeType.light:
      case ThemeType.bluishLight:
      case ThemeType.greenLight:
        return Colors.grey[200]!;
    }
  }

  // Icon color
  Color get iconColor {
    switch (_currentTheme) {
      case ThemeType.dark:
      case ThemeType.blackAmoled:
      case ThemeType.blueDark:
        return Colors.grey[400]!;
      case ThemeType.light:
        return Colors.grey[600]!;
      case ThemeType.bluishLight:
        return const Color(0xFF2196F3).withOpacity(0.8);
      case ThemeType.greenLight:
        return const Color(0xFF4CAF50).withOpacity(0.8);
    }
  }

  // Border color
  Color get borderColor {
    switch (_currentTheme) {
      case ThemeType.dark:
      case ThemeType.blackAmoled:
      case ThemeType.blueDark:
        return Colors.grey[700]!;
      case ThemeType.light:
      case ThemeType.bluishLight:
      case ThemeType.greenLight:
        return Colors.grey[300]!;
    }
  }

  // Theme data getters - Use lazy loading
  ThemeData get theme {
    switch (_currentTheme) {
      case ThemeType.light:
        return _lightTheme ??= _createLightTheme();
      case ThemeType.dark:
        return _darkTheme ??= _createDarkTheme();
      case ThemeType.blackAmoled:
        return _blackAmoledTheme ??= _createBlackAmoledTheme();
      case ThemeType.blueDark:
        return _blueDarkTheme ??= _createBlueDarkTheme();
      case ThemeType.bluishLight:
        return _bluishLightTheme ??= _createBluishLightTheme();
      case ThemeType.greenLight:
        return _greenLightTheme ??= _createGreenLightTheme();
    }
  }

  // Method to get ThemeData for a specific ThemeType
  ThemeData getThemeDataByType(ThemeType type) {
    switch (type) {
      case ThemeType.light:
        return _lightTheme ??= _createLightTheme();
      case ThemeType.dark:
        return _darkTheme ??= _createDarkTheme();
      case ThemeType.blackAmoled:
        return _blackAmoledTheme ??= _createBlackAmoledTheme();
      case ThemeType.blueDark:
        return _blueDarkTheme ??= _createBlueDarkTheme();
      case ThemeType.bluishLight:
        return _bluishLightTheme ??= _createBluishLightTheme();
      case ThemeType.greenLight:
        return _greenLightTheme ??= _createGreenLightTheme();
    }
  }

  // Helper to get string name for a theme type
  String getThemeName(ThemeType type) {
    switch (type) {
      case ThemeType.dark:
        return 'Dark';
      case ThemeType.light:
        return 'Light';
      case ThemeType.blackAmoled:
        return 'Black AMOLED';
      case ThemeType.blueDark:
        return 'Blue Dark';
      case ThemeType.bluishLight:
        return 'Blue Light';
      case ThemeType.greenLight:
        return 'Green Light';
    }
  }

  // Constructor with optional sync loading
  ThemeProvider({bool loadSync = false}) {
    if (!loadSync) {
      _loadTheme();
    }
  }

  // Load the saved theme
  Future<void> _loadTheme() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedTheme = _prefs.getString('theme');
      
      if (savedTheme == null) {
        _isInitialized = true;
        notifyListeners();
        return;
      }
      
      // Convert the saved string to enum
      for (var type in ThemeType.values) {
        if (savedTheme == type.toString()) {
          _currentTheme = type;
          break;
        }
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  // Synchronous version of load theme for preloading
  Future<void> _loadThemeSync() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedTheme = _prefs.getString('theme');
      
      if (savedTheme != null) {
        // Convert the saved string to enum
        for (var type in ThemeType.values) {
          if (savedTheme == type.toString()) {
            _currentTheme = type;
            break;
          }
        }
      }
      
      _isInitialized = true;
    } catch (e) {
      print('Error loading theme synchronously: $e');
    }
  }

  // Set theme method
  Future<void> setTheme(ThemeType theme) async {
    _currentTheme = theme;
    await _prefs.setString('theme', theme.toString());
    notifyListeners();
  }

  // Create dark theme
  ThemeData _createDarkTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF8C00),
        secondary: Color(0xFF6C63FF),
        surface: Color(0xFF1E1E1E),
        error: Color(0xFFCF6679),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8C00),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFFF8C00),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: Color(0xFFFF8C00),
        unselectedItemColor: Colors.grey,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.grey[800],
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // Create light theme
  ThemeData _createLightTheme() {
    return ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFFF8C00),
        secondary: Color(0xFF6C63FF),
        surface: Colors.white,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8C00),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFFF8C00),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFFFF8C00),
        unselectedItemColor: Colors.grey,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F8F8),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // Create Black AMOLED theme
  ThemeData _createBlackAmoledTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF8C00),
        secondary: Color(0xFF6C63FF),
        surface: Colors.black,
        error: Color(0xFFCF6679),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8C00),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFFF8C00),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: Color(0xFFFF8C00),
        unselectedItemColor: Colors.grey,
      ),
      scaffoldBackgroundColor: Colors.black,
      inputDecorationTheme: InputDecorationTheme(
        fillColor: const Color(0xFF121212),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // Create Blue Dark theme
  ThemeData _createBlueDarkTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4D8AF0),
        secondary: Color(0xFF64B5F6),
        surface: Color(0xFF1A2035),
        error: Color(0xFFCF6679),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A2035),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF223050),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4D8AF0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4D8AF0),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A2035),
        selectedItemColor: Color(0xFF4D8AF0),
        unselectedItemColor: Colors.grey,
      ),
      scaffoldBackgroundColor: const Color(0xFF121726),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.grey[800],
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // Create Bluish Light theme
  ThemeData _createBluishLightTheme() {
    return ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2196F3),
        secondary: Color(0xFF03A9F4),
        surface: Colors.white,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF2196F3),
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF2196F3),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF2196F3),
        unselectedItemColor: Colors.grey,
      ),
      scaffoldBackgroundColor: const Color(0xFFEDF4FB),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // Create Green Light theme
  ThemeData _createGreenLightTheme() {
    return ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4CAF50),
        secondary: Color(0xFF8BC34A),
        surface: Colors.white,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF4CAF50),
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4CAF50),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
      ),
      scaffoldBackgroundColor: const Color(0xFFF1F8E9),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}