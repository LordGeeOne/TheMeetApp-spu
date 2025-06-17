import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_meet_app/providers/auth_provider.dart';
import 'package:the_meet_app/services/service_locator.dart';
import 'package:the_meet_app/services/database_service.dart';
import 'package:the_meet_app/services/meet_service.dart';
import 'package:the_meet_app/services/chat_service.dart';
import 'package:the_meet_app/widgets/consistent_app_bar.dart';
import 'package:the_meet_app/config/api_config.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

// Define our own Prediction class to avoid issues with the package version
class LocationPrediction {
  final String placeId;
  final String description;

  LocationPrediction(this.placeId, this.description);
}

class CreateMeetForm extends StatefulWidget {
  final String meetType;

  const CreateMeetForm({super.key, required this.meetType});

  @override
  State<CreateMeetForm> createState() => _CreateMeetFormState();
}

class _CreateMeetFormState extends State<CreateMeetForm> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _location = '';
  int _maxParticipants = 5;
  final bool _isChatEnabled = true;
  
  // New location data variables
  final TextEditingController _locationController = TextEditingController();
  List<LocationPrediction> _locationPredictions = [];
  bool _isLoadingPredictions = false;
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isGettingCurrentLocation = false;
  String? _apiKey; // Add API key variable

  // Service instances - using late because they'll be initialized in initState
  late DatabaseService _databaseService;
  late MeetService _meetService;
  late ChatService _chatService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  File? _coverImageFile;
  String? _coverImageUrl;
  final ImagePicker _picker = ImagePicker();

  // Time defaults - current date and 30 minutes from now
  DateTime _meetDate = DateTime.now();
  late TimeOfDay _meetTime;

  @override
  void initState() {
    super.initState();
    // Initialize time to 30 minutes from now
    final now = DateTime.now();
    _meetTime = TimeOfDay(
      hour: (now.hour + ((now.minute + 30) ~/ 60)) % 24,
      minute: (now.minute + 30) % 60
    );

    // Initialize services from the service locator globals
    _databaseService = databaseService;
    _meetService = meetService;
    _chatService = chatService;
    
    // Load Google Maps API key
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
      // Fallback to the hardcoded key in case of failure
      _apiKey = ApiConfig.googleMapsApiKey;
    }
  }
  
  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  // Get the color based on meet type
  Color _getMeetTypeColor() {
    switch (widget.meetType.toLowerCase()) {
      case 'coffee':
        return Colors.brown.shade600;
      case 'study':
        return Colors.indigo;
      case 'meal':
        return Colors.orange.shade700;
      case 'activity':
        return Colors.green.shade600;
      case 'custom':
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  // Get the icon based on meet type
  IconData _getMeetTypeIcon() {
    switch (widget.meetType.toLowerCase()) {
      case 'coffee':
        return Icons.coffee;
      case 'study':
        return Icons.school;
      case 'meal':
        return Icons.restaurant;
      case 'activity':
        return Icons.sports;
      case 'custom':
        return Icons.create;
      default:
        return Icons.group;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the bottom padding to account for navigation bars
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final typeColor = _getMeetTypeColor();
    final typeIcon = _getMeetTypeIcon();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: ConsistentAppBar(
        title: 'Create', // Shortened from 'Create ${widget.meetType} Meet'
        backgroundColor: typeColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        bottom: true,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0 + bottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Image Picker
                Center(
                  child: GestureDetector(
                    onTap: _pickCoverImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            image: _coverImageFile != null
                                ? DecorationImage(
                                    image: FileImage(_coverImageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : _coverImageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_coverImageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: _coverImageFile == null && _coverImageUrl == null
                              ? Icon(Icons.add_a_photo,
                                  color: typeColor, size: 48)
                              : null,
                        ),
                        if (_coverImageFile != null || _coverImageUrl != null)
                          Container(
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(Icons.edit, color: Colors.white, size: 32),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Meet type header card
                Container(
                  margin: const EdgeInsets.only(bottom: 16, top: 0),
                  child: Card(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: typeColor.withOpacity(0.2),
                            radius: 24,
                            child: Icon(typeIcon, color: typeColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.meetType,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Creating a new ${widget.meetType} meet',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Title & Description Card
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card header
                        Row(
                          children: [
                            Icon(Icons.title, color: typeColor),
                            const SizedBox(width: 8),
                            const Text(
                              'Basic Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Title field
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Meet Title',
                            hintText: 'Give your meet a catchy name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: typeColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                          onChanged: (value) => _title = value,
                        ),
                        const SizedBox(height: 16),
                        
                        // Description field
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'What will you do together?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: typeColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          maxLines: 3,
                          onChanged: (value) => _description = value,
                        ),
                      ],
                    ),
                  ),
                ),

                // Location Card
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card header
                        Row(
                          children: [
                            Icon(Icons.place, color: typeColor),
                            const SizedBox(width: 8),
                            const Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Location field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              alignment: Alignment.centerRight,
                              children: [
                                TextFormField(
                                  controller: _locationController,
                                  decoration: InputDecoration(
                                    labelText: 'Meet Location',
                                    hintText: 'Where will this happen?',
                                    suffixIcon: _isGettingCurrentLocation 
                                      ? const SizedBox(
                                          width: 20, 
                                          height: 20,
                                          child: Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        )
                                      : IconButton(
                                          icon: Icon(Icons.my_location, color: typeColor),
                                          onPressed: _getCurrentLocation,
                                          tooltip: 'Use current location',
                                        ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: typeColor, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a location';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    _location = value;
                                    _getLocationPredictions(value);
                                  },
                                ),
                              ],
                            ),
                            if (_isLoadingPredictions)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: typeColor,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Searching locations...'),
                                    ],
                                  ),
                                ),
                              ),
                            if (_locationPredictions.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Theme.of(context).colorScheme.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                margin: const EdgeInsets.only(top: 4),
                                constraints: const BoxConstraints(maxHeight: 200),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: _locationPredictions.length,
                                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                                  itemBuilder: (context, index) {
                                    final prediction = _locationPredictions[index];
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      title: Text(prediction.description),
                                      leading: Icon(Icons.place, color: typeColor),
                                      dense: true,
                                      onTap: () => _selectLocation(prediction),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Date & Time Card
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card header
                        Row(
                          children: [
                            Icon(Icons.event, color: typeColor),
                            const SizedBox(width: 8),
                            const Text(
                              'Date & Time',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Date picker - attractive design
                        InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _meetDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: typeColor,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _meetDate = pickedDate;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: typeColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Date',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_meetDate.day}/${_meetDate.month}/${_meetDate.year}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Time picker - attractive design
                        InkWell(
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: _meetTime,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: typeColor,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedTime != null) {
                              setState(() {
                                _meetTime = pickedTime;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: typeColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Time',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _meetTime.format(context),
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Participants Card
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card header
                        Row(
                          children: [
                            Icon(Icons.people, color: typeColor),
                            const SizedBox(width: 8),
                            const Text(
                              'Participants',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Participant slider with visual feedback
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Group Size: $_maxParticipants',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    _maxParticipants <= 5 ? 'Small' : 
                                    _maxParticipants <= 15 ? 'Medium' : 'Large',
                                    style: TextStyle(
                                      color: typeColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: typeColor,
                                inactiveTrackColor: typeColor.withOpacity(0.2),
                                thumbColor: typeColor,
                                overlayColor: typeColor.withOpacity(0.2),
                                valueIndicatorColor: typeColor,
                                valueIndicatorTextStyle: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              child: Slider(
                                value: _maxParticipants.toDouble(),
                                min: 2,
                                max: 50,
                                divisions: 48,
                                label: _maxParticipants.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _maxParticipants = value.round();
                                  });
                                },
                              ),
                            ),
                            // Visual representation of participants
                            SizedBox(
                              height: 30,
                              child: Row(
                                children: [
                                  for (int i = 0; i < (_maxParticipants > 10 ? 10 : _maxParticipants); i++)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: i == 0 
                                            ? typeColor 
                                            : typeColor.withOpacity(0.2),
                                        child: i == 0
                                            ? const Icon(Icons.person, size: 14, color: Colors.white)
                                            : Icon(Icons.person_outline, size: 14, color: typeColor),
                                      ),
                                    ),
                                  if (_maxParticipants > 10)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      margin: const EdgeInsets.only(left: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '+${_maxParticipants - 10}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
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

                // Create Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: typeColor,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline),
                              const SizedBox(width: 8),
                              Text(
                                'Create ${widget.meetType} Meet',
                                style: const TextStyle(
                                  fontSize: 16,
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
        ),
      ),
    );
  }

  Future<void> _pickCoverImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      // Compress image to under 100kb
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        picked.path,
        minWidth: 800,
        minHeight: 600,
        quality: 80,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      File? compressedFile;
      int quality = 80;
      List<int>? result = compressedBytes;
      while ((result != null && result.length > 100 * 1024) && quality > 10) {
        quality -= 10;
        result = await FlutterImageCompress.compressWithFile(
          picked.path,
          minWidth: 800,
          minHeight: 600,
          quality: quality,
          format: CompressFormat.jpeg,
          keepExif: false,
        );
      }
      if (result != null) {
        final tempDir = Directory.systemTemp;
        final tempFile = await File('${tempDir.path}/meet_cover_${DateTime.now().millisecondsSinceEpoch}.jpg').create();
        await tempFile.writeAsBytes(result);
        compressedFile = tempFile;
      }
      setState(() {
        _coverImageFile = compressedFile ?? File(picked.path);
      });
    }
  }

  Future<String?> _uploadCoverImage(String meetId) async {
    if (_coverImageFile == null) return null;
    final storageRef = FirebaseStorage.instance.ref().child('meet_covers/$meetId.jpg');
    final uploadTask = storageRef.putFile(_coverImageFile!);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      if (userId == null) {
        throw Exception('You need to be logged in to create a meet');
      }
      final meetDateTime = DateTime(
        _meetDate.year,
        _meetDate.month,
        _meetDate.day,
        _meetTime.hour,
        _meetTime.minute,
      );
      final locationMap = {
        'address': _location,
        'latitude': _latitude,
        'longitude': _longitude,
      };
      final requirements = <String, dynamic>{};
      // Add default image directly to meet creation if no image was selected
      final additionalDetails = <String, dynamic>{
        'imageUrl': _coverImageFile == null ? 'default_cover' : '',
      };
      final meetId = await _databaseService.createMeet(
        type: widget.meetType,
        title: _title,
        description: _description,
        meetTime: meetDateTime,
        location: locationMap,
        maxParticipants: _maxParticipants,
        requirements: requirements,
        additionalDetails: additionalDetails,
        creatorId: userId,
      );
      String? imageUrl;
      if (meetId != null && _coverImageFile != null) {
        imageUrl = await _uploadCoverImage(meetId);
        if (imageUrl != null) {
          await _databaseService.updateMeetImage(meetId, imageUrl);
        }
      }
      // We don't need the else clause anymore as we set 'default_cover' in additionalDetails
      
      if (meetId != null && _isChatEnabled) {
        await _meetService.getMeetById(meetId).then((meet) async {
          if (meet != null) {
            // Create a chat for this meet and get the chat ID
            final chatId = await _chatService.createMeetChat(meet);
            
            // Update the meet with the chat ID
            if (chatId != null && chatId.isNotEmpty) {
              await _firestore.collection('meets').doc(meetId).update({
                'chatId': chatId
              });
              print('Chat created and linked to meet: $chatId');
            }
          }
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meet created successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create meet: ${e.toString()}'), backgroundColor: Colors.red),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _getLocationPredictions(String input) async {
    if (input.length < 3) {
      setState(() {
        _locationPredictions = [];
        _isLoadingPredictions = false;
      });
      return;
    }
    
    setState(() {
      _isLoadingPredictions = true;
    });
      try {
      // Use Google Places API to get predictions
      final apiKey = _apiKey ?? ApiConfig.googleMapsApiKey; // Use loaded API key or fallback
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&types=establishment|geocode';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          setState(() {
            _locationPredictions = predictions
                .map((prediction) => LocationPrediction(
                      prediction['place_id'] as String,
                      prediction['description'] as String,
                    ))
                .toList();
            _isLoadingPredictions = false;
          });
        } else {
          setState(() {
            _locationPredictions = [];
            _isLoadingPredictions = false;
          });
        }
      } else {
        setState(() {
          _locationPredictions = [];
          _isLoadingPredictions = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationPredictions = [];
        _isLoadingPredictions = false;
      });
      print('Error getting location predictions: $e');
    }
  }
  
  Future<void> _selectLocation(LocationPrediction prediction) async {
    setState(() {
      _locationController.text = prediction.description;
      _location = prediction.description;
      _locationPredictions = [];
    });
      try {
      // Get place details to extract coordinates
      final apiKey = _apiKey ?? ApiConfig.googleMapsApiKey; // Use loaded API key or fallback
      final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=${prediction.placeId}&key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];
          setState(() {
            _latitude = location['lat'];
            _longitude = location['lng'];
          });
        } else {
          _showErrorSnackBar('Could not retrieve location details');
        }
      } else {
        _showErrorSnackBar('Failed to load location details');
      }
    } catch (e) {
      _showErrorSnackBar('Error getting location details');
      print('Error getting location details: $e');
    }
  }
  
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingCurrentLocation = true;
    });
    
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permissions are denied');
          setState(() {
            _isGettingCurrentLocation = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('Location permissions are permanently denied');
        setState(() {
          _isGettingCurrentLocation = false;
        });
        return;
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition();
        // Reverse geocode to get address
      final apiKey = _apiKey ?? ApiConfig.googleMapsApiKey; // Use loaded API key or fallback
      final url = 
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final address = data['results'][0]['formatted_address'];
          setState(() {
            _locationController.text = address;
            _location = address;
            _latitude = position.latitude;
            _longitude = position.longitude;
            _isGettingCurrentLocation = false;
          });
        } else {
          _showErrorSnackBar('Could not get address for current location');
          setState(() {
            _isGettingCurrentLocation = false;
          });
        }
      } else {
        _showErrorSnackBar('Failed to get address for current location');
        setState(() {
          _isGettingCurrentLocation = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error getting current location');
      setState(() {
        _isGettingCurrentLocation = false;
      });
      print('Error getting current location: $e');
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
