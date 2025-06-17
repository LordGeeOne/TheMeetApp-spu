// Global accessors
import 'package:the_meet_app/services/auth_service.dart';
import 'package:the_meet_app/services/database_service.dart';
import 'package:the_meet_app/services/chat_service.dart';
import 'package:the_meet_app/services/meet_service.dart';
import 'package:the_meet_app/services/security_service.dart';
import 'package:the_meet_app/providers/config_provider.dart';

AuthService get authService => ServiceLocator.authService;
DatabaseService get databaseService => ServiceLocator.databaseService;
ChatService get chatService => ServiceLocator.chatService;
MeetService get meetService => ServiceLocator.meetService;
SecurityService get securityService => ServiceLocator.securityService;

/// Service Locator pattern implementation to manage and provide access to services
class ServiceLocator {
  static late AuthService authService;
  static late DatabaseService databaseService;
  static late ChatService chatService;
  static late MeetService meetService;
  static late SecurityService securityService;
  
  /// Initialize all services with the provided config
  static void setup(ConfigProvider configProvider) {
    authService = AuthService(configProvider);
    databaseService = DatabaseService(configProvider);
    meetService = MeetService(configProvider);
    chatService = ChatService(configProvider);
    securityService = SecurityService(configProvider);
  }

  /// Get a service by type
  static T get<T>() {
    if (T == AuthService) return authService as T;
    if (T == DatabaseService) return databaseService as T;
    if (T == ChatService) return chatService as T;
    if (T == MeetService) return meetService as T;
    if (T == SecurityService) return securityService as T;
    throw Exception('Service of type $T not found');
  }
}
