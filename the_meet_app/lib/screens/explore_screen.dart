import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Add for delayed content display
import 'package:the_meet_app/models/meet.dart';
import 'package:the_meet_app/providers/auth_provider.dart';
import 'package:the_meet_app/providers/meet_provider.dart';
import 'package:the_meet_app/providers/user_provider.dart';
import 'package:the_meet_app/providers/theme_provider.dart'; // Add theme provider import
import 'package:intl/intl.dart';
import '../screens/map_screen.dart';
import '../screens/meet_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => ExploreScreenState();
}

// Changed to public (removed underscore) so MainNavigationBar can access it via GlobalKey
class ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _locationSearchQuery = ''; // Added for location search
  
  // Search suggestions
  List<Map<String, dynamic>> _searchSuggestions = [];
  bool _showSuggestions = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _searchFocusNode = FocusNode();
  
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
  
  // Filter options
  String _selectedType = 'All';
  DateTime? _selectedDate;
  
  // List of meet types
  final List<String> _meetTypes = ['All', 'Coffee', 'Study', 'Meal', 'Activity', 'Other'];
  
  // Whether to show filter panel
  bool _showFilterPanel = false;

  // Add pagination variables
  final int _itemsPerPage = 10;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreItems = true;
  List<Meet> _displayedMeets = [];
  
  // Add shimmer loading state
  bool _showShimmerLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Listen for tab changes to handle search differently for map vs list view
    _tabController.addListener(() {
      // When switching tabs, update search behavior
      setState(() {
        if (_tabController.index == 1 && _searchQuery.isNotEmpty) { // Map view
          _locationSearchQuery = _searchQuery;
        }
        // Close suggestions when switching tabs
        _removeSuggestionsOverlay();
      });
    });
    
    // Listen for focus changes on search field
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && 
          _tabController.index == 1 && 
          _searchQuery.isNotEmpty && 
          _searchSuggestions.isNotEmpty) {
        _showSearchSuggestions();
      } else if (!_searchFocusNode.hasFocus) {
        _removeSuggestionsOverlay();
      }
    });
    
    // Refresh meet data when the screen loads
    Future.microtask(() {
      final meetProvider = Provider.of<MeetProvider>(context, listen: false);
      meetProvider.refreshMeets();
    });

    // Delay shimmer loading for 0.5 seconds (reduced from 1 second)
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _showShimmerLoading = false;
      });
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeSuggestionsOverlay();
    super.dispose();
  }

  // Handle search differently based on current tab
  void _handleSearch(String value) {
    setState(() {
      _searchQuery = value;
      
      // If in map view, update location search query but don't move the map yet
      if (_tabController.index == 1) {
        _locationSearchQuery = value;
        
        // Show suggestions if we have text
        if (value.isEmpty) {
          _removeSuggestionsOverlay();
        } else if (_searchSuggestions.isNotEmpty) {
          _showSearchSuggestions();
        }
      } else {
        // For list view, reset pagination to show new filtered results
        _resetPagination();
      }
    });
  }
  
  // Clear search in both tabs
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _locationSearchQuery = '';
      _searchSuggestions = [];
      _removeSuggestionsOverlay();
      _resetPagination();
    });
  }

  // Handle search suggestion results from MapScreen
  void _handleSearchResults(List<Map<String, dynamic>> suggestions) {
    setState(() {
      _searchSuggestions = suggestions;
      
      // If we have suggestions and are in map view, show them
      if (_searchSuggestions.isNotEmpty && 
          _tabController.index == 1 && 
          _searchFocusNode.hasFocus) {
        _showSearchSuggestions();
      } else {
        _removeSuggestionsOverlay();
      }
    });
  }

  // Show suggestions overlay
  void _showSearchSuggestions() {
    _removeSuggestionsOverlay(); // Remove existing overlay if any
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _layerLink.leaderSize?.width ?? MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 48), // Position below search bar
          child: Material(
            elevation: 4.0,
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 200,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _searchSuggestions[index];
                  final placeName = suggestion['place_name'] as String;
                  
                  return ListTile(
                    dense: true,
                    title: Text(
                      placeName,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: const Icon(Icons.location_on, size: 20),
                    onTap: () {
                      // Set the search text to the selected location name
                      _searchController.text = placeName;
                      _searchQuery = placeName;
                      _locationSearchQuery = placeName;
                      
                      // Move map to the selected location using the improved static method
                      MapScreen.moveToLocation(suggestion);
                      
                      // Remove suggestions and unfocus search
                      _removeSuggestionsOverlay();
                      _searchFocusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    _showSuggestions = true;
  }
  
  // Remove suggestions overlay
  void _removeSuggestionsOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _showSuggestions = false;
  }

  void _loadMoreMeets(List<Meet> filteredMeets) {
    if (_isLoadingMore || !_hasMoreItems) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    final start = _currentPage * _itemsPerPage;
    final end = start + _itemsPerPage;
    
    if (start >= filteredMeets.length) {
      setState(() {
        _hasMoreItems = false;
        _isLoadingMore = false;
      });
      return;
    }
    
    setState(() {
      _displayedMeets.addAll(
        filteredMeets.sublist(start, end > filteredMeets.length ? filteredMeets.length : end)
      );
      _currentPage++;
      _isLoadingMore = false;
      
      // Check if all items are loaded
      if (_displayedMeets.length >= filteredMeets.length) {
        _hasMoreItems = false;
      }
    });
  }

  void _resetPagination() {
    setState(() {
      _currentPage = 0;
      _hasMoreItems = true;
      _isLoadingMore = false;
      _displayedMeets = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final meetProvider = Provider.of<MeetProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userId = authProvider.user?.uid ?? '';
    
    // Combine upcoming and nearby meets, remove duplicates, and filter
    final allMeets = [
      ...meetProvider.upcomingMeets,
      ...meetProvider.nearbyMeets
    ];
    final uniqueMeets = {
      for (var m in allMeets) m.id: m
    }.values.toList();
    
    // Filter meets based on search query and filters
    final List<Meet> filteredMeets = uniqueMeets
        .where((meet) {
          if (_searchQuery.isNotEmpty && _tabController.index == 0) { // Only filter list view by search
            return meet.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                meet.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                meet.location.toLowerCase().contains(_searchQuery.toLowerCase());
          }
          return true;
        })
        .where((meet) {
          if (_selectedType != 'All') {
            return meet.type == _selectedType;
          }
          return true;
        })
        .where((meet) {
          if (_selectedDate != null) {
            return meet.time.year == _selectedDate!.year &&
                meet.time.month == _selectedDate!.month &&
                meet.time.day == _selectedDate!.day;
          }
          return true;
        })
        .toList();

    // Only reset pagination when filters change, not on every build
    if (_displayedMeets.isEmpty && !_isLoadingMore) {
      _loadMoreMeets(filteredMeets);
    }
    
    // Create the body content
    final bodyContent = Column(
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
              Tab(text: 'List View'),
              Tab(text: 'Map View'),
            ],
          ),
        ),
        // Search and filter bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Search bar
              CompositedTransformTarget(
                link: _layerLink,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: _tabController.index == 0 
                      ? 'Search for meets...'
                      : 'Search for locations...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.filter_list,
                            color: _showFilterPanel
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          onPressed: () {
                            setState(() {
                              _showFilterPanel = !_showFilterPanel;
                              // Close suggestions when toggling filters
                              _removeSuggestionsOverlay();
                            });
                          },
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: themeProvider.searchBarColor, // Use theme-specific color
                  ),
                  onChanged: _handleSearch,
                  onTap: () {
                    // Show suggestions if we have any when tapping search bar
                    if (_tabController.index == 1 && 
                        _searchQuery.isNotEmpty && 
                        _searchSuggestions.isNotEmpty) {
                      _showSearchSuggestions();
                    }
                  },
                ),
              ),
                
              // Filter options
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _showFilterPanel ? 140 : 0,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      // Types filter
                      const Text(
                        'Meet Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _meetTypes.length,
                          itemBuilder: (context, index) {
                            final type = _meetTypes[index];
                            final isSelected = type == _selectedType;
                            
                            // Color based on type
                            Color typeColor = Colors.blueGrey;
                            if (type == 'Coffee') typeColor = Colors.brown;
                            if (type == 'Study') typeColor = Colors.indigo;
                            if (type == 'Meal') typeColor = Colors.orange;
                            if (type == 'Activity') typeColor = Colors.green;
                            
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(type),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedType = selected ? type : 'All';
                                    _resetPagination();
                                    _loadMoreMeets(filteredMeets);
                                  });
                                },
                                backgroundColor: themeProvider.filterChipBackgroundColor,
                                checkmarkColor: isSelected
                                    ? (type == 'All' ? Colors.blue : typeColor)
                                    : null,
                                selectedColor: type == 'All'
                                    ? Colors.blue.withOpacity(0.2)
                                    : typeColor.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? (type == 'All' ? Colors.blue : typeColor)
                                      : Theme.of(context).brightness == Brightness.light 
                                          ? Colors.black87 
                                          : Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date filter
                      Row(
                        children: [
                          // Date filter
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate ?? DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 90)),
                                    );
                                    if (picked != null && picked != _selectedDate) {
                                      setState(() {
                                        _selectedDate = picked;
                                        _resetPagination();
                                        _loadMoreMeets(filteredMeets);
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: themeProvider.filterChipBackgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _selectedDate == null
                                                ? 'Any Date'
                                                : DateFormat('MMM d, yyyy').format(_selectedDate!),
                                            style: TextStyle(
                                              color: _selectedDate == null
                                                  ? Theme.of(context).brightness == Brightness.light 
                                                      ? Colors.grey[700] 
                                                      : Colors.grey[400]
                                                  : Theme.of(context).brightness == Brightness.light 
                                                      ? Colors.black87 
                                                      : Colors.white,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.calendar_today,
                                          color: _selectedDate == null
                                              ? Colors.grey[400]
                                              : Theme.of(context).colorScheme.primary,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
          
        // Results section - always show UI structure but swap content based on loading state
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await meetProvider.refreshMeets();
              _resetPagination();
              _loadMoreMeets(filteredMeets);
            },
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe to change tabs
              children: [
                // List view - show immediate UI with shimmer loading effect while data loads
                _showShimmerLoading
                  ? _buildShimmerListView()
                  : meetProvider.isLoading
                      ? _buildShimmerListView()
                      : _buildListView(filteredMeets, userId),
                  
                // Map view with search suggestions capability
                meetProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredMeets.isNotEmpty
                      ? MapScreen(
                          key: mapScreenKey, // Use the global key
                          meet: filteredMeets.first,
                          searchQuery: _locationSearchQuery,
                          onSearchResults: _handleSearchResults,
                        )
                      : const Center(child: Text('No meets to show on map')),
              ],
            ),
          ),
        ),
      ],
    );
    
    // Wrap the content in a Scaffold to fix "No Material widget found" errors
    return GestureDetector(
      onTap: () {
        // Close suggestions when tapping outside
        _removeSuggestionsOverlay();
        _searchFocusNode.unfocus();
      },
      child: Scaffold(
        body: bodyContent,
      ),
    );
  }
  
  // Add shimmer loading effect for List View
  Widget _buildShimmerListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Show 5 shimmer items
      itemBuilder: (context, index) {
        return _buildShimmerMeetCard();
      },
    );
  }
  
  Widget _buildShimmerMeetCard() {
    final shimmerColor = Colors.grey.withOpacity(0.3);
    final highlightColor = Colors.grey.withOpacity(0.1);
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image placeholder
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [shimmerColor, highlightColor, shimmerColor],
              ),
            ),
          ),
          
          // Content area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location and time info placeholders
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 14,
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
                    ),
                    const SizedBox(width: 16),
                    Container(
                      height: 14,
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
                
                const SizedBox(height: 12),
                
                // Description placeholder
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
                Container(
                  height: 14,
                  width: 200,
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
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    // View Details button placeholder
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [shimmerColor, highlightColor, shimmerColor],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Join button placeholder
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [shimmerColor, highlightColor, shimmerColor],
                          ),
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
    );
  }
  
  Widget _buildListView(List<Meet> filteredMeets, String userId) {
    if (_displayedMeets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'No meets found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isLoadingMore && 
            _hasMoreItems && 
            scrollInfo.metrics.pixels > 0 && 
            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMoreMeets(filteredMeets);
        }
        return true;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _displayedMeets.length + (_hasMoreItems && _displayedMeets.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _displayedMeets.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: SizedBox(
                  width: 24, 
                  height: 24, 
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                  )
                ),
              ),
            );
          }
          final meet = _displayedMeets[index];
          return _buildMeetCard(meet, userId);
        },
      ),
    );
  }
  
  Widget _buildMeetCard(Meet meet, String userId) {
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
    
    // Check if the user is already a participant
    final bool isParticipant = meet.isParticipant(userId);
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MeetDetailScreen(meetId: meet.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Gradient Overlay and Type Badge
            Stack(
              children: [
                // Cover Image
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: meet.isDefaultImage
                    ? Image.asset(
                        meet.displayImageUrl,
                        fit: BoxFit.cover,
                      )
                    : CachedNetworkImage(
                        imageUrl: meet.displayImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: typeColor.withOpacity(0.2),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: typeColor,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: typeColor.withOpacity(0.2),
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 48,
                              color: typeColor,
                            ),
                          ),
                        ),
                      ),
                ),
                
                // Gradient overlay for better text readability
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                
                // Type badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          typeIcon,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          meet.type,
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
                
                // Time remaining badge
                Positioned(
                  bottom: 48,
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
                
                // Title and host info on the image
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meet.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hosted by ${meet.creatorName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Capacity indicator
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${meet.participantIds.length}/${meet.maxParticipants}',
                          style: TextStyle(
                            fontSize: 12,
                            color: meet.participantIds.length >= meet.maxParticipants
                                ? Colors.red
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Content area
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location and time info
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                meet.location,
                                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('E, MMM d · h:mm a').format(meet.time),
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    meet.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      color: Colors.grey[300],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      // View Details button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MeetDetailScreen(meetId: meet.id),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.grey[800],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Join button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isParticipant || meet.participantIds.length >= meet.maxParticipants
                              ? null // Disable if user is already a participant or meet is full
                              : () {
                                  // Here you would implement the join functionality
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MeetDetailScreen(meetId: meet.id),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: typeColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledForegroundColor: Colors.white.withOpacity(0.6),
                            disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                          ),
                          child: Text(
                            isParticipant
                                ? 'Joined'
                                : meet.participantIds.length >= meet.maxParticipants
                                    ? 'Full'
                                    : 'Join',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
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
  }
}