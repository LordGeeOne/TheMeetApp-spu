import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:the_meet_app/models/meet.dart';
import 'package:the_meet_app/providers/auth_provider.dart';
import 'package:the_meet_app/widgets/consistent_app_bar.dart';
import 'package:the_meet_app/widgets/safewalk_monitor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:the_meet_app/config/api_config.dart';

// Helper class to track marker animation state
class AnimatedMarkerPosition {
  final String markerId;
  LatLng currentPosition;
  LatLng? targetPosition;
  AnimationController? animationController;
  Animation<double>? animation;
  
  AnimatedMarkerPosition({
    required this.markerId, 
    required this.currentPosition,
    this.targetPosition,
  });
}

class MeetMapScreen extends StatefulWidget {
  final Meet meet;

  const MeetMapScreen({
    super.key,
    required this.meet,
  });

  @override
  State<MeetMapScreen> createState() => _MeetMapScreenState();
}

class _MeetMapScreenState extends State<MeetMapScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();
  
  // Map configuration
  late CameraPosition _initialCameraPosition;
  final Set<Marker> _markers = {};
  Map<String, dynamic> _userMarkers = {};
  
  // Animation related
  final Map<String, AnimatedMarkerPosition> _animatedMarkers = {};
  final Duration _markerAnimationDuration = const Duration(milliseconds: 500);
  
  // Directions
  final Set<Polyline> _polylines = {};
  List<LatLng> _directionPoints = [];
  
  // States
  bool _isLoading = true;
  bool _directionsLoaded = false;
  bool _isLiveLocationEnabled = false;
  bool _isSettingLiveLocation = false;
  Timer? _locationUpdateTimer;
  String? _apiKey;
  
  // User info
  String _userId = '';
  
  // Location data
  LatLng? _userLocation;
  LatLng? _meetLocation;
  
  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }
  
  Future<void> _initializeMapData() async {
    final meetLat = widget.meet.latitude;
    final meetLng = widget.meet.longitude;
    
    // Set default meet location if coordinates are available
    _meetLocation = (meetLat != 0 && meetLng != 0)
        ? LatLng(meetLat, meetLng)
        : null;
    
    // Get user ID
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userId = authProvider.user?.uid ?? '';
    
    // Load the API key
    await _loadApiKey();
    
    // Initialize map position based on meet location or default to South Africa
    _initialCameraPosition = _meetLocation != null
        ? CameraPosition(target: _meetLocation!, zoom: 14.0)
        : const CameraPosition(
            target: LatLng(-29.0, 24.0), // Default to South Africa
            zoom: 6.0,
          );
    
    // Get the current user location
    await _getUserLocation();
    
    // Add the meet location marker if available
    if (_meetLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('meet_location'),
          position: _meetLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: widget.meet.title,
            snippet: widget.meet.location,
          ),
        ),
      );
    }
    
    // Add user location marker if available
    if (_userLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
          ),
        ),
      );
      
      // Get directions from user location to meet location
      if (_meetLocation != null) {
        await _getDirections();
      }
    }
    
    // Check if live location is already enabled for this meet
    await _checkLiveLocationStatus();
    
    setState(() {
      _isLoading = false;
    });
  }
    // Load API key from AndroidManifest metadata
  Future<void> _loadApiKey() async {
    try {
      // Access the Google Maps API key from the platform
      _apiKey = await const MethodChannel('com.themeetapp/google_maps')
          .invokeMethod<String>('getGoogleMapsApiKey');
    } catch (e) {
      print('Failed to load API key from platform: $e');
      // Fallback to the configured key in case of failure
      _apiKey = ApiConfig.googleMapsApiKey;
    }
  }
  
  Future<void> _getUserLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // If permission denied, show a message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // If permission permanently denied, show settings option
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permissions are permanently denied, please enable them in settings'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  openAppSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }
  
  Future<void> _getDirections() async {
    if (_userLocation == null || _meetLocation == null || _apiKey == null) {
      return;
    }
    
    try {
      // Construct the URL for the Directions API
      final directionsUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${_userLocation!.latitude},${_userLocation!.longitude}'
        '&destination=${_meetLocation!.latitude},${_meetLocation!.longitude}'
        '&key=$_apiKey'
      );
      
      // Make the request
      final response = await http.get(directionsUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          // Decode polyline points
          if (data['routes'].isNotEmpty) {
            final points = PolylinePoints()
                .decodePolyline(data['routes'][0]['overview_polyline']['points']);
            
            List<LatLng> polylineCoordinates = [];
            for (var point in points) {
              polylineCoordinates.add(LatLng(point.latitude, point.longitude));
            }
            
            setState(() {
              _directionPoints = polylineCoordinates;
              _polylines.add(
                Polyline(
                  polylineId: const PolylineId('directions'),
                  color: Colors.blue,
                  points: polylineCoordinates,
                  width: 5,
                ),
              );
              _directionsLoaded = true;
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to get directions: ${data['status']}')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to connect to directions service')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting directions: $e')),
        );
      }
    }
  }
  
  Future<void> _checkLiveLocationStatus() async {
    try {
      final locationRef = FirebaseFirestore.instance
          .collection('meet_locations')
          .doc(widget.meet.id);
          
      final doc = await locationRef.get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final userLocations = data['user_locations'] as Map<String, dynamic>? ?? {};
        
        setState(() {
          _isLiveLocationEnabled = userLocations.containsKey(_userId);
          _userMarkers = userLocations;
        });
        
        // Add markers for other users
        if (userLocations.isNotEmpty) {
          _updateUserMarkersOnMap(userLocations);
        }
      }
    } catch (e) {
      print('Error checking live location status: $e');
    }
  }
  
  void _toggleLiveLocation() async {
    if (_userId.isEmpty || _userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to enable live location')),
      );
      return;
    }
    
    setState(() {
      _isSettingLiveLocation = true;
    });
    
    try {
      final locationRef = FirebaseFirestore.instance
          .collection('meet_locations')
          .doc(widget.meet.id);
      
      if (_isLiveLocationEnabled) {
        // Turn off live location
        await locationRef.update({
          'user_locations.$_userId': FieldValue.delete(),
        });
        
        // Stop the update timer
        _locationUpdateTimer?.cancel();
        _locationUpdateTimer = null;
        
      } else {
        // Turn on live location - create or update the document
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .get();
        
        final String displayName = userData.exists && userData.data() != null
            ? userData.data()!['displayName'] ?? 'User'
            : 'User';
            
        final locationData = {
          'user_locations.$_userId': {
            'latitude': _userLocation!.latitude,
            'longitude': _userLocation!.longitude,
            'last_updated': FieldValue.serverTimestamp(),
            'display_name': displayName,
          }
        };
        
        await locationRef.set(locationData, SetOptions(merge: true));
        
        // Start the location update timer
        _startLocationUpdates();
      }
      
      setState(() {
        _isLiveLocationEnabled = !_isLiveLocationEnabled;
      });
      
      // Listen for other users' location updates
      _listenToLocationUpdates();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating live location: $e')),
      );
    } finally {
      setState(() {
        _isSettingLiveLocation = false;
      });
    }
  }
  
  void _startLocationUpdates() {
    // Update location every 10 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!_isLiveLocationEnabled || _userId.isEmpty) {
        timer.cancel();
        return;
      }
      
      try {
        // Get updated location
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        final locationRef = FirebaseFirestore.instance
            .collection('meet_locations')
            .doc(widget.meet.id);
            
        await locationRef.update({
          'user_locations.$_userId.latitude': position.latitude,
          'user_locations.$_userId.longitude': position.longitude,
          'user_locations.$_userId.last_updated': FieldValue.serverTimestamp(),
        });
        
        final newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _userLocation = newLocation;
          
          // Animate the user's own marker using the same animation system
          _animateMarkerToLocation(
            'user_location',
            newLocation,
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            title: 'Your Location',
          );
        });
        
      } catch (e) {
        print('Error updating location: $e');
      }
    });
  }
  
  void _listenToLocationUpdates() {
    FirebaseFirestore.instance
        .collection('meet_locations')
        .doc(widget.meet.id)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      
      final data = snapshot.data() as Map<String, dynamic>;
      final userLocations = data['user_locations'] as Map<String, dynamic>? ?? {};
      
      setState(() {
        _userMarkers = userLocations;
      });
      
      _updateUserMarkersOnMap(userLocations);
      
      // Automatically adjust camera view to show all users whenever locations change
      if (userLocations.length > 1) {
        _adjustCameraToShowAllUsers();
      }
    });
  }
  
  void _updateUserMarkersOnMap(Map<String, dynamic> userLocations) {
    // We no longer remove markers here as the animation system handles updates
    
    // Add or update animated markers for all other users
    for (var entry in userLocations.entries) {
      final userId = entry.key;
      if (userId == _userId) continue; // Skip own user
      
      final userData = entry.value as Map<String, dynamic>;
      final lat = userData['latitude'] as double?;
      final lng = userData['longitude'] as double?;
      final name = userData['display_name'] as String? ?? 'User';
      
      if (lat != null && lng != null) {
        final userLatLng = LatLng(lat, lng);
        final markerId = 'user_$userId';
        
        // Animate the marker to its new position
        _animateMarkerToLocation(
          markerId,
          userLatLng,
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          title: name,
          snippet: 'Participant',
        );
      }
    }
  }
  
  @override
  void dispose() {
    // Dispose all animation controllers
    for (final animatedMarker in _animatedMarkers.values) {
      animatedMarker.animationController?.dispose();
    }
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
  
  // Create or update an animated marker
  void _animateMarkerToLocation(
    String markerId, 
    LatLng targetLocation, 
    BitmapDescriptor icon,
    {String? title, String? snippet}
  ) {
    // If the marker doesn't exist in our tracking system yet, create it
    if (!_animatedMarkers.containsKey(markerId)) {
      _animatedMarkers[markerId] = AnimatedMarkerPosition(
        markerId: markerId,
        currentPosition: targetLocation,
      );
      
      // Add the marker at its initial position
      _markers.add(Marker(
        markerId: MarkerId(markerId),
        position: targetLocation,
        icon: icon,
        infoWindow: InfoWindow(
          title: title ?? '',
          snippet: snippet,
        ),
      ));
      
      setState(() {});
      return;
    }
    
    final animatedMarker = _animatedMarkers[markerId]!;
    
    // If there's an ongoing animation, stop it
    if (animatedMarker.animationController != null && 
        animatedMarker.animationController!.isAnimating) {
      animatedMarker.animationController!.stop();
    }
    
    // Create a new controller for this animation
    animatedMarker.animationController?.dispose();
    animatedMarker.animationController = AnimationController(
      duration: _markerAnimationDuration,
      vsync: this,
    );
    
    // Store the start and target positions
    final startPosition = animatedMarker.currentPosition;
    animatedMarker.targetPosition = targetLocation;
    
    // Create a Tween animation
    animatedMarker.animation = CurvedAnimation(
      parent: animatedMarker.animationController!,
      curve: Curves.easeInOut,
    );
    
    // Listen for animation updates
    animatedMarker.animationController!.addListener(() {
      if (!mounted) return;
      
      final animationValue = animatedMarker.animation!.value;
      
      // Interpolate between start and target positions
      final lat = startPosition.latitude + 
          (targetLocation.latitude - startPosition.latitude) * animationValue;
      final lng = startPosition.longitude + 
          (targetLocation.longitude - startPosition.longitude) * animationValue;
      
      final newPosition = LatLng(lat, lng);
      
      // Update current position
      animatedMarker.currentPosition = newPosition;
      
      // Update the actual marker on the map
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == markerId);
        _markers.add(Marker(
          markerId: MarkerId(markerId),
          position: newPosition,
          icon: icon,
          infoWindow: InfoWindow(
            title: title ?? '',
            snippet: snippet,
          ),
        ));
      });
    });
    
    // When animation completes, update the final position
    animatedMarker.animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animatedMarker.currentPosition = targetLocation;
        animatedMarker.targetPosition = null;
      }
    });
    
    // Start the animation
    animatedMarker.animationController!.forward();
  }

  // Automatically adjust camera to show all users
  Future<void> _adjustCameraToShowAllUsers() async {
    if (_userMarkers.isEmpty) return;
    
    try {
      // Collect all user locations to create bounds
      List<LatLng> userLocations = [];
      
      // Add meet location if available
      if (_meetLocation != null) {
        userLocations.add(_meetLocation!);
      }
      
      // Add current user's location if available
      if (_userLocation != null) {
        userLocations.add(_userLocation!);
      }
      
      // Add all other users' locations
      for (var entry in _userMarkers.entries) {
        // Skip the current user as we've already added their position
        if (entry.key == _userId) continue;
        
        final userData = entry.value as Map<String, dynamic>;
        final lat = userData['latitude'] as double?;
        final lng = userData['longitude'] as double?;
        
        if (lat != null && lng != null) {
          userLocations.add(LatLng(lat, lng));
        }
      }
      
      // Proceed if we have at least 2 locations to create bounds
      if (userLocations.length >= 2) {
        // Calculate the bounds that include all user locations
        double minLat = double.infinity;
        double maxLat = -double.infinity;
        double minLng = double.infinity;
        double maxLng = -double.infinity;
        
        for (var location in userLocations) {
          minLat = math.min(minLat, location.latitude);
          maxLat = math.max(maxLat, location.latitude);
          minLng = math.min(minLng, location.longitude);
          maxLng = math.max(maxLng, location.longitude);
        }
        
        // Create LatLngBounds from the calculated boundaries
        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );
        
        // Get controller and move camera to show all markers
        final controller = await _controller.future;
        
        // Calculate padding based on how close users are to each other
        // When users are closer together, we add more padding for better visibility
        // We calculate the distance between the furthest points to determine zoom level
        double latDist = maxLat - minLat;
        double lngDist = maxLng - minLng;
        
        // The smaller the distance, the more padding we need relatively speaking
        double distanceRatio = math.max(latDist, lngDist);
        
        // Adjust padding based on distance - closer = more padding for better visibility
        double padding = distanceRatio < 0.001 ? 150 : // Very close
                        distanceRatio < 0.005 ? 120 : // Close
                        distanceRatio < 0.01 ? 100 :  // Moderate distance
                        80;                           // Far apart
        
        // Use animated camera to smoothly move to the new position
        controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
      }
    } catch (e) {
      print('Error adjusting camera view: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    // Determine color based on meet type
    Color typeColor = Colors.blueGrey;
    switch (widget.meet.type.toLowerCase()) {
      case 'coffee':
        typeColor = Colors.brown;
        break;
      case 'study':
        typeColor = Colors.indigo;
        break;
      case 'meal':
        typeColor = Colors.orange;
        break;
      case 'activity':
        typeColor = Colors.green;
        break;
    }
    
    return SafeWalkMonitor(
      meet: widget.meet,
      child: Scaffold(
      appBar: ConsistentAppBar(
        title: widget.meet.title,
        backgroundColor: typeColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Map
          _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: true,
              compassEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
            
          // Floating buttons panel at the bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meet name and location
                    Text(
                      widget.meet.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.meet.location,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Display count of users sharing location
                        if (_userMarkers.isNotEmpty)
                          Text(
                            '${_userMarkers.length} ${_userMarkers.length == 1 ? 'person' : 'people'} sharing location',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          
                        // Live location toggle
                        Row(
                          children: [
                            Text(
                              'Live Location',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _isLiveLocationEnabled ? typeColor : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _isSettingLiveLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Switch(
                                  value: _isLiveLocationEnabled,
                                  activeColor: typeColor,
                                  onChanged: (value) => _toggleLiveLocation(),
                                ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Recenter and directions buttons
          Positioned(
            bottom: 96,
            right: 16,
            child: Column(
              children: [
                // Recenter button
                FloatingActionButton(
                  heroTag: 'recenterBtn',
                  onPressed: () async {
                    if (_userLocation != null) {
                      final controller = await _controller.future;
                      controller.animateCamera(CameraUpdate.newLatLngZoom(
                        _userLocation!,
                        15,
                      ));
                    } else {
                      await _getUserLocation();
                      if (_userLocation != null) {
                        final controller = await _controller.future;
                        controller.animateCamera(CameraUpdate.newLatLngZoom(
                          _userLocation!,
                          15,
                        ));
                      }
                    }
                  },
                  backgroundColor: Colors.white,
                  mini: true,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                // Directions button
                FloatingActionButton(
                  heroTag: 'directionsBtn',
                  onPressed: _directionsLoaded 
                    ? () async {
                        // Zoom to fit both markers in view
                        if (_userLocation != null && _meetLocation != null) {
                          final controller = await _controller.future;
                          
                          final bounds = LatLngBounds(
                            southwest: LatLng(
                              _userLocation!.latitude < _meetLocation!.latitude 
                                  ? _userLocation!.latitude 
                                  : _meetLocation!.latitude,
                              _userLocation!.longitude < _meetLocation!.longitude 
                                  ? _userLocation!.longitude 
                                  : _meetLocation!.longitude,
                            ),
                            northeast: LatLng(
                              _userLocation!.latitude > _meetLocation!.latitude 
                                  ? _userLocation!.latitude 
                                  : _meetLocation!.latitude,
                              _userLocation!.longitude > _meetLocation!.longitude 
                                  ? _userLocation!.longitude 
                                  : _meetLocation!.longitude,
                            ),
                          );
                          
                          controller.animateCamera(CameraUpdate.newLatLngBounds(
                            bounds,
                            70, // padding
                          ));
                        }
                      } 
                    : () async {
                        await _getDirections();
                      },
                  backgroundColor: Colors.white,
                  mini: true,
                  child: Icon(
                    Icons.directions,
                    color: _directionsLoaded ? Colors.green : typeColor,
                  ),
                ),
                const SizedBox(height: 8),
                // Adjust camera to show all users button
                FloatingActionButton(
                  heroTag: 'adjustCameraBtn',
                  onPressed: _adjustCameraToShowAllUsers,
                  backgroundColor: Colors.white,
                  mini: true,
                  child: const Icon(Icons.group, color: Colors.purple),                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}