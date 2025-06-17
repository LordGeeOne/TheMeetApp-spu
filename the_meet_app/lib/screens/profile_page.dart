import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_meet_app/providers/auth_provider.dart' as app_auth_provider; // Added prefix
import 'package:the_meet_app/providers/meet_provider.dart';
import 'package:the_meet_app/providers/theme_provider.dart';
import 'package:the_meet_app/models/meet.dart';
import 'package:the_meet_app/models/user_model.dart';
import 'package:the_meet_app/screens/meet_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // Added import for DateFormat
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider; // Hide Firebase's AuthProvider to avoid conflict

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

// Changed to public (removed underscore) so MainNavigationBar can access it via GlobalKey
class ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditing = false;
  bool get isEditing => _isEditing; // Public getter for _isEditing
  bool _isLoading = false; 
  bool _isUploadingProfileImage = false; 

  final ImagePicker _picker = ImagePicker();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  List<String> _interests = [];
  // Added for more diverse common interests
  final List<String> _commonInterests = [
    'Sports', 'Music', 'Arts', 'Technology', 'Science', 
    'Reading', 'Travel', 'Cooking', 'Gaming', 'Photography',
    'Fitness', 'Movies', 'Nature', 'Fashion', 'History',
    'Dancing', 'Writing', 'Volunteering', 'Yoga', 'Hiking'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Fetch the complete user data when the page is loaded
    Future.microtask(() {
      final authProvider = Provider.of<app_auth_provider.AuthProvider>(context, listen: false); // Use prefixed AuthProvider
      authProvider.refreshUserData();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Initialize text controllers with user data
  void _initializeControllers(UserModel user) {
    _nameController.text = user.displayName;
    _bioController.text = user.bio;
    _interests = List.from(user.interests);
  }
  
  // Public methods to be called from MainNavigationBar
  void toggleEditMode({VoidCallback? onToggled}) { // Added optional callback
    setState(() {
      _isEditing = !_isEditing;
      
      // If we're closing edit mode, save the changes
      if (!_isEditing) {
        final authProvider = Provider.of<app_auth_provider.AuthProvider>(context, listen: false); // Use prefixed AuthProvider
        final user = authProvider.user;
        
        if (user != null && _nameController.text.isNotEmpty) {
          _saveProfileChanges(authProvider); // Fixed missing semicolon
        }
      }
    });
    onToggled?.call(); // Call the callback after setState
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth_provider.AuthProvider>(context); // Use prefixed AuthProvider
    final meetProvider = Provider.of<MeetProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context); // Get theme data for easier access
    
    final user = authProvider.user;
    
    // If user data is null, show loading or error
    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Initialize controllers with current data if needed
    if (_nameController.text.isEmpty && !_isEditing) {
      _initializeControllers(user);
    }
    
    return Scaffold( 
      body: CustomScrollView( 
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0, 
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.surface, 
            elevation: 2,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: _isEditing 
                  ? null 
                  : Text(
                      user.displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  user.photoURL.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.photoURL,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: theme.colorScheme.surfaceContainerHighest),
                          errorWidget: (context, url, error) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.person, size: 80, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.primaryContainer, 
                          child: Icon(Icons.person, size: 100, color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7)),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                  if (_isEditing) 
                    Positioned(
                      right: 16,
                      bottom: 16, 
                      child: Material(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        elevation: 4,
                        child: InkWell(
                          onTap: _isUploadingProfileImage ? null : _showChangeProfileImageDialog, // Updated onTap
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ),
                  if (_isUploadingProfileImage)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
            actions: null, // Ensured local edit button is removed
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditing)
                    _buildEditableProfileFields(user, themeProvider, theme)
                  else
                    _buildReadOnlyProfileInfo(user, themeProvider, theme),
                  
                  const SizedBox(height: 30),
                  
                  Text(
                    'Interests',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInterestsSection(themeProvider, theme),
                  
                  const SizedBox(height: 30),
                  // Ensured Save Changes button is removed
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5), // Subtle background for tabs
              child: TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Your Meets'),
                  Tab(text: 'Joined Meets'),
                ],
              ),
            ),
          ),
          SliverFillRemaining( // Use SliverFillRemaining to ensure TabBarView fills available space
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildYourMeetsTab(meetProvider, user.uid, themeProvider, theme),
                _buildJoinedMeetsTab(meetProvider, user.uid, themeProvider, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableProfileFields(UserModel user, ThemeProvider themeProvider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Display Name',
            hintText: 'How you appear to others',
            prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary.withOpacity(0.7)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surface.withOpacity(0.5),
          ),
          style: theme.textTheme.bodyLarge,
          validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _bioController,
          decoration: InputDecoration(
            labelText: 'Bio',
            hintText: 'Tell us about yourself (max 150 characters)',
            prefixIcon: Icon(Icons.edit_note_outlined, color: theme.colorScheme.primary.withOpacity(0.7)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surface.withOpacity(0.5),
            alignLabelWithHint: true,
          ),
          style: theme.textTheme.bodyLarge,
          maxLines: 3,
          maxLength: 150,
        ),
        const SizedBox(height: 12),
        Text(
          user.email,
          style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
        ),
        const SizedBox(height: 20),
        _buildStatsRow(user, themeProvider, theme, isEditing: true),
      ],
    );
  }

  Widget _buildReadOnlyProfileInfo(UserModel user, ThemeProvider themeProvider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // Center align read-only info
      children: [
        // Name is in AppBar, so no need to repeat here unless desired
        // const SizedBox(height: 8), // Space from AppBar title if it were here
        Text(
          user.email,
          style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            user.bio.isNotEmpty ? user.bio : 'No bio yet.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5, color: theme.textTheme.bodySmall?.color?.withOpacity(0.9)),
          ),
        ),
        const SizedBox(height: 24),
        _buildStatsRow(user, themeProvider, theme),
      ],
    );
  }

  Widget _buildStatsRow(UserModel user, ThemeProvider themeProvider, ThemeData theme, {bool isEditing = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isEditing ? Colors.transparent : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Created', user.meetsCreated.toString(), themeProvider, theme),
          _buildStatColumn('Joined', user.meetsJoined.toString(), themeProvider, theme),
          _buildStatColumn('Member Since', _formatDate(user.joinDate), themeProvider, theme),
        ],
      ),
    );
  }
  
  Widget _buildStatColumn(String label, String value, ThemeProvider themeProvider, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection(ThemeProvider themeProvider, ThemeData theme) {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _commonInterests.map((interest) {
              final isSelected = _interests.contains(interest);
              return FilterChip(
                label: Text(interest),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      if (_interests.length < 7) {
                        _interests.add(interest);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You can select up to 7 interests.'), backgroundColor: Colors.orangeAccent),
                        );
                      }
                    } else {
                      _interests.remove(interest);
                    }
                  });
                },
                backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                selectedColor: theme.colorScheme.primaryContainer,
                checkmarkColor: theme.colorScheme.onPrimaryContainer,
                labelStyle: TextStyle(
                    color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.textTheme.bodyLarge?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Add another interest...',
              suffixIcon: IconButton(
                icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                onPressed: () {
                  // This requires a TextEditingController for the custom interest field
                  // For now, let's assume _showAddInterestDialog handles it or we create one.
                  _showAddInterestDialog(context); 
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: theme.colorScheme.surface.withOpacity(0.5),
            ),
            onFieldSubmitted: (value) {
              if (value.trim().isNotEmpty && !_interests.contains(value.trim())) {
                 if (_interests.length < 7) {
                    setState(() {
                      _interests.add(value.trim());
                    });
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You can select up to 7 interests.'), backgroundColor: Colors.orangeAccent),
                      );
                  }
              }
              // Clear field after submit could be added here if a controller is used
            },
          ),
          const SizedBox(height: 12),
          if (_interests.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _interests.map((interest) => Chip(
                label: Text(interest),
                onDeleted: () {
                  setState(() {
                    _interests.remove(interest);
                  });
                },
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                labelStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                deleteIconColor: theme.colorScheme.primary.withOpacity(0.7),
              )).toList(),
            ),
        ],
      );
    } else {
      // Read-only view of interests
      if (_interests.isEmpty) {
        return Text('No interests added yet.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)));
      }
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _interests
            .map<Widget>((interest) => Chip(
                label: Text(interest),
                backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                labelStyle: TextStyle(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ))
            .toList(),
      );
    }
  }
  
  Widget _buildYourMeetsTab(MeetProvider meetProvider, String userId, ThemeProvider themeProvider, ThemeData theme) {
    final createdMeets = meetProvider.upcomingMeets
        .where((meet) => meet.creatorId == userId)
        .toList();
    
    if (createdMeets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 64, color: theme.textTheme.bodySmall?.color?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No meets created yet',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Time to host your own! Tap below to get started.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/create_meet');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create a New Meet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: createdMeets.length,
      itemBuilder: (context, index) {
        final meet = createdMeets[index];
        return _buildMeetListItem(meet, true, themeProvider, theme);
      },
    );
  }
  
  Widget _buildJoinedMeetsTab(MeetProvider meetProvider, String userId, ThemeProvider themeProvider, ThemeData theme) {
    final joinedMeets = meetProvider.upcomingMeets
        .where((meet) => meet.isParticipant(userId) && meet.creatorId != userId)
        .toList();
    
    if (joinedMeets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 64, color: theme.textTheme.bodySmall?.color?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No meets joined yet',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover and join meets to connect with others.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/explore');
              },
              icon: const Icon(Icons.search),
              label: const Text('Explore Meets Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: joinedMeets.length,
      itemBuilder: (context, index) {
        final meet = joinedMeets[index];
        return _buildMeetListItem(meet, false, themeProvider, theme);
      },
    );
  }
  
  Widget _buildMeetListItem(Meet meet, bool isCreator, ThemeProvider themeProvider, ThemeData theme) {
    IconData typeIcon = Icons.group;
    Color typeColor = theme.colorScheme.secondary;

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

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      color: theme.cardColor,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MeetDetailScreen(meetId: meet.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            meet.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCreator)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Created',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meet.location,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat("MMM d, yyyy 'at' h:mm a", Localizations.localeOf(context).toString()).format(meet.time),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people_outline, size: 16, color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              '${meet.participantIds.length}/${meet.maxParticipants}',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
    );
      
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 30) {
      return '${difference.inDays} days';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'}';
    }
  }
  
  void _saveProfileChanges(app_auth_provider.AuthProvider authProvider) { // Use prefixed AuthProvider
    setState(() {
      _isLoading = true;
    });
    
    // Update the user profile in Firestore
    authProvider.updateProfile(
      displayName: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      interests: _interests,
    ).then((success) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
  
  void _showAddInterestDialog(BuildContext context) {
    final TextEditingController interestController = TextEditingController();
    final theme = Theme.of(context); // Get theme for dialog styling
    
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Add a New Interest', style: theme.textTheme.titleLarge),
          content: TextField(
            controller: interestController,
            decoration: InputDecoration(
              labelText: 'Interest Name',
              hintText: 'e.g., Hiking, Coding, Painting',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: theme.colorScheme.surface.withOpacity(0.5),
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty && !_interests.contains(value.trim())) {
                if (_interests.length < 7) {
                    setState(() {
                      _interests.add(value.trim());
                    });
                    Navigator.of(dialogContext).pop();
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You can select up to 7 interests.'), backgroundColor: Colors.orangeAccent),
                      );
                  }
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7))),
            ),
            ElevatedButton(
              onPressed: () {
                final interest = interestController.text.trim();
                if (interest.isNotEmpty && !_interests.contains(interest)) {
                  if (_interests.length < 7) {
                    setState(() {
                       _interests.add(interest);
                    });
                    Navigator.of(dialogContext).pop();
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You can select up to 7 interests.'), backgroundColor: Colors.orangeAccent),
                      );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
              child: Text('Add Interest', style: TextStyle(color: theme.colorScheme.onPrimary)),
            ),
          ],
        );
      },
    ).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        interestController.dispose();
      });
    });
  }
  
  void _showChangeProfileImageDialog() {
    final authProvider = Provider.of<app_auth_provider.AuthProvider>(context, listen: false); // Use prefixed AuthProvider
    final user = authProvider.user!;
    final theme = Theme.of(context); // Get theme for dialog styling
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Update Profile Picture', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: theme.colorScheme.primary),
              title: Text('Choose from Gallery', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: theme.colorScheme.primary),
              title: Text('Take a Photo', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (user.photoURL.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                title: Text('Remove Photo', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error)),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePicture();
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7))),
          ),
        ],
      ),
    );
  }

  void _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      if (!mounted) return;
      setState(() {
        _isUploadingProfileImage = true; 
      });
      await _processAndUploadImage(File(pickedFile.path));
      // _isUploadingProfileImage will be set to false in _processAndUploadImage's finally block
    }
  }
  
  void _takePhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      if (!mounted) return;
      setState(() {
        _isUploadingProfileImage = true;
      });
      await _processAndUploadImage(File(pickedFile.path));
      // _isUploadingProfileImage will be set to false in _processAndUploadImage's finally block
    }
  }
  
  Future<void> _processAndUploadImage(File imageFile) async {
    if (mounted) {
      setState(() {
        _isUploadingProfileImage = true;
      });
    }

    try {
      final authProvider = Provider.of<app_auth_provider.AuthProvider>(context, listen: false); // Use prefixed AuthProvider
      final userFromProvider = authProvider.user;
      final currentUserFromFirebaseAuth = FirebaseAuth.instance.currentUser;

      print('--- Profile Image Upload Debug ---');
      if (userFromProvider == null) {
        print('AuthProvider.user is NULL at the start of _processAndUploadImage.');
      } else {
        print('AuthProvider.user ID: ${userFromProvider.uid}, Email: ${userFromProvider.email}');
      }

      if (currentUserFromFirebaseAuth == null) {
        print('FirebaseAuth.instance.currentUser is NULL.');
        throw Exception('User not authenticated in FirebaseAuth instance.');
      } else {
        print('FirebaseAuth.instance.currentUser ID: ${currentUserFromFirebaseAuth.uid}, Email: ${currentUserFromFirebaseAuth.email}');
        
        try {
          print('Attempting to refresh Firebase Auth token...');
          final idTokenResult = await currentUserFromFirebaseAuth.getIdTokenResult(true);
          print('Token refreshed. New token issued at: ${idTokenResult.issuedAtTime}, Expires: ${idTokenResult.expirationTime}');
        } catch (e) {
          print('Error refreshing Firebase Auth token: $e');
        }
      }
      
      final user = currentUserFromFirebaseAuth; 
      final String userId = user.uid;
      
      print('Using User ID for storage path: $userId');
      
      const int targetSizeBytes = 100 * 1024;
      
      var compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        minWidth: 500,
        minHeight: 500,
        quality: 80,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      
      File? compressedFileToUpload;
      List<int>? bytesToUpload = compressedBytes;
      
      if (bytesToUpload != null && bytesToUpload.length > targetSizeBytes) {
        int quality = 70;
        while (quality >= 20 && bytesToUpload != null && bytesToUpload.length > targetSizeBytes) {
          bytesToUpload = await FlutterImageCompress.compressWithFile(
            imageFile.path, 
            minWidth: 400, 
            minHeight: 400,
            quality: quality,
            format: CompressFormat.jpeg,
            keepExif: false,
          );
          quality -= 10;
        }
        
        if (bytesToUpload != null && bytesToUpload.length > targetSizeBytes) {
          bytesToUpload = await FlutterImageCompress.compressWithFile(
            imageFile.path,
            minWidth: 300,
            minHeight: 300,
            quality: 60, 
            format: CompressFormat.jpeg,
            keepExif: false,
          );
        }
      }
      
      if (bytesToUpload != null) {
        final tempDir = Directory.systemTemp;
        final tempFile = await File('${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg').create();
        await tempFile.writeAsBytes(bytesToUpload);
        compressedFileToUpload = tempFile;
        
        print('Original size: ${imageFile.lengthSync()} bytes');
        print('Compressed size: ${compressedFileToUpload.lengthSync()} bytes');
      } else {
         print('Compression resulted in null bytes. Uploading original file.');
      }
      
      final String userIdForPath = user.uid; 
      print('Final check - User ID for storage path: $userIdForPath, User Email: ${user.email}');
      
      final storageRef = FirebaseStorage.instance.ref().child('user_images/$userIdForPath.jpg');
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userIdForPath},
        cacheControl: 'public, max-age=31536000', 
      );
      
      final uploadTask = storageRef.putFile(
        compressedFileToUpload ?? imageFile, 
        metadata,
      );
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Profile image upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      }, onError: (error) {
        print('Upload task stream error: $error'); 
      });
      
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      await authProvider.updateProfile(photoURL: downloadUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingProfileImage = false;
        });
      }
      print('--- End Profile Image Upload Debug ---');
    }
  }
  
  Future<void> _removeProfilePicture() async {
    setState(() {
      _isUploadingProfileImage = true; // Show loading indicator during removal
    });
    try {
      final authProvider = Provider.of<app_auth_provider.AuthProvider>(context, listen: false); // Use prefixed AuthProvider
      
      await authProvider.updateProfile(photoURL: ''); // Send empty string to remove
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // No loading state to reset here for remove, but good practice if one was added
      if (mounted) {
        setState(() {
          // If _isUploadingProfileImage was true for removal, set it to false here
        });
      }
    }
  }
}