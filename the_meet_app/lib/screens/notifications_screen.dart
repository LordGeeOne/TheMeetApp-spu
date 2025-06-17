import 'package:flutter/material.dart';
import 'package:the_meet_app/screens/meet_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock notifications data - in a real app, this would come from a database
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'New Meet Nearby',
      message: 'A new Coffee meetup has been created near you!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      type: NotificationType.newMeet,
      relatedId: 'demo-meet-1',
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Someone joined your meet',
      message: 'Alex has joined your Study Group meet',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.joinedMeet,
      relatedId: 'demo-meet-2',
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: 'Meet Reminder',
      message: 'Your Coffee Chat meet starts in 1 hour',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      type: NotificationType.reminder,
      relatedId: 'demo-meet-3',
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      title: 'Meet Cancelled',
      message: 'The Lunch Meetup for tomorrow has been cancelled',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.cancelled,
      relatedId: 'demo-meet-4',
      isRead: true,
    ),
    NotificationItem(
      id: '5',
      title: 'Meet Update',
      message: 'The location for Game Night has been changed',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.updated,
      relatedId: 'demo-meet-5',
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Count unread notifications
    final unreadCount = _notifications.where((notif) => !notif.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'The MeetApp',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        toolbarHeight: 48, // Smaller height for the header
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.85),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all as read'),
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Center(
                      child: Text(
                        'You have $unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationTile(notification);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll be notified about meet updates,\ninvitations, and other activities',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem notification) {
    // Get icon and color based on notification type
    IconData icon;
    Color color;
    switch (notification.type) {
      case NotificationType.newMeet:
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case NotificationType.joinedMeet:
        icon = Icons.person_add;
        color = Colors.blue;
        break;
      case NotificationType.reminder:
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      case NotificationType.cancelled:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case NotificationType.updated:
        icon = Icons.update;
        color = Colors.purple;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    // Format the timestamp
    final now = DateTime.now();
    final difference = now.difference(notification.timestamp);
    String timeAgo;
    
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes}m ago';
    } else {
      timeAgo = 'Just now';
    }

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification removed'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              timeAgo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: notification.isRead
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          // Mark as read
          setState(() {
            final index = _notifications.indexWhere((n) => n.id == notification.id);
            if (index >= 0) {
              _notifications[index] = _notifications[index].copyWith(isRead: true);
            }
          });

          // Navigate to related content if applicable
          if (notification.relatedId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MeetDetailScreen(meetId: notification.relatedId),
              ),
            );
          }
        },
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

enum NotificationType {
  newMeet,
  joinedMeet,
  reminder,
  cancelled,
  updated,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final String relatedId;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.relatedId,
    required this.isRead,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    String? relatedId,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
    );
  }
}