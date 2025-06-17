// Stubbed out for minimal build. No Firestore or Firebase references.

import 'dart:async';

// This is a dummy location service that doesn't actually use location tracking
// The real implementation has been commented out to fix Android compatibility issues
class LocationService {
  String? currentMeetId;

  // Initialize location service
  Future<bool> initialize() async {
    // Pretend we initialized successfully
    return true;
  }

  // Start tracking and uploading user's location for a specific meet
  Future<bool> startTracking(String meetId) async {
    currentMeetId = meetId;
    // No actual tracking starts
    return true;
  }

  // Stop tracking user's location
  void stopTracking() {
    currentMeetId = null;
  }

  // Get a stream of all participant locations for a meet
  Stream<List<Map<String, dynamic>>> getParticipantLocations(String meetId) {
    // Return an empty stream
    return Stream.value([]);
  }

  // Get a single location update - uses a dummy location
  Future<void> updateLocationOnce(String meetId) async {
    // Stubbed out for minimal build
  }

  // Dispose resources
  void dispose() {
    stopTracking();
  }
}
