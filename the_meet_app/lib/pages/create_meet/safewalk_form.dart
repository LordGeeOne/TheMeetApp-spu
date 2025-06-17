import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_meet_app/providers/auth_provider.dart';
import 'package:the_meet_app/services/service_locator.dart';
import 'package:the_meet_app/widgets/consistent_app_bar.dart';

class SafeWalkForm extends StatefulWidget {
  const SafeWalkForm({super.key});

  @override
  State<SafeWalkForm> createState() => _SafeWalkFormState();
}

class _SafeWalkFormState extends State<SafeWalkForm> {
  final _formKey = GlobalKey<FormState>();
  String _description = '';
  String? _startLocation;
  String? _endLocation;
  int _maxParticipants = 5;
  bool _isSubmitting = false;
  bool _notifySecurity = true;
  bool _enableEmergencyAlerts = true;

  // SPU campus locations
  final List<String> _campusLocations = [
    // Residences
    'Kopano Residence',
    'Ametis Residence',
    'Ithemba Residence',
    'Ubuntu Residence',
    'YCrescent Residence',
    'South Point Residence',
    'Student Village',
    // Main campus areas
    'South Campus Main Gate',
    'North Campus Main Gate',
    'Central Campus',
    'Library',
    'Student Centre',
    'Sport Centre',
    'Rathaga',
    'Mhudi Precinct',
    'Medical School',
    'Science Building',
    'Engineering Building',
    'Art Centre',
    'Commerce Building',
    'Law Building',
    // Off-campus nearby locations
    'Campus Square Mall',
    'Melville',
    'Auckland Park',
    'Bus Station',
    'Train Station',
  ];

  // Time defaults - current date and 15 minutes from now
  DateTime _meetDate = DateTime.now();
  late TimeOfDay _meetTime;

  @override
  void initState() {
    super.initState();
    // Initialize time to 15 minutes from now
    final now = DateTime.now();
    _meetTime = TimeOfDay(
      hour: (now.hour + ((now.minute + 15) ~/ 60)) % 24,
      minute: (now.minute + 15) % 60
    );
  }

  String _generateTitle() {
    if (_startLocation == null || _endLocation == null) {
      return 'SafeWalk';
    }
    return 'SafeWalk from $_startLocation to $_endLocation';
  }

  @override
  Widget build(BuildContext context) {
    // Get the bottom padding to account for navigation bars
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      appBar: const ConsistentAppBar(
        title: 'SafeWalk',  // Shortened from 'SPU SafeWalk'
      ),
      body: SafeArea(
        bottom: true,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + bottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SafeWalk header with security notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'SPU CAMPUS SECURITY SERVICE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Security will be notified of your route and will monitor your progress in real-time.',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'EMERGENCY: Press power button 5 times to send a panic alert during your walk.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Location section
                _buildSectionHeader('Route Information'),
                
                // Start location dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Starting Location *',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  value: _startLocation,
                  hint: const Text('Select starting point'),
                  isExpanded: true,
                  items: _campusLocations.map((location) => 
                    DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    )
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      _startLocation = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a starting location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // End location dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Destination *',
                    prefixIcon: Icon(Icons.flag),
                    border: OutlineInputBorder(),
                  ),
                  value: _endLocation,
                  hint: const Text('Select destination'),
                  isExpanded: true,
                  items: _campusLocations.map((location) => 
                    DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    )
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      _endLocation = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your destination';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Additional notes
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes',
                    hintText: 'Any specific details or concerns (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (value) => _description = value,
                ),
                const SizedBox(height: 16),
                
                _buildSectionHeader('Date & Time'),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(
                    '${_meetDate.day}/${_meetDate.month}/${_meetDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _meetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 7)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _meetDate = pickedDate;
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('Time'),
                  subtitle: Text(_meetTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: _meetTime,
                    );
                    if (pickedTime != null) {
                      setState(() {
                        _meetTime = pickedTime;
                      });
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                _buildSectionHeader('Group Size'),
                Row(
                  children: [
                    Expanded(
                      child: Text('Maximum Participants: $_maxParticipants'),
                    ),
                    Slider(
                      value: _maxParticipants.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: Colors.red,
                      label: _maxParticipants.toString(),
                      onChanged: (value) {
                        setState(() {
                          _maxParticipants = value.round();
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                _buildSectionHeader('Security Features'),
                
                SwitchListTile(
                  title: const Text('Notify Campus Security'),
                  subtitle: const Text('Security will be alerted of your route and status'),
                  value: _notifySecurity,
                  activeColor: Colors.red,
                  onChanged: (value) {
                    setState(() {
                      _notifySecurity = value;
                    });
                  },
                ),
                
                SwitchListTile(
                  title: const Text('Enable Emergency Alerts'),
                  subtitle: const Text('Press power button 5 times to send panic alert'),
                  value: _enableEmergencyAlerts,
                  activeColor: Colors.red,
                  onChanged: (value) {
                    setState(() {
                      _enableEmergencyAlerts = value;
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Preview: ${_generateTitle()}',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create SafeWalk'),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'SPU Campus security: 0800-SAFETY (0800-723389)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
        throw Exception('You need to be logged in to create a SafeWalk');
      }
      
      final meetDateTime = DateTime(
        _meetDate.year,
        _meetDate.month,
        _meetDate.day,
        _meetTime.hour,
        _meetTime.minute,
      );
      
      // Generate title from locations
      final title = _generateTitle();
      
      final locationMap = {
        'address': 'From $_startLocation to $_endLocation',
        'startLocation': _startLocation,
        'endLocation': _endLocation,
        'latitude': 0.0, // In a real app, you would use geocoding here
        'longitude': 0.0, // to convert address to coordinates
      };
      
      final requirements = <String, dynamic>{};
      final additionalDetails = <String, dynamic>{
        'notifySecurity': _notifySecurity,
        'enableEmergencyAlerts': _enableEmergencyAlerts,
        'isSafeWalk': true,
        'spuStudentsOnly': true,
      };
      
      final meetId = await databaseService.createMeet(
        type: 'SafeWalk',
        title: title,
        description: _description,
        meetTime: meetDateTime,
        location: locationMap,
        maxParticipants: _maxParticipants,
        requirements: requirements,
        additionalDetails: additionalDetails,
        creatorId: userId,
      );
      
      if (meetId != null) {
        // Create a chat for this meet when it's successfully created
        await meetService.getMeetById(meetId).then((meet) {
          if (meet != null) {
            chatService.createMeetChat(meet);
            
            // In a real app, this would notify campus security
            if (_notifySecurity) {
              securityService.notifySecurity(meet);
            }
          }
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SafeWalk created successfully! Security has been notified.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Go back to home screen
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create SafeWalk: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}