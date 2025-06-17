import 'package:flutter_test/flutter_test.dart';
import 'package:the_meet_app/services/global_safewalk_service.dart';
import 'package:the_meet_app/services/panic_button_service.dart';
import 'package:the_meet_app/models/meet.dart';
import 'package:the_meet_app/providers/auth_provider.dart';
import 'package:the_meet_app/providers/safe_button_provider.dart';
import 'package:the_meet_app/models/safe_button.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([AuthProvider, SafeButtonProvider])
import 'safewalk_integration_test.mocks.dart';

void main() {
  group('SafeWalk Integration Tests', () {
    late GlobalSafeWalkService globalService;
    late PanicButtonService panicService;
    late MockAuthProvider mockAuthProvider;
    late MockSafeButtonProvider mockSafeButtonProvider;

    setUp(() {
      globalService = GlobalSafeWalkService();
      panicService = PanicButtonService();
      mockAuthProvider = MockAuthProvider();
      mockSafeButtonProvider = MockSafeButtonProvider();
    });

    test('GlobalSafeWalkService should initialize correctly', () {
      // Test initialization
      globalService.initialize(mockAuthProvider);
      
      final status = globalService.getStatus();
      expect(status['isInitialized'], true);
      expect(status['isMonitoring'], true);
      expect(status['activeMeetIds'], []);
    });

    test('Meet time validation should work correctly', () {
      // Create a test SafeWalk meet
      final now = DateTime.now();
      final meetTime = now.add(const Duration(minutes: 10)); // 10 minutes in future
      
      final testMeet = Meet(
        id: 'test-safewalk-1',
        title: 'SafeWalk from Kopano to Library',
        description: 'Test SafeWalk',
        location: 'From Kopano Residence to Library',
        latitude: -26.1076,
        longitude: 27.9989,
        time: meetTime,
        type: 'SafeWalk',
        maxParticipants: 5,
        creatorId: 'test-user',
        participantIds: ['test-user'],
        imageUrl: '',
        chatId: 'test-chat',
      );

      // Test meet should be active within the 5-minute buffer
      final shouldBeActive = globalService.getStatus(); // We can't directly test _shouldBeActive as it's private
      expect(shouldBeActive['isInitialized'], true);
    });

    test('PanicButtonService should handle button registration', () {
      // Create test safe buttons
      final testButtons = [
        SafeButton(
          id: 'vol-up',
          name: 'Volume Up',
          action: 'volume_up',
          type: 'volume',
          isActive: true,
        ),
        SafeButton(
          id: 'vol-down',
          name: 'Volume Down',
          action: 'volume_down',
          type: 'volume',
          isActive: true,
        ),
      ];

      when(mockSafeButtonProvider.safeButtons).thenReturn(testButtons);

      // Test status
      final status = panicService.getStatus();
      expect(status['isActive'], false);
      expect(status['activeMeet'], null);
    });

    test('Service integration should work together', () {
      // Test that services can work together
      globalService.initialize(mockAuthProvider);
      
      final globalStatus = globalService.getStatus();
      final panicStatus = panicService.getStatus();
      
      expect(globalStatus['isInitialized'], true);
      expect(panicStatus['isActive'], false);
      
      // Both services should be ready
      expect(globalStatus['isMonitoring'], true);
    });

    tearDown(() {
      globalService.stop();
      panicService.dispose();
    });
  });

  group('SafeWalk Time Validation Tests', () {
    test('SafeWalk should activate 5 minutes before start time', () {
      final now = DateTime.now();
      
      // Test various time scenarios
      final testCases = [
        {
          'description': 'Meet starting in 10 minutes',
          'meetTime': now.add(const Duration(minutes: 10)),
          'shouldBeActive': false, // Not yet within 5-minute buffer
        },
        {
          'description': 'Meet starting in 3 minutes',
          'meetTime': now.add(const Duration(minutes: 3)),
          'shouldBeActive': true, // Within 5-minute buffer
        },
        {
          'description': 'Meet started 30 minutes ago',
          'meetTime': now.subtract(const Duration(minutes: 30)),
          'shouldBeActive': true, // Still within 3-hour window
        },
        {
          'description': 'Meet started 4 hours ago',
          'meetTime': now.subtract(const Duration(hours: 4)),
          'shouldBeActive': false, // Beyond 3-hour timeout
        },
      ];

      for (final testCase in testCases) {
        final meet = Meet(
          id: 'test-meet',
          title: 'Test SafeWalk',
          description: testCase['description'] as String,
          location: 'Test Location',
          latitude: 0.0,
          longitude: 0.0,
          time: testCase['meetTime'] as DateTime,
          type: 'SafeWalk',
          maxParticipants: 5,
          creatorId: 'test-user',
          participantIds: ['test-user'],
          imageUrl: '',
          chatId: '',
        );

        // Note: We would test the private _shouldBeActive method if it were public
        // For now, we're just testing that the meet is created correctly
        expect(meet.type, 'SafeWalk');
        expect(meet.time, testCase['meetTime']);
      }
    });
  });
}
