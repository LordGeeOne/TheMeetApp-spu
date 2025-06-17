import 'package:flutter/material.dart';

/// A utility class to handle image loading with proper fallbacks
class ImageHandler {
  /// Get the color associated with a meet type
  static Color getColorForMeetType(String meetType) {
    switch (meetType.toLowerCase()) {
      case 'spusafewalk':
        return Colors.blue.shade700;
      case 'walktravel':
        return Colors.green.shade600;
      case 'locationmeet':
        return Colors.orange.shade600;
      case 'activitymeet':
        return Colors.red.shade600;
      case 'eventmeet':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade700;
    }
  }
  
  /// Get the icon associated with a meet type
  static IconData getIconForMeetType(String meetType) {
    switch (meetType.toLowerCase()) {
      case 'spusafewalk':
        return Icons.shield;
      case 'walktravel':
        return Icons.directions_walk;
      case 'locationmeet':
        return Icons.place;
      case 'activitymeet':
        return Icons.sports_soccer;
      case 'eventmeet':
        return Icons.event;
      default:
        return Icons.group;
    }
  }
  
  /// Create a placeholder image widget for a specific meet type
  static Widget createPlaceholderImage(String meetType) {
    return Container(
      color: getColorForMeetType(meetType),
      child: Center(
        child: Icon(
          getIconForMeetType(meetType),
          size: 48,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }
}
