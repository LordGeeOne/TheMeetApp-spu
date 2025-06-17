class FirestoreTester {
  static Future<Map<String, dynamic>> runTests() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': 'stubbed',
      'tests': <String, String>{},
    };

    // Stubbed out for minimal build. No Firestore or Firebase references.

    return results;
  }
}
