class FirebaseErrorHandler {
  /// Handle Firebase errors and provide meaningful messages
  static String getReadableError(dynamic error) {
    return 'Error: ${error.toString()}';
  }
  
  /// Get debugging info about Firebase configuration
  static Map<String, String> getFirebaseInfo() {
    return {
      'error': 'Firebase functionality is stubbed out for minimal build.',
    };
  }
}
