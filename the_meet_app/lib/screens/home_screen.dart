import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Add for delayed content display
import 'package:the_meet_app/models/meet.dart';
import 'package:the_meet_app/providers/auth_provider.dart';
import 'package:the_meet_app/providers/meet_provider.dart';
import 'package:the_meet_app/providers/user_provider.dart';
import 'package:the_meet_app/pages/create_meet/meet_templates_page.dart';
import 'package:the_meet_app/pages/create_meet/create_meet_page.dart';
import 'package:the_meet_app/screens/meet_detail_screen.dart';
import 'package:the_meet_app/screens/all_upcoming_meets_screen.dart';
import 'package:the_meet_app/widgets/main_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

// Changed to public (removed underscore) so MainNavigationBar can access it via GlobalKey
class HomeScreenState extends State<HomeScreen> {
  bool _showShimmer = true; // State to control shimmer visibility

  // Helper function for time remaining calculation
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
  void initState() {
    super.initState();
    // Refresh meet data and user data when the screen loads
    Future.microtask(() {
      final meetProvider = Provider.of<MeetProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // First ensure we have the user's data
      if (authProvider.user != null && !userProvider.isLoaded) {
        userProvider.loadUserData(authProvider.user!.uid);
      }
      
      // Then load the meets data
      meetProvider.refreshMeets();
      userProvider.loadUserMeets();
    });

    // Delay shimmer for 0.5 seconds (reduced from 2 seconds)
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _showShimmer = false;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final meetProvider = Provider.of<MeetProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';
    
    // Getting upcoming and nearby meets using available properties
    final upcomingMeets = userProvider.participatingMeets.isNotEmpty 
      ? userProvider.participatingMeets 
      : meetProvider.upcomingMeets.where((meet) => meet.isParticipant(userId)).toList();
    
    final nearbyMeets = meetProvider.nearbyMeets;
    
    final primaryColor = Theme.of(context).colorScheme.primary;
    final accentColor = Theme.of(context).colorScheme.secondary;
    
    // Main body content - always showing structure immediately
    final bodyContent = RefreshIndicator(
      onRefresh: () async {
        await meetProvider.refreshMeets();
        await userProvider.loadUserMeets();
        return;
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header with user greeting
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${userProvider.currentUser?.displayName.split(' ')[0] ?? 'there'}!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Find meaningful connections today',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick actions - Always visible
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickActionButton(
                    context,
                    Icons.add_location_alt_rounded,
                    'Create',
                    Colors.orangeAccent,
                    _navigateToCreateMeet,
                  ),
                  _buildQuickActionButton(
                    context,
                    Icons.explore,
                    'Discover',
                    Colors.blueAccent,
                    () {
                      // Navigate to the MainNavigationBar route, passing the explore tab index
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MainNavigationBar(),
                          settings: const RouteSettings(name: 'MainNavigationBar', arguments: 1),
                        ),
                      );
                    },
                  ),
                  _buildQuickActionButton(
                    context,
                    Icons.security,
                    'SafeWalk',
                    Colors.redAccent,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateMeetPage(meetType: 'SafeWalk'),
                          settings: const RouteSettings(name: 'SafeWalk'),
                        ),
                      ).then((value) {
                        // This code will run after returning from CreateMeetPage
                        // We can add refresh logic here if needed
                        final meetProvider = Provider.of<MeetProvider>(context, listen: false);
                        meetProvider.refreshMeets();
                      });
                    },
                  ),
                  _buildQuickActionButton(
                    context,
                    Icons.favorite,
                    'Saved',
                    Colors.pinkAccent,
                    () {
                      _showSavedMeetsDialog();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            
            // Upcoming meets section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Upcoming Meets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _navigateToAllUpcomingMeets(upcomingMeets);
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(color: accentColor),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: meetProvider.isLoading || userProvider.isLoading || _showShimmer
                  ? _buildShimmerLoading(true) // Shimmer loading effect for horizontal list
                  : upcomingMeets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No upcoming meets',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          scrollDirection: Axis.horizontal,
                          itemCount: upcomingMeets.length,
                          itemBuilder: (context, index) {
                            final meet = upcomingMeets[index];
                            return GestureDetector(
                              onTap: () => _navigateToMeetDetails(meet),
                              child: _buildUpcomingMeetCard(context, meet),
                            );
                          },
                        ),
            ),
            
            const SizedBox(height: 24),
            
            // Nearby meets section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Happening Near You',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      meetProvider.refreshMeets();
                    },
                    child: Text(
                      'Refresh',
                      style: TextStyle(color: accentColor),
                    ),
                  ),
                ],
              ),
            ),
            meetProvider.isLoading || _showShimmer
              ? _buildShimmerLoading(false) // Shimmer loading effect for vertical list
              : nearbyMeets.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No meets found nearby',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: nearbyMeets.length,
                    itemBuilder: (context, index) {
                      final meet = nearbyMeets[index];
                      return GestureDetector(
                        onTap: () => _navigateToMeetDetails(meet),
                        child: _buildNearbyMeetItemFromModel(context, meet),
                      );
                    },
                  ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    
    return Scaffold(
      body: bodyContent,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateMeet,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // Create shimmer loading effect for placeholders
  Widget _buildShimmerLoading(bool isHorizontal) {
    return isHorizontal
        ? ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: 3, // Show 3 shimmer cards
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: _buildShimmerCard(),
              );
            },
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 2, // Show 2 shimmer items
            itemBuilder: (context, index) {
              return _buildShimmerListItem();
            },
          );
  }

  Widget _buildShimmerCard() {
    final shimmerColor = Colors.grey.withOpacity(0.3);
    final highlightColor = Colors.grey.withOpacity(0.1);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 180,
        height: 180,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 90,
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            // Info placeholders
            Container(
              height: 12,
              width: 80,
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
            const SizedBox(height: 4),
            Container(
              height: 12,
              width: 100,
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
      ),
    );
  }

  Widget _buildShimmerListItem() {
    final shimmerColor = Colors.grey.withOpacity(0.3);
    final highlightColor = Colors.grey.withOpacity(0.1);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          // Image placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [shimmerColor, highlightColor, shimmerColor],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title placeholder
                  Container(
                    height: 18,
                    width: 150,
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
                  const SizedBox(height: 12),
                  // Info placeholders
                  Container(
                    height: 14,
                    width: 180,
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
                  Container(
                    height: 14,
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
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 80,
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
            ),
          ),
        ],
      ),
    );
  }
  
  void _navigateToCreateMeet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MeetTemplatesPage()),
    );
  }
  
  void _navigateToMeetDetails(Meet meet) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MeetDetailScreen(meetId: meet.id)),
    );
  }

  void _navigateToAllUpcomingMeets(List<Meet> upcomingMeets) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllUpcomingMeetsScreen(upcomingMeets: upcomingMeets),
      ),
    );
  }
  
  Widget _buildQuickActionButton(
    BuildContext context, 
    IconData icon, 
    String label, 
    Color color, 
    VoidCallback onTap
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUpcomingMeetCard(BuildContext context, Meet meet) {
    final IconData typeIcon = _getIconForMeetType(meet.type);
    final Color typeColor = _getColorForMeetType(meet.type);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: SizedBox(
        width: 180,
        // Removed height constraint to allow the card to size based on content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image section
            Stack(
              children: [
                SizedBox(
                  height: 90, // Slightly reduced height to give more space to content
                  width: double.infinity,
                  child: meet.isDefaultImage
                      ? Image.asset(
                          meet.displayImageUrl,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          meet.displayImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error, size: 24),
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          meet.type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Content section - more compact padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meet.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _getTimeRemaining(meet.time),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Location row
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          meet.location,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Time row
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          DateFormat('E, h:mm a').format(meet.time),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Participants row
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${meet.participantIds.length}/${meet.maxParticipants}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
  }

  Widget _buildNearbyMeetItemFromModel(BuildContext context, Meet meet) {
    final IconData typeIcon = _getIconForMeetType(meet.type);
    final Color typeColor = _getColorForMeetType(meet.type);
    const double imageSize = 120.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: () => _navigateToMeetDetails(meet),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with time remaining overlay - making sure no space at bottom
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: imageSize,
                height: imageSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    meet.isDefaultImage
                      ? Image.asset(
                          meet.displayImageUrl,
                          fit: BoxFit.cover,
                          width: imageSize,
                          height: imageSize,
                        )
                      : Image.network(
                          meet.displayImageUrl,
                          fit: BoxFit.cover,
                          width: imageSize,
                          height: imageSize,
                          errorBuilder: (context, error, stack) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error, size: 32),
                          ),
                        ),
                    // Time remaining badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getTimeRemaining(meet.time),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            meet.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(typeIcon, color: typeColor, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                meet.type,
                                style: TextStyle(
                                  color: typeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            meet.location,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            DateFormat('E, MMM d • h:mm a').format(meet.time),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${meet.participantIds.length}/${meet.maxParticipants} participants',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getIconForMeetType(String meetType) {
    switch (meetType.toLowerCase()) {
      case 'study':
        return Icons.school;
      case 'coffee':
        return Icons.coffee;
      case 'meal':
        return Icons.restaurant;
      case 'activity':
        return Icons.sports_basketball;
      case 'custom':
        return Icons.add_circle_outline;
      default:
        return Icons.group;
    }
  }
  
  Color _getColorForMeetType(String meetType) {
    switch (meetType.toLowerCase()) {
      case 'study':
        return Colors.blue;
      case 'coffee':
        return Colors.brown;
      case 'meal':
        return Colors.orange;
      case 'activity':
        return Colors.green;
      case 'custom':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  // Function to show SafeWalk feature dialog
  void _showSafeWalkDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SafeWalk Feature'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.security,
              size: 64,
              color: Colors.redAccent,
            ),
            SizedBox(height: 16),
            Text(
              'SafeWalk helps you get home safely by connecting you with other students walking in the same direction.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'This feature will be available in the next update.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Function to show saved meets dialog
  void _showSavedMeetsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved Meets'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite,
              size: 64,
              color: Colors.pinkAccent,
            ),
            SizedBox(height: 16),
            Text(
              'Save meets you\'re interested in for easier access later.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'This feature will be available in the next update.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}