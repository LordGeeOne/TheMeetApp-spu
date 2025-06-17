import 'dart:async';
import 'package:flutter/material.dart';
import '../models/meet.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../utils/safewalk_debug_helper.dart';
import '../config/api_config.dart';

// Create a global key that can be used to access the MapScreen state
final GlobalKey<_MapScreenState> mapScreenKey = GlobalKey<_MapScreenState>();

class MapScreen extends StatefulWidget {
  final Meet meet;
  final String searchQuery;
  final Function(List<Map<String, dynamic>> suggestions)? onSearchResults;

  const MapScreen({
    super.key, 
    required this.meet, 
    this.searchQuery = '',
    this.onSearchResults,
  });

  // Static method to move to a location that works regardless of context
  static void moveToLocation(Map<String, dynamic> location) {
    final currentState = mapScreenKey.currentState;
    if (currentState != null) {
      currentState.moveToLocation(location);
    }
  }

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  bool _isLoading = false;
  bool _isSearching = false;
  
  // Default location (will be updated with user's location)
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(-29.0, 24.0), // Default to South Africa
    zoom: 6.0,
  );
  
  bool _locationInitialized = false;
  Set<Marker> _markers = {};
  
  // Search results
  List<Map<String, dynamic>> _searchResults = [];
  LatLng? _searchedLocation;
  String _searchResultName = '';
  String _lastProcessedQuery = '';
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    // Get location when the map initializes
    _initUserLocation();
    // Load API key from platform
    _loadApiKey();
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

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If search query changes, fetch search suggestions
    if (widget.searchQuery.isNotEmpty && 
        widget.searchQuery != oldWidget.searchQuery && 
        widget.searchQuery != _lastProcessedQuery) {
      _fetchSearchSuggestions(widget.searchQuery);
    }
  }

  // Fetch search suggestions without moving the map
  Future<void> _fetchSearchSuggestions(String query) async {
    if (query.isEmpty) {
      if (widget.onSearchResults != null) {
        widget.onSearchResults!([]);
      }
      return;
    }
    
    setState(() {
      _isSearching = true;
      _lastProcessedQuery = query;
    });

    try {
      // Ensure API key is loaded before making the request
      if (_apiKey == null) {
        await _loadApiKey();
      }
      
      // Get current map center for better contextual results
      final GoogleMapController controller = await _controller.future;
      final LatLngBounds bounds = await controller.getVisibleRegion();
      final LatLng center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );
      
      // Use Google Places API with TextSearch for best business results
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=$query'
          '&location=${center.latitude},${center.longitude}'
          '&radius=50000'
          '&region=za'
          '&key=$_apiKey');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        if (results.isNotEmpty) {
          // Convert Google Places results to a format compatible with our app
          final searchResults = results.map((result) {
            return {
              'id': result['place_id'],
              'place_name': result['name'],
              'center': [result['geometry']['location']['lng'], result['geometry']['location']['lat']],
              'address': result['formatted_address'] ?? '',
              'properties': {
                'category': result['types']?.isNotEmpty == true ? result['types'][0] : 'place',
              }
            };
          }).toList();
          
          // Update search results
          setState(() {
            _searchResults = List<Map<String, dynamic>>.from(searchResults);
          });
          
          // Pass search results to parent widget
          if (widget.onSearchResults != null) {
            widget.onSearchResults!(_searchResults);
          }
        } else {
          // If no results found, show error message
          if (widget.onSearchResults != null) {
            widget.onSearchResults!([]);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No locations found for your search')),
            );
          }
        }
      } else {
        if (widget.onSearchResults != null) {
          widget.onSearchResults!([]);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to search location')),
          );
        }
      }
    } catch (e) {
      if (widget.onSearchResults != null) {
        widget.onSearchResults!([]);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // Move map to a selected location
  void moveToLocation(Map<String, dynamic> location) async {
    try {
      final locationName = location['place_name'] as String;
      final coordinates = location['center'] as List;
      final latLng = LatLng(coordinates[1], coordinates[0]); // [longitude, latitude]
      
      setState(() {
        _searchedLocation = latLng;
        _searchResultName = locationName;
        
        // Update markers
        _markers = {
          // Always keep user location marker
          if (_locationInitialized) 
            Marker(
              markerId: const MarkerId('user_location'),
              position: LatLng(_initialCameraPosition.target.latitude, _initialCameraPosition.target.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
            // Add searched location marker
          Marker(
            markerId: const MarkerId('search_result'),
            position: latLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };
      });
      
      // Move the map to the selected location
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: latLng,
          zoom: 15.0,
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moving to location: $e')),
        );
      }
    }
  }

  Future<void> _initUserLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // If permission denied, we'll use the default location
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          setState(() {
            _isLoading = false;
          });
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
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update the current location
      if (mounted) {
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          );
          _locationInitialized = true;
          
          // Add marker for user's location
          _markers = {
            Marker(
              markerId: const MarkerId('user_location'),
              position: LatLng(position.latitude, position.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
          };
        });
        
        // Move camera when controller is available
        if (_controller.isCompleted) {
          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(CameraUpdate.newCameraPosition(_initialCameraPosition));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Show a snackbar if permission is denied
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Show a snackbar if permission is denied forever
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
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update the current location
      if (mounted) {
        setState(() {
          // Clear search results and update markers
          _searchedLocation = null;
          _markers = {
            Marker(
              markerId: const MarkerId('user_location'),
              position: LatLng(position.latitude, position.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
          };
        });
        
        // Move the map to the user's location
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Function to adjust map view to show all relevant markers
  Future<void> _adjustCameraToShowAllMarkers() async {
    if (_markers.isEmpty || _markers.length < 2) return;
    
    try {
      // Calculate the bounds that include all markers
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;
      
      for (var marker in _markers) {
        minLat = math.min(minLat, marker.position.latitude);
        maxLat = math.max(maxLat, marker.position.latitude);
        minLng = math.min(minLng, marker.position.longitude);
        maxLng = math.max(maxLng, marker.position.longitude);
      }
      
      // Create LatLngBounds from the calculated boundaries
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      
      // Get controller and move camera to show all markers
      final controller = await _controller.future;
      
      // Calculate padding based on how close markers are to each other
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
    } catch (e) {
      print('Error adjusting camera view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(      children: [
        GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          myLocationEnabled: false,  // Disable default location button
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,  // Disable the map toolbar (prevents "open in Google Maps" option)
          compassEnabled: false,     // Disable the compass
          markers: _markers,
          rotateGesturesEnabled: true,  // Keep rotation gestures
          scrollGesturesEnabled: true,  // Keep scrolling/panning
          zoomGesturesEnabled: true,    // Keep pinch to zoom
          tiltGesturesEnabled: true,    // Keep tilt gestures
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            if (_locationInitialized) {
              controller.animateCamera(CameraUpdate.newCameraPosition(_initialCameraPosition));
            }
          },
        ),

        // SafeWalk Status Monitor - only show for SafeWalk meets
        if (widget.meet.type.toLowerCase() == 'safewalk')
          Positioned(
            top: 16,
            left: 16,
            child: SafeWalkDebugHelper.createStatusMonitor(),
          ),
        
        // Location button overlay
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,            children: [
              // SafeWalk Debug Button - only show for SafeWalk meets
              if (widget.meet.type.toLowerCase() == 'safewalk')
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SafeWalkDebugHelper.createDebugFAB(context),
                ),
              
              // View all markers button (only shows when there are multiple markers)
              if (_markers.length >= 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: FloatingActionButton(
                    onPressed: _adjustCameraToShowAllMarkers,
                    backgroundColor: Colors.white,
                    elevation: 4,
                    mini: true,
                    tooltip: 'Show all locations',
                    child: const Icon(
                      Icons.crop_free,
                      color: Colors.purple,
                    ),
                  ),
                ),
              
              // My location button
              FloatingActionButton(
                onPressed: _isLoading ? null : _getUserLocation,
                backgroundColor: Colors.white,
                elevation: 4,
                mini: true,
                tooltip: 'My Location',
                child: _isLoading 
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                    ),
              ),
            ],
          ),
        ),
        
        // Initial loading indicator
        if (!_locationInitialized && _isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
          
        // Search loading indicator
        if (_isSearching)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
