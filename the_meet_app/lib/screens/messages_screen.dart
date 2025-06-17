import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_meet_app/providers/auth_provider.dart';
import 'package:the_meet_app/providers/meet_provider.dart';
import 'package:the_meet_app/providers/theme_provider.dart'; // Add import for ThemeProvider
import 'package:intl/intl.dart';
import 'package:the_meet_app/services/service_locator.dart';
import 'package:the_meet_app/models/chat.dart';
import 'package:the_meet_app/models/meet.dart';
import 'package:the_meet_app/screens/meet_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

class MessagesScreen extends StatefulWidget {
  final String? initialMeetId;
  final String? initialChatId;

  const MessagesScreen({
    super.key,
    this.initialMeetId,
    this.initialChatId,
  });

  @override
  State<MessagesScreen> createState() => MessagesScreenState();
}

// Changed to public (removed underscore) so MainNavigationBar can access it via GlobalKey
class MessagesScreenState extends State<MessagesScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  bool _isLoading = true;
  List<Chat> _meetChats = [];
  List<DirectMessage> _directMessages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();

    // If an initialMeetId is provided, find and open that chat after loading
    _checkForInitialMeetChat();
    
    // Listen for tab changes to reload data if needed
    _tabController.addListener(_handleTabChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible
    _loadMessages();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload data when app comes to foreground
      _loadMessages();
    }
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      // Refresh data when tab changes
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkForInitialMeetChat() async {
    if (widget.initialMeetId != null || widget.initialChatId != null) {
      // Wait for messages to load
      await _loadMessages();
      
      // If we have an initial chat ID, use it directly
      if (widget.initialChatId != null && widget.initialChatId!.isNotEmpty) {
        final meetChat = _meetChats.firstWhere(
          (chat) => chat.id == widget.initialChatId,
          orElse: () => Chat(
            id: widget.initialChatId!,
            meetId: widget.initialMeetId ?? '',
            meetTitle: 'Meet Chat',
            meetType: '',
            lastMessage: '',
            lastMessageTime: DateTime.now(),
            unreadCount: 0,
            participantIds: [],
          ),
        );
        
        if (mounted) {
          _navigateToChatDetail(context, meetChat);
        }
        return;
      }
      
      // If we only have a meet ID, find or create a chat for it
      if (widget.initialMeetId != null) {
        // Try to find existing chat in loaded chats
        Chat? meetChat;
        try {
          meetChat = _meetChats.firstWhere(
            (chat) => chat.meetId == widget.initialMeetId,
          );
          
          // Found existing chat, navigate to it
          if (mounted) {
            _navigateToChatDetail(context, meetChat);
            return;
          }
        } catch (e) {
          // Chat not found in loaded chats, will create a new one
          print('Chat for meet ${widget.initialMeetId} not found, creating new one');
        }
        
        // Get the meet details
        final meet = await meetService.getMeetById(widget.initialMeetId!);
        if (meet != null && mounted) {
          // Ensure chat exists for this meet - this is the critical part that was missing
          final chatId = await chatService.createMeetChat(meet);
          
          if (chatId != null && chatId.isNotEmpty) {
            // Update the meet with the chat ID in Firestore
            final meetProvider = Provider.of<MeetProvider>(context, listen: false);
            await meetProvider.updateMeetChatId(meet.id, chatId);
            
            // Reload messages to include the new chat
            await _loadMessages();
            
            // Find the newly created chat
            final createdChat = _meetChats.firstWhere(
              (chat) => chat.id == chatId,
              orElse: () => Chat(
                id: chatId,
                meetId: meet.id,
                meetTitle: meet.title,
                meetType: meet.type,
                lastMessage: 'Chat created',
                lastMessageTime: DateTime.now(),
                unreadCount: 0,
                participantIds: meet.participantIds,
              ),
            );
            
            // Navigate to the chat
            if (mounted) {
              _navigateToChatDetail(context, createdChat);
            }
          }
        }
      }
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? 'demo-user-1';

      // Load chats from Firebase via our ChatService
      final meetChats = await chatService.getMeetChats(userId);
      final directMessages = await chatService.getDirectMessages(userId);

      setState(() {
        _meetChats = meetChats;
        _directMessages = directMessages;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Public method to refresh messages
  void refreshMessages() async {
    await _loadMessages();
    
    // Show feedback to user
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Messages refreshed'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _navigateToChatDetail(BuildContext context, Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          chat: chat,
          chatId: chat.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meetProvider = Provider.of<MeetProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userId = authProvider.user?.uid ?? 'demo-user-1';

    return Column(
      children: [
        // Add TabBar directly without being in AppBar
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Theme.of(context).colorScheme.secondary,
            tabs: const [
              Tab(text: 'Meet Chats'),
              Tab(text: 'Direct Messages'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Meet chats tab - show skeleton UI while loading
              _isLoading
                ? _buildShimmerMessageList(context)
                : _buildMeetChatsTab(meetProvider, userId),

              // Direct messages tab - show skeleton UI while loading
              _isLoading
                ? _buildShimmerMessageList(context) 
                : _buildDirectMessagesTab(userId),
            ],
          ),
        ),
      ],
    );
  }
  
  // Shimmer loading effect for messages list
  Widget _buildShimmerMessageList(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final shimmerColor = Colors.grey.withOpacity(0.2);
    final highlightColor = Colors.grey.withOpacity(0.1);
    
    return ListView.builder(
      itemCount: 5, // Show 5 shimmer message items
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chat avatar placeholder
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: shimmerColor,
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [shimmerColor, highlightColor, shimmerColor],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Chat info placeholder
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title placeholder
                        Container(
                          height: 16,
                          width: 120,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [shimmerColor, highlightColor, shimmerColor],
                            ),
                          ),
                        ),
                        // Time placeholder
                        Container(
                          height: 12,
                          width: 60,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [shimmerColor, highlightColor, shimmerColor],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Message placeholder
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [shimmerColor, highlightColor, shimmerColor],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Type badge placeholder
                    Container(
                      height: 20,
                      width: 70,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [shimmerColor, highlightColor, shimmerColor],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeetChatsTab(MeetProvider meetProvider, String userId) {
    if (_meetChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'No meet chats yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join a meet to start chatting with participants',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to explore screen
                Navigator.pushNamed(context, '/explore');
              },
              icon: const Icon(Icons.explore),
              label: const Text('Explore Meets'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _meetChats.length,
      itemBuilder: (context, index) {
        final chat = _meetChats[index];
        final chatType = chat.meetType;

        // Determine icon and color based on meet type
        IconData typeIcon = Icons.group;
        Color typeColor = Colors.blueGrey;

        switch (chatType.toLowerCase()) {
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

        return InkWell(
          onTap: () {
            _navigateToChatDetail(context, chat);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chat avatar with meet type icon
                CircleAvatar(
                  radius: 24,
                  backgroundColor: typeColor.withOpacity(0.2),
                  child: Icon(typeIcon, color: typeColor),
                ),

                const SizedBox(width: 16),

                // Chat info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat.meetTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatChatTime(chat.lastMessageTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessage,
                              style: TextStyle(
                                color: chat.unreadCount > 0
                                    ? Colors.white
                                    : Colors.grey[500],
                                fontWeight: chat.unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                chat.unreadCount.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              chatType,
                              style: TextStyle(
                                fontSize: 10,
                                color: typeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDirectMessagesTab(String userId) {
    if (_directMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'No direct messages yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with other users',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _directMessages.length,
      itemBuilder: (context, index) {
        final message = _directMessages[index];

        return InkWell(
          onTap: () {
            _navigateToDirectMessageDetail(context, message);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User avatar with online status
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: CachedNetworkImageProvider(message.userPhoto),
                      backgroundColor: Colors.grey[800],
                      child: const Text('?'),
                    ),
                    if (message.online)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Message info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              message.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatChatTime(message.lastMessageTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.lastMessage,
                              style: TextStyle(
                                color: message.unreadCount > 0
                                    ? Colors.white
                                    : Colors.grey[500],
                                fontWeight: message.unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (message.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                message.unreadCount.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatChatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE').format(time); // Day of week
      } else {
        return DateFormat('MM/dd/yy').format(time);
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _navigateToDirectMessageDetail(BuildContext context, DirectMessage message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectMessageScreen(
          dmId: message.id,
          directMessage: message,
        ),
      ),
    );
  }
}

// Chat detail screen
class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final Chat chat;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.chat,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;
  late StreamSubscription<List<Message>> _messagesSubscription;

  @override
  void initState() {
    super.initState();
    // Mark this chat as read
    _markChatAsRead();

    // Subscribe to message updates via stream
    _messagesSubscription = chatService.getChatMessages(widget.chatId).listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });

        // Scroll to bottom on new messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  Future<void> _markChatAsRead() async {
    try {
      // Only attempt to mark as read if the chat ID is not empty
      if (widget.chatId.isEmpty) {
        print('Chat ID is empty, cannot mark as read');
        return;
      }
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? 'demo-user-1';
      await chatService.markChatAsRead(widget.chatId, userId);
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); // Get the theme provider
    
    // Determine color based on chat type for better theming
    IconData typeIcon = Icons.group;
    Color typeColor = Colors.blueGrey;
    
    switch (widget.chat.meetType.toLowerCase()) {
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: meetService.getMeetById(widget.chat.meetId),
              builder: (context, AsyncSnapshot<Meet?> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text(widget.chat.meetTitle);
                }
                
                final meet = snapshot.data;
                if (meet != null) {
                  return Text(meet.title);
                } else {
                  return Text(widget.chat.meetTitle);
                }
              }
            ),
            FutureBuilder(
              future: meetService.getMeetById(widget.chat.meetId),
              builder: (context, AsyncSnapshot<Meet?> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text(
                    "${widget.chat.participantIds.length} participants",
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.secondaryTextColor, // Use theme-specific color
                    ),
                  );
                }
                
                final meet = snapshot.data;
                if (meet != null) {
                  return Text(
                    "${meet.participantIds.length} participants",
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.secondaryTextColor, // Use theme-specific color
                    ),
                  );
                } else {
                  return Text(
                    "${widget.chat.participantIds.length} participants",
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.secondaryTextColor, // Use theme-specific color
                    ),
                  );
                }
              }
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () async {
              // Show meet details
              final meet = await meetService.getMeetById(widget.chat.meetId);
              if (meet != null && mounted) {
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => MeetDetailScreen(meetId: meet.id),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                // Single background image for all chats - fitted instead of repeated
                image: const DecorationImage(
                  image: AssetImage('assets/images/chat_bg.png'),
                  fit: BoxFit.cover,
                  opacity: 0.15,
                ),
                // Gradient background based on theme
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        Colors.black,
                        Colors.black87,
                      ]
                    : [
                        Colors.white,
                        Colors.white.withOpacity(0.9),
                      ],
                ),
              ),
              child: Column(
                children: [
                  // Messages list
                  Expanded(
                    child: _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  typeIcon,
                                  size: 64,
                                  color: typeColor.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet. Start the conversation!',
                                  style: TextStyle(
                                    color: themeProvider.secondaryTextColor, // Use theme-specific color
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];

                              // Get the current user ID to determine if this is our message
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              final userId = authProvider.user?.uid ?? 'demo-user-1';
                              final isMe = message.senderId == userId;

                              return _buildMessageBubble(message, isMe, themeProvider); // Pass themeProvider
                            },
                          ),
                  ),

                  // Message input
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: themeProvider.cardBackgroundColor, // Use theme-specific color
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.add_circle_outline, color: themeProvider.iconColor), // Use theme-specific color
                          onPressed: () {
                            // Show attachment options
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: themeProvider.secondaryTextColor), // Use theme-specific color
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: themeProvider.searchBarColor, // Use theme-specific color
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            minLines: 1,
                            maxLines: 5,
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : Colors.black87), // Adjust text color based on theme
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          color: typeColor, // Use type color for send button
                          onPressed: () {
                            _sendMessage();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message.senderPhoto.isNotEmpty
                  ? CachedNetworkImageProvider(message.senderPhoto)
                  : null,
              backgroundColor: themeProvider.secondaryBackgroundColor, // Use theme-specific color
              child: message.senderPhoto.isEmpty
                  ? Text(message.senderName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.secondaryTextColor, // Use theme-specific color
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Theme.of(context).colorScheme.primary
                        : themeProvider.filterChipBackgroundColor, // Use theme-specific color
                    borderRadius: BorderRadius.circular(16),
                    border: !isMe && Theme.of(context).brightness == Brightness.light
                        ? Border.all(color: themeProvider.borderColor, width: 0.5)
                        : null,
                    // Add subtle shadow to message bubbles
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isMe 
                          ? Colors.white 
                          : Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87, // Adjust text color based on theme
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
                  child: Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: themeProvider.secondaryTextColor, // Use theme-specific color
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isMe) const SizedBox(width: 24),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        throw Exception('You need to be logged in to send messages');
      }

      final userModel = await authService.getCurrentUser();

      if (userModel == null) {
        throw Exception('Failed to get user data');
      }

      await chatService.sendChatMessage(widget.chatId, userModel, message);

      // No need to update state since we're listening to a stream
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    }
  }
}

// Direct message screen
class DirectMessageScreen extends StatefulWidget {
  final String dmId;
  final DirectMessage directMessage;

  const DirectMessageScreen({
    super.key,
    required this.dmId,
    required this.directMessage,
  });

  @override
  State<DirectMessageScreen> createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends State<DirectMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;
  late StreamSubscription<List<Message>> _messagesSubscription;

  @override
  void initState() {
    super.initState();
    // Mark this chat as read
    _markChatAsRead();

    // Subscribe to message updates via stream
    _messagesSubscription = chatService.getDirectChatMessages(widget.dmId).listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });

        // Scroll to bottom on new messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  Future<void> _markChatAsRead() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? 'demo-user-1';
      await chatService.markDirectChatAsRead(widget.dmId, userId);
    } catch (e) {
      print('Error marking direct chat as read: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: CachedNetworkImageProvider(widget.directMessage.userPhoto),
              backgroundColor: themeProvider.secondaryBackgroundColor,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.directMessage.userName),
                Text(
                  widget.directMessage.online ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.directMessage.online ? Colors.green[400] : themeProvider.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              // Initiate call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // Initiate video call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show options
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.block),
                      title: const Text('Block user'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Block feature coming soon')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text('Delete conversation'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Delete feature coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                // Single background image for all chats - fitted instead of repeated
                image: const DecorationImage(
                  image: AssetImage('assets/images/chat_bg.png'),
                  fit: BoxFit.cover,
                  opacity: 0.15,
                ),
                // Gradient background based on theme
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        Colors.black,
                        Colors.black87,
                      ]
                    : [
                        Colors.white,
                        Colors.white.withOpacity(0.9),
                      ],
                ),
              ),
              child: Column(
                children: [
                  // Messages list
                  Expanded(
                    child: _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: themeProvider.secondaryTextColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet. Start the conversation!',
                                  style: TextStyle(
                                    color: themeProvider.secondaryTextColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];

                              // Get the current user ID to determine if this is our message
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              final userId = authProvider.user?.uid ?? 'demo-user-1';
                              final isMe = message.senderId == userId;

                              return _buildMessageBubble(message, isMe, themeProvider);
                            },
                          ),
                  ),

                  // Message input
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: themeProvider.cardBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: themeProvider.iconColor,
                          ),
                          onPressed: () {
                            // Show attachment options
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: themeProvider.secondaryTextColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: themeProvider.searchBarColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            minLines: 1,
                            maxLines: 5,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          color: widget.directMessage.online ? Colors.green : Theme.of(context).colorScheme.primary,
                          onPressed: () {
                            _sendMessage();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: CachedNetworkImageProvider(widget.directMessage.userPhoto),
              backgroundColor: themeProvider.secondaryBackgroundColor,
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Theme.of(context).colorScheme.primary
                        : themeProvider.filterChipBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: !isMe && Theme.of(context).brightness == Brightness.light
                        ? Border.all(color: themeProvider.borderColor, width: 0.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatMessageTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : themeProvider.secondaryTextColor,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 12,
                              color: message.isRead ? Colors.blue : Colors.white70,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isMe) const SizedBox(width: 24),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        throw Exception('You need to be logged in to send messages');
      }

      final userModel = await authService.getCurrentUser();

      if (userModel == null) {
        throw Exception('Failed to get user data');
      }

      await chatService.sendDirectMessage(
        widget.dmId,
        userModel,
        widget.directMessage.userId,
        message,
      );

      // No need to update state since we're listening to a stream
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    }
  }
}