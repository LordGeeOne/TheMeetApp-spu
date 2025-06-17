import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meet.dart';
import '../services/panic_button_service.dart';
import '../providers/auth_provider.dart';

/// Global service that monitors SafeWalk meets and automatically activates
/// panic button monitoring when SafeWalk meets start
class GlobalSafeWalkService {
  static final GlobalSafeWalkService _instance = GlobalSafeWalkService._internal();
  factory GlobalSafeWalkService() => _instance;
  GlobalSafeWalkService._internal();

  Timer? _monitoringTimer;
  final Set<String> _activeMeetIds = {};
  AuthProvider? _authProvider;
  bool _isInitialized = false;

  /// Initialize the global service
  void initialize(AuthProvider authProvider) {
    _authProvider = authProvider;
    _isInitialized = true;
    _startGlobalMonitoring();
    debugPrint('GlobalSafeWalkService: Initialized and started monitoring');
  }

  /// Start monitoring for SafeWalk meets that should be active
  void _startGlobalMonitoring() {
    // Check every 30 seconds for SafeWalk meets that should be active
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForActiveSafeWalks();
    });
    
    // Also check immediately
    _checkForActiveSafeWalks();
  }
  /// Check for SafeWalk meets that should currently be active
  Future<void> _checkForActiveSafeWalks() async {
    if (!_isInitialized || _authProvider?.user == null) {
      debugPrint('GlobalSafeWalkService: Service not initialized or user not authenticated');
      return;
    }

    try {
      final userId = _authProvider!.user!.uid;
      final now = DateTime.now();
      
      debugPrint('🔍 GlobalSafeWalkService: Checking for active SafeWalks at ${now.toString()}');
      debugPrint('🔍 User ID: $userId');      // Query for SafeWalk meets that:
      // 1. User is a participant in
      // 2. Start time is now or in the past
      // 3. End time is in the future (meet duration + buffer)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('meets')
          .where('type', isEqualTo: 'SafeWalk')
          .where('participantIds', arrayContains: userId)
          .get();

      debugPrint('🔍 Found ${querySnapshot.docs.length} SafeWalk meets for user');

      for (var doc in querySnapshot.docs) {
        final meet = Meet.fromFirestore(doc);
        final isActive = _shouldBeActive(meet, now);
        
        debugPrint('🔍 Evaluating SafeWalk: ${meet.title}');
        debugPrint('   - Meet ID: ${meet.id}');
        debugPrint('   - Meet time: ${meet.time}');
        debugPrint('   - Current time: $now');
        debugPrint('   - Should be active: $isActive');
        debugPrint('   - Already monitoring: ${_activeMeetIds.contains(meet.id)}');
        
        if (isActive) {
          if (!_activeMeetIds.contains(meet.id)) {
            debugPrint('🚨 ACTIVATING panic monitoring for SafeWalk: ${meet.title}');
            await _activatePanicButtonsForMeet(meet);
          } else {
            debugPrint('✅ Already monitoring SafeWalk: ${meet.title}');
          }
        } else {
          if (_activeMeetIds.contains(meet.id)) {
            debugPrint('⏹️ DEACTIVATING panic monitoring for SafeWalk: ${meet.title}');
            await _deactivatePanicButtonsForMeet(meet);
          }
        }
      }

      // Also check for meets that are no longer in the query results
      final currentMeetIds = querySnapshot.docs.map((doc) => doc.id).toSet();
      final meetIdsToDeactivate = _activeMeetIds.difference(currentMeetIds);
      
      for (final meetId in meetIdsToDeactivate) {
        _activeMeetIds.remove(meetId);
        await PanicButtonService().deactivate();
        debugPrint('🗑️ GlobalSafeWalkService: Deactivated panic buttons for removed meet: $meetId');
      }

      debugPrint('📊 GlobalSafeWalkService Status:');
      debugPrint('   - Active meets: ${_activeMeetIds.length}');
      debugPrint('   - Meet IDs: ${_activeMeetIds.toList()}');

    } catch (e) {
      debugPrint('❌ GlobalSafeWalkService: Error checking for active SafeWalks: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }  /// Determine if a SafeWalk meet should currently be active
  bool _shouldBeActive(Meet meet, DateTime now) {
    final meetStartTime = meet.time;
    
    // SafeWalk is active if:
    // 1. Start time has passed (allowing 10 minute early buffer for preparation)
    final startBuffer = meetStartTime.subtract(const Duration(minutes: 10));
    
    // 2. Not more than 2 hours after start time (reasonable walking duration)
    final endBuffer = meetStartTime.add(const Duration(hours: 2));
    
    final isInActiveWindow = now.isAfter(startBuffer) && now.isBefore(endBuffer);
    
    debugPrint('🕐 Time Analysis for ${meet.title}:');
    debugPrint('   - Meet start: $meetStartTime');
    debugPrint('   - Active from: $startBuffer (10min early)');
    debugPrint('   - Active until: $endBuffer (2hr duration)');
    debugPrint('   - Current time: $now');
    debugPrint('   - Is after start buffer: ${now.isAfter(startBuffer)}');
    debugPrint('   - Is before end buffer: ${now.isBefore(endBuffer)}');
    debugPrint('   - Final decision: $isInActiveWindow');
    
    return isInActiveWindow;
  }

  /// Activate panic buttons for a specific SafeWalk meet
  Future<void> _activatePanicButtonsForMeet(Meet meet) async {
    try {
      await PanicButtonService().activateForMeet(meet);
      _activeMeetIds.add(meet.id);
      debugPrint('GlobalSafeWalkService: Activated panic buttons for SafeWalk: ${meet.title}');
    } catch (e) {
      debugPrint('GlobalSafeWalkService: Failed to activate panic buttons for meet ${meet.id}: $e');
    }
  }

  /// Deactivate panic buttons for a specific SafeWalk meet
  Future<void> _deactivatePanicButtonsForMeet(Meet meet) async {
    try {
      await PanicButtonService().deactivate();
      _activeMeetIds.remove(meet.id);
      debugPrint('GlobalSafeWalkService: Deactivated panic buttons for SafeWalk: ${meet.title}');
    } catch (e) {
      debugPrint('GlobalSafeWalkService: Failed to deactivate panic buttons for meet ${meet.id}: $e');
    }
  }

  /// Force trigger a check (useful for testing)
  Future<void> triggerCheck() async {
    await _checkForActiveSafeWalks();
  }

  /// Test function to manually check a specific SafeWalk by ID
  Future<void> testSpecificSafeWalk(String meetId) async {
    try {
      debugPrint('🧪 Testing specific SafeWalk: $meetId');
      
      final doc = await FirebaseFirestore.instance
          .collection('meets')
          .doc(meetId)
          .get();
      
      if (!doc.exists) {
        debugPrint('❌ SafeWalk document does not exist: $meetId');
        return;
      }
      
      final meet = Meet.fromFirestore(doc);
      final now = DateTime.now();
      final isActive = _shouldBeActive(meet, now);
      
      debugPrint('🧪 SafeWalk Test Results:');
      debugPrint('   - ID: ${meet.id}');
      debugPrint('   - Title: ${meet.title}');
      debugPrint('   - Type: ${meet.type}');
      debugPrint('   - Meet time: ${meet.time}');
      debugPrint('   - Current time: $now');
      debugPrint('   - Creator ID: ${meet.creatorId}');
      debugPrint('   - Participants: ${meet.participantIds}');
      debugPrint('   - Current user: ${_authProvider?.user?.uid}');
      debugPrint('   - User is participant: ${meet.participantIds.contains(_authProvider?.user?.uid)}');
      debugPrint('   - Should be active: $isActive');
      debugPrint('   - Currently monitoring: ${_activeMeetIds.contains(meet.id)}');
      
      if (isActive && meet.participantIds.contains(_authProvider?.user?.uid)) {
        debugPrint('🚨 This SafeWalk should trigger panic monitoring!');
        await _activatePanicButtonsForMeet(meet);
      }
      
    } catch (e) {
      debugPrint('❌ Error testing SafeWalk $meetId: $e');
    }
  }

  /// Get current status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'activeMeetIds': _activeMeetIds.toList(),
      'isMonitoring': _monitoringTimer != null && _monitoringTimer!.isActive,
      'userId': _authProvider?.user?.uid,
    };
  }

  /// Stop global monitoring
  void stop() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _activeMeetIds.clear();
    PanicButtonService().deactivate();
    debugPrint('GlobalSafeWalkService: Stopped global monitoring');
  }

  /// Dispose resources
  void dispose() {
    stop();
    _authProvider = null;
    _isInitialized = false;
  }
}
