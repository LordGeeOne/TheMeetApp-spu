import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meet.dart';
import '../providers/panic_button_provider.dart';
import '../providers/safe_button_provider.dart';

class SafeWalkMonitor extends StatefulWidget {
  final Meet meet;
  final Widget child;

  const SafeWalkMonitor({
    super.key,
    required this.meet,
    required this.child,
  });

  @override
  State<SafeWalkMonitor> createState() => _SafeWalkMonitorState();
}

class _SafeWalkMonitorState extends State<SafeWalkMonitor> {
  bool _hasStartedMonitoring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartMonitoring();
    });
  }

  @override
  void didUpdateWidget(SafeWalkMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meet.id != widget.meet.id) {
      _checkAndStartMonitoring();
    }
  }

  void _checkAndStartMonitoring() {
    if (_isSafeWalkMeet() && !_hasStartedMonitoring) {
      _startPanicButtonMonitoring();
    }
  }

  bool _isSafeWalkMeet() {
    return widget.meet.type.toLowerCase() == 'safewalk';
  }

  void _startPanicButtonMonitoring() {
    final panicButtonProvider = Provider.of<PanicButtonProvider>(context, listen: false);
    final safeButtonProvider = Provider.of<SafeButtonProvider>(context, listen: false);

    // Check if user has registered safe buttons
    if (safeButtonProvider.safeButtons.isEmpty) {
      _showNoButtonsWarning();
      return;
    }

    // Start monitoring
    panicButtonProvider.startMonitoring(widget.meet);
    _hasStartedMonitoring = true;

    debugPrint('SafeWalkMonitor: Started monitoring for meet: ${widget.meet.title}');
  }

  void _showNoButtonsWarning() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No panic buttons registered. Go to Settings > Safe Module to set up panic buttons.',
          ),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Setup',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to Safe Module screen
              Navigator.pushNamed(context, '/settings');
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_hasStartedMonitoring) {
      // Stop monitoring when this widget is disposed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final panicButtonProvider = Provider.of<PanicButtonProvider>(context, listen: false);
        panicButtonProvider.stopMonitoring();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PanicButtonProvider, SafeButtonProvider>(
      builder: (context, panicProvider, safeProvider, child) {
        return Stack(
          children: [
            widget.child,
            
            // Show panic button status indicator for SafeWalk
            if (_isSafeWalkMeet())
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: panicProvider.isMonitoring 
                        ? Colors.green.withOpacity(0.9)
                        : Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        panicProvider.isMonitoring 
                            ? Icons.security 
                            : Icons.warning,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        panicProvider.isMonitoring 
                            ? 'Panic buttons active'
                            : 'Panic buttons inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
