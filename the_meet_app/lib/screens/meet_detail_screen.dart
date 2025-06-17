import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:the_meet_app/models/meet.dart';
import 'package:the_meet_app/providers/auth_provider.dart';
import 'package:the_meet_app/providers/meet_provider.dart';
import 'package:the_meet_app/providers/user_provider.dart';
import 'package:the_meet_app/screens/map_screen.dart';
import 'package:the_meet_app/screens/meet_map_screen.dart';
import 'package:the_meet_app/services/service_locator.dart';
import 'package:the_meet_app/screens/messages_screen.dart';
import 'package:the_meet_app/widgets/consistent_app_bar.dart';

class MeetDetailScreen extends StatefulWidget {
  final String meetId;

  const MeetDetailScreen({
    super.key,
    required this.meetId,
  });

  @override
  State<MeetDetailScreen> createState() => _MeetDetailScreenState();
}

class _MeetDetailScreenState extends State<MeetDetailScreen> {
  Meet? _meet;
  bool _isLoading = true;
  String? _errorMessage;
  bool _notifyWhenAvailable = false;
  bool _isJoining = false;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _loadMeetDetails();
  }

  Future<void> _loadMeetDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final meetProvider = Provider.of<MeetProvider>(context, listen: false);
      final meet = await meetProvider.fetchMeetById(widget.meetId);

      if (meet == null) {
        setState(() {
          _errorMessage = 'Meet not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _meet = meet;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading meet details: $e';
        _isLoading = false;
      });
    }
  }

  String _getTimeRemaining(DateTime meetTime) {
    final now = DateTime.now();
    final difference = meetTime.difference(now);
    
    // If the meet has already started
    if (difference.isNegative) {
      return 'Started';
    }
    
    // If more than a day remains
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    }
    
    // If more than an hour remains
    if (difference.inHours > 0) {
      if (difference.inHours == 1) {
        // About an hour remaining
        return 'about 1h';
      }
      return '${difference.inHours}h';
    }
    
    // If more than a minute remains
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    }
    
    // Less than a minute remains
    return 'Now';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';

    // Show loading indicator while data is being fetched
    if (_isLoading) {
      return const Scaffold(
        appBar: ConsistentAppBar(title: 'The Meet App'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show error message if loading failed
    if (_errorMessage != null) {
      return Scaffold(
        appBar: const ConsistentAppBar(title: 'The Meet App'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadMeetDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Get meet details
    final meet = _meet!;
    final isParticipant = meet.isParticipant(userId);
    final isCreator = meet.isCreator(userId);
    final isFull = meet.participantIds.length >= meet.maxParticipants;
    final timeRemaining = _getTimeRemaining(meet.time);

    // Determine icon and color based on meet type
    IconData typeIcon = Icons.group;
    Color typeColor = Colors.blueGrey;

    switch (meet.type.toLowerCase()) {
      case 'coffee':
        typeIcon = Icons.coffee;
        typeColor = Colors.brown;
        break;
      case 'study':
        typeIcon = Icons.school;
        typeColor = Colors.indigo;
        break;
      case 'meal':
        typeIcon = Icons.restaurant;
        typeColor = Colors.orange;
        break;
      case 'activity':
        typeIcon = Icons.sports_basketball;
        typeColor = Colors.green;
        break;
    }

    return Scaffold(
      appBar: ConsistentAppBar(
        title: 'The Meet App',
        actions: [
          if (isCreator)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit Meet'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Meet', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  // Navigate to edit screen
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => EditMeetScreen(meet: meet)));
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, meet);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meet image with gradient overlay for smooth transition and rounded corners
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: meet.isDefaultImage
                          ? DecorationImage(
                              image: AssetImage(meet.displayImageUrl),
                              fit: BoxFit.cover,
                            )
                          : DecorationImage(
                              image: NetworkImage(meet.displayImageUrl),
                              fit: BoxFit.cover,
                              onError: (error, stackTrace) =>
                                  const AssetImage('assets/images/meet_images/default.jpg'),
                            ),
                    ),
                    child: meet.displayImageUrl.isEmpty
                        ? Center(
                            child: Icon(
                              typeIcon,
                              size: 80,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          )
                        : null,
                  ),
                  // Gradient overlay for smooth transition to content
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Time remaining badge
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeRemaining,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Meet details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badges and Join/Chat buttons
                  Row(
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, size: 14, color: typeColor),
                            const SizedBox(width: 4),
                            Text(
                              meet.type,
                              style: TextStyle(
                                color: typeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isFull ? Colors.red : Colors.green).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isFull ? 'Full' : 'Open',
                          style: TextStyle(
                            color: isFull ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Chat button - now responsive to join status
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          onPressed: (isCreator || isParticipant) 
                            ? () => _navigateToMeetChat(context, meet)
                            : null, // Disabled if not joined
                          icon: const Icon(Icons.chat),
                          tooltip: 'Meet Chat',
                          style: IconButton.styleFrom(
                            backgroundColor: (isCreator || isParticipant) 
                                ? typeColor.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            foregroundColor: (isCreator || isParticipant) 
                                ? typeColor
                                : Colors.grey,
                          ),
                        ),
                      ),

                      // Join/Leave button
                      ElevatedButton(
                        onPressed: isCreator || _isJoining || _isLeaving
                            ? null
                            : (isParticipant ? () => _leaveMeet(context, meet, userId) : 
                               isFull ? null : () => _joinMeet(context, meet, userId)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isParticipant ? Colors.red : typeColor,
                          disabledBackgroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          minimumSize: const Size(100, 40),
                          elevation: 4, // Adding more elevation for better prominence
                        ),
                        child: _isJoining || _isLeaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                isCreator
                                    ? 'Host'
                                    : isParticipant
                                        ? 'Leave'
                                        : isFull
                                            ? 'Full'
                                            : 'Join',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    meet.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Creator name (moved under title)
                  FutureBuilder(
                    future: _getUserName(meet.creatorId),
                    builder: (context, snapshot) {
                      final creatorName = snapshot.data ?? 'Unknown User';
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey[800],
                            child: Text(
                              creatorName.isNotEmpty ? creatorName[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            creatorName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Time and location
                  _buildInfoRow(
                    Icons.access_time,
                    DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(meet.time),
                  ),

                  const SizedBox(height: 8),

                  _buildInfoRow(
                    Icons.location_on,
                    meet.location,
                    onTap: () {
                      // Launch the new MeetMapScreen instead of regular MapScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MeetMapScreen(meet: meet),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // Add dedicated map button for better visibility
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MeetMapScreen(meet: meet),
                          ),
                        );
                      },
                      icon: Icon(Icons.map, color: typeColor),
                      label: const Text('View on Map & Directions'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        side: BorderSide(color: typeColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    Icons.people,
                    '${meet.participantIds.length}/${meet.maxParticipants} participants',
                  ),

                  // Notify when available toggle (only show if meet is full and user isn't participating)
                  if (isFull && !isParticipant && !isCreator)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_outlined, size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Notify me when a spot opens up',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Switch(
                              value: _notifyWhenAvailable,
                              onChanged: (value) {
                                final meetProvider = Provider.of<MeetProvider>(context, listen: false);
                                
                                if (value) {
                                  // Register for notifications
                                  meetProvider.registerForAvailabilityNotification(meet.id, userId)
                                    .then((success) {
                                      if (success) {
                                        setState(() {
                                          _notifyWhenAvailable = true;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('You\'ll be notified when a spot opens up'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Failed to register for notifications'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    });
                                } else {
                                  // Unregister from notifications
                                  meetProvider.unregisterFromAvailabilityNotification(meet.id, userId)
                                    .then((success) {
                                      if (success) {
                                        setState(() {
                                          _notifyWhenAvailable = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Notification canceled'),
                                            backgroundColor: Colors.grey,
                                          ),
                                        );
                                      }
                                    });
                                }
                              },
                              activeColor: typeColor,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meet.description.isNotEmpty
                        ? meet.description
                        : 'No description provided.',
                    style: TextStyle(
                      fontSize: 16,
                      color: meet.description.isEmpty ? Colors.grey : null,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {VoidCallback? onTap}) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: onTap != null ? Colors.blue : null,
            ),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: row,
      );
    }

    return row;
  }

  Future<String> _getUserName(String userId) async {
    try {
      final user = await authService.getUserById(userId);
      return user?.displayName ?? 'User';
    } catch (e) {
      return 'User';
    }
  }

  void _joinMeet(BuildContext context, Meet meet, String userId) {
    setState(() {
      _isJoining = true;
    });

    final meetProvider = Provider.of<MeetProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    meetProvider.joinMeet(meet.id, userId).then((_) {
      // Refresh the meet details
      _loadMeetDetails();

      // Update user's participating meets
      userProvider.loadUserMeets();

      // Get the updated meet with the user included in participants
      meetProvider.fetchMeetById(meet.id).then((updatedMeet) {
        if (updatedMeet != null) {
          // Create/update chat for the meet and ensure this user is included
          _createMeetChat(updatedMeet);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have joined this meet!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });

      setState(() {
        _isJoining = false;
      });
    }).catchError((error) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining meet: $error'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {
        _isJoining = false;
      });
    });
  }

  void _leaveMeet(BuildContext context, Meet meet, String userId) {
    setState(() {
      _isLeaving = true;
    });

    final meetProvider = Provider.of<MeetProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Add user to the "left" field before removing them from participants
    meetProvider.addUserToLeftField(meet.id, userId).then((_) {
      // Continue to remove from participants
      meetProvider.leaveMeet(meet.id, userId).then((_) {
        // Refresh the meet details
        _loadMeetDetails();

        // Update user's participating meets
        userProvider.loadUserMeets();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have left this meet'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _isLeaving = false;
        });
      }).catchError((error) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error leaving meet: $error'),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() {
          _isLeaving = false;
        });
      });
    }).catchError((error) {
      // Show error message for adding to left field
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error leaving meet: $error'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {
        _isLeaving = false;
      });
    });
  }

  Future<void> _createMeetChat(Meet meet) async {
    try {
      // Get the current user's ID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? '';
      
      // Create chat for the meet using the chat service
      final chatId = await chatService.createMeetChat(meet);
      
      if (chatId != null && chatId.isNotEmpty) {
        // Update the meet with the chat ID in Firestore
        final meetProvider = Provider.of<MeetProvider>(context, listen: false);
        await meetProvider.updateMeetChatId(meet.id, chatId);
        
        print('Chat created and linked to meet successfully: $chatId');
      } else {
        print('Failed to create chat - chatId is null or empty');
      }
    } catch (e) {
      print('Error creating chat for meet: $e');
      // We don't show UI error here since it's not critical for the user
    }
  }

  void _navigateToMeetChat(BuildContext context, Meet meet) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? '';
    final isParticipant = meet.isParticipant(userId);
    final isCreator = meet.isCreator(userId);
    
    // Only allow access to the chat if the user has joined the meet or is the creator
    if (isParticipant || isCreator) {
      try {
        // Create or get the chat for this meet
        chatService.createMeetChat(meet).then((chatId) {
          if (chatId != null && chatId.isNotEmpty) {
            // Update the meet with the chat ID in Firestore
            final meetProvider = Provider.of<MeetProvider>(context, listen: false);
            meetProvider.updateMeetChatId(meet.id, chatId).then((_) {
              
              if (mounted) {
                // Navigate to the chat using the chat ID
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessagesScreen(
                      initialChatId: chatId,
                      initialMeetId: meet.id,
                    ),
                  ),
                );
              }
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to load chat. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Show a toast message if the user hasn't joined
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join the meet to view the meet\'s chat'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, Meet meet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meet?'),
        content: const Text(
          'This will permanently delete this meet and remove it for all participants. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMeet(context, meet);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteMeet(BuildContext context, Meet meet) {
    final meetProvider = Provider.of<MeetProvider>(context, listen: false);

    meetProvider.deleteMeet(meet.id).then((_) {
      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meet deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }).catchError((error) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting meet: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}