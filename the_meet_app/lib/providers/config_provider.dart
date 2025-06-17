import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigProvider with ChangeNotifier {
  bool _isLoading = false;
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  final bool _isDemo = false;  // Set to false to use real Firebase
  
  bool get isLoading => _isLoading;
  bool get isDemo => _isDemo;
  
  ConfigProvider() {
    // Don't call any async operations directly in the constructor
  }
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Always use production mode (no demo mode)
      await _prefs?.setBool('demo_mode', false);
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}