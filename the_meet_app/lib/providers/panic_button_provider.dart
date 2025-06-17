import 'package:flutter/foundation.dart';
import '../models/meet.dart';
import '../services/panic_button_service.dart';

class PanicButtonProvider with ChangeNotifier {
  final PanicButtonService _panicButtonService = PanicButtonService();
  
  bool _isMonitoring = false;
  Meet? _activeMeet;
  
  bool get isMonitoring => _isMonitoring;
  Meet? get activeMeet => _activeMeet;

  /// Start panic button monitoring for a SafeWalk meet
  Future<void> startMonitoring(Meet meet) async {
    if (_isMonitoring && _activeMeet?.id == meet.id) {
      debugPrint('PanicButtonProvider: Already monitoring this meet');
      return;
    }

    if (!_isSafeWalkMeet(meet)) {
      debugPrint('PanicButtonProvider: Not a SafeWalk meet');
      return;
    }

    try {
      await _panicButtonService.activateForMeet(meet);
      _isMonitoring = true;
      _activeMeet = meet;
      
      debugPrint('PanicButtonProvider: Started monitoring SafeWalk: ${meet.title}');
      notifyListeners();
    } catch (e) {
      debugPrint('PanicButtonProvider: Failed to start monitoring: $e');
    }
  }

  /// Stop panic button monitoring
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    try {
      await _panicButtonService.deactivate();
      _isMonitoring = false;
      _activeMeet = null;
      
      debugPrint('PanicButtonProvider: Stopped panic button monitoring');
      notifyListeners();
    } catch (e) {
      debugPrint('PanicButtonProvider: Failed to stop monitoring: $e');
    }
  }

  /// Check if a meet is a SafeWalk
  bool _isSafeWalkMeet(Meet meet) {
    return meet.type.toLowerCase() == 'safewalk';
  }

  /// Test panic button functionality
  Future<void> testPanicButton() async {
    await _panicButtonService.testPanicButton();
  }

  /// Get service status for debugging
  Map<String, dynamic> getServiceStatus() {
    return _panicButtonService.getStatus();
  }

  @override
  void dispose() {
    stopMonitoring();
    _panicButtonService.dispose();
    super.dispose();
  }
}
