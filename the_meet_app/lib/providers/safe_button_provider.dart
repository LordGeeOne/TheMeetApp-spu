import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

import '../models/safe_button.dart';

class SafeButtonProvider with ChangeNotifier {
  List<SafeButton> _safeButtons = [];
  bool _isListening = false;
  bool _isRecordingButton = false;
  String? _lastButtonPressed;
  SafeButton? _lastDetectedButton;
  Timer? _recordingTimer;
  final int _recordingTimeout = 10; // 10 seconds to detect a button press
  int _remainingTime = 10;
  
  // Method channel for native button detection
  static const platform = MethodChannel('com.echoless.the_meet_app/volume_buttons');
  
  // Getters
  List<SafeButton> get safeButtons => _safeButtons;
  bool get isListening => _isListening;
  bool get isRecordingButton => _isRecordingButton;
  String? get lastButtonPressed => _lastButtonPressed;
  SafeButton? get lastDetectedButton => _lastDetectedButton;
  int get remainingTime => _remainingTime;
  
  // Constructor
  SafeButtonProvider() {
    _loadButtons();
    _setupButtonListener();
  }
  // Setup the platform channel listener
  void _setupButtonListener() {
    debugPrint('SafeButtonProvider: Setting up button listener on channel: ${platform.name}');
    
    // Listen for volume button presses
    platform.setMethodCallHandler((call) async {
      debugPrint('SafeButtonProvider: Received method call: ${call.method}');
      
      if (call.method == 'buttonPressed') {
        final String action = call.arguments['action'];
        final String type = call.arguments['type'] ?? 'volume';
        
        debugPrint('SafeButtonProvider: Button press detected - action: $action, type: $type');
        _onButtonEvent(action, type);
        return true;
      }
      return null;
    });
    
    debugPrint('SafeButtonProvider: Button listener setup complete');
  }

  // Load saved buttons from SharedPreferences
  Future<void> _loadButtons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final buttonsJson = prefs.getStringList('safe_buttons') ?? [];
      
      if (buttonsJson.isNotEmpty) {
        _safeButtons = buttonsJson
            .map((json) => SafeButton.fromMap(jsonDecode(json)))
            .toList();
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading safe buttons: $e');
    }
  }
  
  // Save buttons to SharedPreferences
  Future<void> _saveButtons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final buttonsJson = _safeButtons
          .map((button) => jsonEncode(button.toMap()))
          .toList();
      
      await prefs.setStringList('safe_buttons', buttonsJson);
    } catch (e) {
      debugPrint('Error saving safe buttons: $e');
    }
  }
    // Start listening for button presses during test mode
  Future<void> startListening() async {
    if (_isListening) return;
    
    try {
      debugPrint('SafeButtonProvider: Starting button detection...');
      // Initialize platform channel listening
      final result = await platform.invokeMethod('startListening');
      debugPrint('SafeButtonProvider: Start listening result: $result');
      
      _isListening = true;
      _lastButtonPressed = null;
      notifyListeners();
      debugPrint('SafeButtonProvider: Now listening for buttons, isListening = $_isListening');
    } catch (e) {
      debugPrint('Error starting button detection: $e');
    }
  }
    // Stop listening for button presses
  Future<void> stopListening() async {
    if (!_isListening) {
      debugPrint('SafeButtonProvider: Already not listening, nothing to stop');
      return;
    }
    
    try {
      debugPrint('SafeButtonProvider: Stopping button detection...');
      // Tell native code to stop listening
      final result = await platform.invokeMethod('stopListening');
      debugPrint('SafeButtonProvider: Stop listening result: $result');
      
      _isListening = false;
      notifyListeners();
      debugPrint('SafeButtonProvider: Stopped listening for buttons');
    } catch (e) {
      debugPrint('Error stopping button detection: $e');
    }
  }
  // Handle button events from the native side
  void _onButtonEvent(String action, String type) {
    debugPrint('SafeButtonProvider: Processing button event: $action ($type), isListening: $_isListening');
    
    _lastButtonPressed = action;
      
    // Find if this button is one of our safe buttons
    try {
      _lastDetectedButton = _safeButtons.firstWhere(
        (button) => button.action == action && button.type == type,
      );
      debugPrint('SafeButtonProvider: Matched button: ${_lastDetectedButton?.name}');
    } catch (e) {
      // No matching button found
      _lastDetectedButton = null;
      debugPrint('SafeButtonProvider: No matching button found');
    }
    
    // If recording a button, store it
    if (_isRecordingButton) {
      debugPrint('SafeButtonProvider: Recording mode active, storing button');
      _stopRecordingButton(action, type);
    }
    
    notifyListeners();
    debugPrint('SafeButtonProvider: Event processed, listeners notified');
  }
    // Start recording a new button
  void startRecordingButton() async {
    if (_isRecordingButton) return;
    
    debugPrint('SafeButtonProvider: Starting button recording mode');
    _isRecordingButton = true;
    _remainingTime = _recordingTimeout;
    _lastButtonPressed = null;
    
    // Start a timer to automatically cancel if no button is pressed
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingTime--;
      debugPrint('SafeButtonProvider: Recording countdown: $_remainingTime');
      
      if (_remainingTime <= 0) {
        debugPrint('SafeButtonProvider: Recording timed out');
        cancelRecording();
      }
      
      notifyListeners();
    });
    
    // Start listening for button presses if not already - make sure to await this
    if (!_isListening) {
      debugPrint('SafeButtonProvider: Starting listener for recording');
      await startListening();
    } else {
      debugPrint('SafeButtonProvider: Already listening');
    }
    
    notifyListeners();
    debugPrint('SafeButtonProvider: Recording mode started, isListening: $_isListening');
  }
  
  // Stop recording and save the button
  void _stopRecordingButton(String action, String type) {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _isRecordingButton = false;
    
    // Detected button can be saved later with addSafeButton
    notifyListeners();
  }
    // Cancel recording without saving
  void cancelRecording() {
    debugPrint('SafeButtonProvider: Canceling recording mode');
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _isRecordingButton = false;
    _lastButtonPressed = null;
    
    // We don't stop listening here, as we might be in test mode
    // The setup mode will continue listening for new button presses
    
    notifyListeners();
    debugPrint('SafeButtonProvider: Recording canceled, isListening remains: $_isListening');
  }
  
  // Add a new safe button
  Future<void> addSafeButton(String name, String action, String type) async {
    if (_safeButtons.length >= 2) {
      // Limit to 2 buttons only
      return;
    }
    
    final newButton = SafeButton(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      action: action,
    );
    
    _safeButtons.add(newButton);
    await _saveButtons();
    
    notifyListeners();
  }
  
  // Remove a safe button
  Future<void> removeSafeButton(String id) async {
    _safeButtons.removeWhere((button) => button.id == id);
    await _saveButtons();
    
    notifyListeners();
  }
  
  // Update a safe button
  Future<void> updateSafeButton(SafeButton button) async {
    final index = _safeButtons.indexWhere((b) => b.id == button.id);
    
    if (index >= 0) {
      _safeButtons[index] = button;
      await _saveButtons();
    }
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    _recordingTimer?.cancel();
    stopListening();
    super.dispose();
  }
}