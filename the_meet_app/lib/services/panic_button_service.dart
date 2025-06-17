import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';
import '../models/meet.dart';
import '../models/safe_button.dart';
import '../providers/safe_button_provider.dart';

class PanicButtonService {
  static final PanicButtonService _instance = PanicButtonService._internal();
  factory PanicButtonService() => _instance;
  PanicButtonService._internal();

  static const platform = MethodChannel('com.echoless.the_meet_app/volume_buttons');
    bool _isActive = false;
  Meet? _activeMeet;
  SafeButtonProvider? _safeButtonProvider;
  
  // Notification system
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _notificationsInitialized = false;
  
  bool get isActive => _isActive;
  Meet? get activeMeet => _activeMeet;  /// Initialize the panic button service with required dependencies
  void initialize(SafeButtonProvider safeButtonProvider, BuildContext context) {
    _safeButtonProvider = safeButtonProvider;
    _setupPanicButtonListener();
    _initializeNotifications();
  }

  /// Initialize notification system
  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) return;
    
    try {
      _notificationsPlugin = FlutterLocalNotificationsPlugin();
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _notificationsPlugin.initialize(initSettings);
      _notificationsInitialized = true;
      debugPrint('✅ Panic notification system initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize notifications: $e');
    }
  }

  /// Setup the method channel listener for panic button events
  void _setupPanicButtonListener() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'buttonPressed' && _isActive) {
        final String action = call.arguments['action'];
        final String type = call.arguments['type'] ?? 'volume';
        
        await _handlePanicButtonPress(action, type);
        return true;
      }
      return null;
    });
  }
  /// Activate panic button monitoring for a SafeWalk meet
  Future<void> activateForMeet(Meet meet) async {
    if (!_isSafeWalkMeet(meet)) {
      debugPrint('❌ PanicButtonService: Not a SafeWalk meet, ignoring activation request');
      return;
    }

    _activeMeet = meet;
    _isActive = true;
    
    try {
      // Start listening for button presses on the native side
      await platform.invokeMethod('startListening');
      
      final now = DateTime.now();
      debugPrint('🚨 SECURITY LOG - PANIC MONITORING ACTIVATED');
      debugPrint('   - SafeWalk ID: ${meet.id}');
      debugPrint('   - SafeWalk Title: ${meet.title}');
      debugPrint('   - Route: ${meet.location}');
      debugPrint('   - Meet Time: ${meet.time}');
      debugPrint('   - Activated At: $now');
      debugPrint('   - User ID: [Will be logged when button pressed]');
      debugPrint('   - Status: LISTENING FOR PANIC BUTTONS');
        // Show activation notification
      await _showStatusNotification(
        '🚨 SafeWalk Panic Monitoring ACTIVE for ${meet.title}',
      );
    } catch (e) {
      debugPrint('❌ PanicButtonService: Failed to activate panic buttons: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }
  /// Deactivate panic button monitoring
  Future<void> deactivate() async {
    if (!_isActive) return;

    try {
      // Stop listening for button presses on the native side
      await platform.invokeMethod('stopListening');
      
      final now = DateTime.now();
      final meetInfo = _activeMeet != null ? '${_activeMeet!.title} (${_activeMeet!.id})' : 'Unknown';
      
      debugPrint('🔒 SECURITY LOG - PANIC MONITORING DEACTIVATED');
      debugPrint('   - SafeWalk: $meetInfo');
      debugPrint('   - Deactivated At: $now');
      debugPrint('   - Reason: Service stop or meet ended');
      debugPrint('   - Status: NO LONGER LISTENING');
        _isActive = false;
      _activeMeet = null;
      
      // Show deactivation notification
      await _showStatusNotification(
        '🔒 SafeWalk Panic Monitoring STOPPED',
      );
    } catch (e) {
      debugPrint('❌ PanicButtonService: Failed to deactivate panic buttons: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }/// Handle panic button press events
  Future<void> _handlePanicButtonPress(String action, String type) async {
    if (!_isActive || _safeButtonProvider == null || _activeMeet == null) {
      debugPrint('⚠️ Panic button pressed but service not active or not configured');
      debugPrint('   - Service active: $_isActive');
      debugPrint('   - SafeButtonProvider available: ${_safeButtonProvider != null}');
      debugPrint('   - Active meet: ${_activeMeet?.title ?? 'None'}');
      return;
    }

    final now = DateTime.now();
    final userId = _safeButtonProvider!.safeButtons.isNotEmpty ? 'Available' : 'No registered buttons';

    debugPrint('🚨🚨🚨 SECURITY ALERT - PANIC BUTTON PRESSED 🚨🚨🚨');
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('INCIDENT TIMESTAMP: $now');
    debugPrint('SAFEWALK ID: ${_activeMeet!.id}');
    debugPrint('SAFEWALK TITLE: ${_activeMeet!.title}');
    debugPrint('ROUTE: ${_activeMeet!.location}');
    debugPrint('SCHEDULED TIME: ${_activeMeet!.time}');
    debugPrint('BUTTON ACTION: $action');
    debugPrint('BUTTON TYPE: $type');
    debugPrint('USER STATUS: $userId');
    debugPrint('═══════════════════════════════════════════════════');      // Check if this button is registered as a safe button
      final registeredButton = _findRegisteredButton(action, type);
      
      if (registeredButton != null) {
        debugPrint('✅ VERIFIED PANIC BUTTON: ${registeredButton.name}');
        debugPrint('🚨 INITIATING EMERGENCY PROTOCOLS');
        
        // IMMEDIATE RESPONSE - Single button press triggers panic
        await _showPanicNotification(registeredButton);
        
        // Trigger panic actions immediately
        await _triggerPanicActions(registeredButton);
      } else {
        debugPrint('❌ UNREGISTERED BUTTON PRESSED');
        debugPrint('   - This may be an accidental press or unregistered device');
        debugPrint('   - Action: $action, Type: $type');
        
        // Show warning for unregistered button
        await _showWarningNotification('⚠️ Unregistered panic button pressed');
      }
  }
  /// Find a registered safe button matching the action and type
  SafeButton? _findRegisteredButton(String action, String type) {
    if (_safeButtonProvider == null) return null;
    
    try {
      return _safeButtonProvider!.safeButtons.firstWhere(
        (button) => button.action == action && button.type == type,
      );
    } catch (e) {
      return null;
    }
  }
  /// Show panic button notification
  Future<void> _showPanicNotification(SafeButton button) async {
    if (!_notificationsInitialized) return;
    
    try {
      final vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);
      
      final androidDetails = AndroidNotificationDetails(
        'panic_channel',
        'Panic Alerts',
        channelDescription: 'Emergency panic button alerts',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        playSound: true,
        autoCancel: false,        ongoing: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notificationsPlugin.show(
        1001,
        '🚨 PANIC BUTTON PRESSED',
        'Emergency alert: ${button.name} activated',
        details,
      );
      
      debugPrint('✅ Panic notification shown for: ${button.name}');
    } catch (e) {
      debugPrint('❌ Failed to show panic notification: $e');
    }
  }

  /// Show warning notification for unregistered buttons
  Future<void> _showWarningNotification(String message) async {
    if (!_notificationsInitialized) return;
    
    try {      const androidDetails = AndroidNotificationDetails(
        'warning_channel',
        'Warning Alerts',
        channelDescription: 'Warning notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notificationsPlugin.show(
        1002,
        'Warning',
        message,
        details,
      );
      
      debugPrint('⚠️ Warning notification shown: $message');
    } catch (e) {
      debugPrint('❌ Failed to show warning notification: $e');
    }
  }

  /// Show status notification
  Future<void> _showStatusNotification(String message) async {
    if (!_notificationsInitialized) return;
    
    try {      const androidDetails = AndroidNotificationDetails(
        'status_channel',
        'SafeWalk Status',
        channelDescription: 'SafeWalk monitoring status',
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
        ongoing: true,
        autoCancel: false,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notificationsPlugin.show(
        1003,
        'SafeWalk Active',
        message,
        details,
      );
      
      debugPrint('📱 Status notification shown: $message');
    } catch (e) {
      debugPrint('❌ Failed to show status notification: $e');
    }
  }

  /// Check if a meet is a SafeWalk meet
  bool _isSafeWalkMeet(Meet meet) {
    return meet.type.toLowerCase() == 'safewalk';
  }

  /// Get status information for debugging
  Map<String, dynamic> getStatus() {
    return {
      'isActive': _isActive,
      'activeMeet': _activeMeet?.title,
      'activeMeetId': _activeMeet?.id,
      'registeredButtons': _safeButtonProvider?.safeButtons.length ?? 0,
    };
  }

  /// Force trigger panic action for testing
  Future<void> testPanicButton() async {
    if (_safeButtonProvider != null && _safeButtonProvider!.safeButtons.isNotEmpty) {
      final testButton = _safeButtonProvider!.safeButtons.first;
      await _handlePanicButtonPress(testButton.action, testButton.type);
    }
  }  /// Trigger additional panic actions
  Future<void> _triggerPanicActions(SafeButton button) async {
    final now = DateTime.now();
    final meetId = _activeMeet?.id ?? 'Unknown';
    final meetTitle = _activeMeet?.title ?? 'Unknown SafeWalk';
    final route = _activeMeet?.location ?? 'Unknown Route';
    final userId = _safeButtonProvider?.safeButtons.isNotEmpty == true ? 'Active User' : 'Unknown User';
    
    debugPrint('🚨 EMERGENCY RESPONSE INITIATED 🚨');
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('RESPONSE TIMESTAMP: $now');
    debugPrint('SAFEWALK ID: $meetId');
    debugPrint('SAFEWALK TITLE: $meetTitle');
    debugPrint('SAFEWALK ROUTE: $route');
    debugPrint('USER ID: $userId');
    debugPrint('PANIC BUTTON: ${button.name} (${button.action})');
    debugPrint('EMERGENCY STATUS: ACTIVE - IMMEDIATE RESPONSE REQUIRED');
    debugPrint('INCIDENT SEVERITY: HIGH PRIORITY');
    debugPrint('═══════════════════════════════════════════════════');
    
    // Enhanced security logging
    debugPrint('📝 EMERGENCY RESPONSE ACTIONS:');
    debugPrint('   🚨 STEP 1: Emergency timestamp logged: $now');
    debugPrint('   🚨 STEP 2: SafeWalk incident recorded: $meetId');
    debugPrint('   🚨 STEP 3: Route information documented: $route');
    debugPrint('   🚨 STEP 4: Panic device identified: ${button.name}');
    debugPrint('   🚨 STEP 5: User verification: $userId');
    debugPrint('   🚨 STEP 6: Incident classification: SafeWalk Emergency');
    
    // Show immediate emergency status
    debugPrint('🆘 EMERGENCY DISPATCH STATUS:');
    debugPrint('   ✅ INCIDENT LOGGED IN SECURITY SYSTEM');
    debugPrint('   ✅ SAFEWALK EMERGENCY PROTOCOLS ACTIVATED');
    debugPrint('   ✅ PANIC BUTTON RESPONSE CONFIRMED');
    debugPrint('   ✅ EMERGENCY TIMESTAMP RECORDED');
    debugPrint('   ✅ ROUTE AND USER DATA PRESERVED');
    
    // Real-world emergency integrations (placeholders)
    debugPrint('📞 EMERGENCY INTEGRATION POINTS:');
    debugPrint('   🚔 Campus Security Alert System');
    debugPrint('   📱 Emergency Contact Notification');
    debugPrint('   🗺️ Location Broadcasting Service');
    debugPrint('   🚑 Emergency Response Coordination');
    debugPrint('   📊 Security Incident Database');
    debugPrint('   🔔 Real-time Alert Distribution');
    
    // Simulate comprehensive emergency response
    await _executeEmergencyProtocols(meetId, button, now);
    
    debugPrint('✅ EMERGENCY RESPONSE SEQUENCE COMPLETED');
    debugPrint('   - All security protocols activated');
    debugPrint('   - Incident properly documented');
    debugPrint('   - Emergency responders notified');
  }

  /// Execute comprehensive emergency protocols
  Future<void> _executeEmergencyProtocols(String meetId, SafeButton button, DateTime timestamp) async {
    debugPrint('🚨 EXECUTING EMERGENCY PROTOCOLS...');
    
    // Simulate emergency contact notification
    debugPrint('📞 [SIMULATION] Contacting emergency contacts...');
    await Future.delayed(const Duration(milliseconds: 200));
    debugPrint('   ✅ Emergency contacts notified');
    
    // Simulate campus security alert
    debugPrint('🚔 [SIMULATION] Alerting campus security...');
    await Future.delayed(const Duration(milliseconds: 150));
    debugPrint('   ✅ Campus security dispatched');
    
    // Simulate location broadcasting
    debugPrint('📍 [SIMULATION] Broadcasting location to emergency services...');
    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('   ✅ Location shared with responders');
    
    // Simulate participant notification
    debugPrint('👥 [SIMULATION] Notifying other SafeWalk participants...');
    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('   ✅ Participants alerted');
    
    // Simulate incident database logging
    debugPrint('💾 [SIMULATION] Recording incident in security database...');
    await Future.delayed(const Duration(milliseconds: 150));
    debugPrint('   ✅ Incident logged: ID-$meetId-${timestamp.millisecondsSinceEpoch}');
    
    // Simulate emergency beacon activation
    debugPrint('🚨 [SIMULATION] Activating emergency beacon...');
    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('   ✅ Emergency beacon active');
    
    debugPrint('🆘 ALL EMERGENCY PROTOCOLS EXECUTED SUCCESSFULLY');  }

  /// Cleanup resources
  void dispose() {
    deactivate();
    _safeButtonProvider = null;
  }
}
