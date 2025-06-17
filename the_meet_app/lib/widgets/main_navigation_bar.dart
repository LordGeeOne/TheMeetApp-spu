import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_meet_app/providers/auth_provider.dart';
import 'package:the_meet_app/providers/meet_provider.dart';
import 'package:the_meet_app/providers/theme_provider.dart';
import 'package:the_meet_app/providers/user_provider.dart';
import 'package:the_meet_app/screens/home_screen.dart';
import 'package:the_meet_app/screens/messages_screen.dart';
import 'package:the_meet_app/screens/explore_screen.dart';
import 'package:the_meet_app/screens/profile_page.dart';
import 'package:the_meet_app/screens/notifications_screen.dart';
import 'package:the_meet_app/screens/search_screen.dart';

class MainNavigationBar extends StatefulWidget {
  const MainNavigationBar({super.key});

  @override
  State<MainNavigationBar> createState() => _MainNavigationBarState();
}

class _MainNavigationBarState extends State<MainNavigationBar> {
  int _selectedIndex = 0;
  
  // GlobalKeys to access each screen's state - using the proper public state classes
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();
  final GlobalKey<ProfilePageState> _profilePageKey = GlobalKey<ProfilePageState>();
  final GlobalKey<MessagesScreenState> _messagesScreenKey = GlobalKey<MessagesScreenState>();
  final GlobalKey<ExploreScreenState> _exploreScreenKey = GlobalKey<ExploreScreenState>();

  // List of content widgets without their own app bars
  late final List<Widget> _contentWidgets = <Widget>[
    _ScreenContent(child: HomeScreen(key: _homeScreenKey)),
    _ScreenContent(child: ExploreScreen(key: _exploreScreenKey)),
    _ScreenContent(child: MessagesScreen(key: _messagesScreenKey)),
    _ScreenContent(child: ProfilePage(key: _profilePageKey)),
  ];

  // Screen titles
  final List<String> _titles = [
    'Home',
    'Explore',
    'Messages',
    'Profile',
  ];

  // Handle navigation
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if we need to navigate to a specific tab from route settings
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int && args >= 0 && args < _contentWidgets.length) {
        setState(() {
          _selectedIndex = args;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use Provider.of for the authentication check
    final authProvider = Provider.of<AuthProvider>(context);
    
    // If the user is not logged in, redirect to login
    if (!authProvider.isAuthenticated) {
      // Use Future.microtask to avoid build phase errors
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/login');
      });

      // Return loading screen while redirecting
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Get the theme colors directly
    final navBarColor = Theme.of(context).brightness == Brightness.light
        ? Colors.white
        : Theme.of(context).colorScheme.surface;
    
    final selectedColor = Theme.of(context).colorScheme.primary;
    
    final unselectedColor = Theme.of(context).brightness == Brightness.light 
        ? Colors.grey.shade600 
        : Colors.grey.shade400;

    // Reused widgets - create once
    const bottomNavBarType = BottomNavigationBarType.fixed;
    const navBarElevation = 8.0;
    const navBarIconSize = 26.0;
    const navBarSelectedFontSize = 12.0;
    const navBarUnselectedFontSize = 11.0;
    
    return Scaffold(
      // Persistent AppBar that stays across all tab changes
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
        // Add screen-specific action buttons
        actions: _buildAppBarActions(_selectedIndex),
      ),
      body: _contentWidgets.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: bottomNavBarType,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: _titles[0],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore_outlined),
            activeIcon: const Icon(Icons.explore),
            label: _titles[1],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            activeIcon: const Icon(Icons.chat_bubble),
            label: _titles[2],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: _titles[3],
          ),
        ],
        currentIndex: _selectedIndex,
        elevation: navBarElevation,
        iconSize: navBarIconSize,
        selectedFontSize: navBarSelectedFontSize,
        unselectedFontSize: navBarUnselectedFontSize,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        backgroundColor: navBarColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }

  // Helper method to build screen-specific app bar actions
  List<Widget> _buildAppBarActions(int index) {
    switch (index) {
      case 0: // Home screen
        return [
          IconButton(
            icon: const Icon(Icons.search, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 22),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
        ];
      case 1: // Explore screen
        return [];  // Using TabBar in body, no actions needed
      case 2: // Messages screen
        return [
          IconButton(
            icon: const Icon(Icons.search, size: 22),
            onPressed: () {
              // Implement search in messages
              // This would typically search through messages
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message search coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: () {
              // Use global key to access the state
              if (_messagesScreenKey.currentState != null) {
                // Call the public method
                _messagesScreenKey.currentState!.refreshMessages();
              } else {
                // Fallback if state is not accessible
                final meetProvider = Provider.of<MeetProvider>(context, listen: false);
                meetProvider.refreshMeets();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshing messages...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ];
      case 3: // Profile screen
        // Access the isEditing state from ProfilePageState
        // This will now be re-evaluated when MainNavigationBar rebuilds
        bool isEditing = _profilePageKey.currentState?.mounted == true && _profilePageKey.currentState!.isEditing;
        return [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit), // Change icon based on edit mode
            onPressed: () {
              // Use global key to access the state
              if (_profilePageKey.currentState != null) {
                _profilePageKey.currentState!.toggleEditMode(onToggled: () {
                  setState(() {}); // Rebuild MainNavigationBar to update the icon
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () {
              // Navigate to the new SettingsScreen
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ];
      default:
        return [];
    }
  }
}

// Wrapper widget to provide content without its own AppBar
class _ScreenContent extends StatelessWidget {
  const _ScreenContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar here - using the parent's AppBar
      body: child,
      // No BottomNavigationBar here - using the parent's
    );
  }
}