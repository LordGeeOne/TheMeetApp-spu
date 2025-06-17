import 'package:flutter/material.dart';
import '../services/global_safewalk_service.dart';
import '../services/panic_button_service.dart';
import '../providers/auth_provider.dart';
import '../providers/safe_button_provider.dart';

/// Debug helper for testing and monitoring SafeWalk functionality
class SafeWalkDebugHelper {
  static void showDebugInfo(BuildContext context) {
    final globalService = GlobalSafeWalkService();
    final panicService = PanicButtonService();
    
    final globalStatus = globalService.getStatus();
    final panicStatus = panicService.getStatus();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 SafeWalk Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSection('Global SafeWalk Service', [
                'Initialized: ${globalStatus['isInitialized']}',
                'Monitoring: ${globalStatus['isMonitoring']}',
                'User ID: ${globalStatus['userId'] ?? 'None'}',
                'Active Meets: ${globalStatus['activeMeetIds'].length}',
                'Active Meet IDs: ${globalStatus['activeMeetIds'].join(', ')}',
              ]),
              const SizedBox(height: 16),
              _buildSection('Panic Button Service', [
                'Active: ${panicStatus['isActive']}',
                'Active Meet: ${panicStatus['activeMeet'] ?? 'None'}',
                'Active Meet ID: ${panicStatus['activeMeetId'] ?? 'None'}',
                'Registered Buttons: ${panicStatus['registeredButtons']}',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _triggerManualCheck(context);
            },
            child: const Text('🔄 Force Check'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _testPanicButton(context);
            },
            child: const Text('🚨 Test Panic'),
          ),
        ],
      ),
    );
  }
  
  static Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text('• $item'),
        )),
      ],
    );
  }
  
  static void _triggerManualCheck(BuildContext context) {
    debugPrint('🔍 SafeWalkDebugHelper: Triggering manual check...');
    GlobalSafeWalkService().triggerCheck().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Manual SafeWalk check completed'),
          duration: Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Manual check failed: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }
  
  static void _testPanicButton(BuildContext context) {
    debugPrint('🚨 SafeWalkDebugHelper: Testing panic button...');
    PanicButtonService().testPanicButton().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Panic button test completed'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Panic test failed: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }
  
  /// Create a floating action button for easy debug access
  static Widget createDebugFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => showDebugInfo(context),
      backgroundColor: Colors.orange,
      child: const Icon(Icons.bug_report, color: Colors.white),
      mini: true,
    );
  }
  
  /// Monitor SafeWalk status and show persistent notification
  static Widget createStatusMonitor() {
    return StreamBuilder<void>(
      stream: Stream.periodic(const Duration(seconds: 5)),
      builder: (context, snapshot) {
        final globalStatus = GlobalSafeWalkService().getStatus();
        final panicStatus = PanicButtonService().getStatus();
        
        final isMonitoring = globalStatus['isMonitoring'] == true;
        final isPanicActive = panicStatus['isActive'] == true;
        final activeMeets = globalStatus['activeMeetIds'].length;
        
        if (!isMonitoring && !isPanicActive) {
          return const SizedBox.shrink();
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPanicActive ? Colors.red : Colors.green,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isPanicActive 
              ? '🚨 PANIC ACTIVE ($activeMeets meets)' 
              : '👁️ MONITORING ($activeMeets meets)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
