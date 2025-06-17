import 'package:flutter/material.dart';
import 'package:the_meet_app/pages/create_meet/create_meet_form.dart';
import 'package:the_meet_app/pages/create_meet/safewalk_form.dart';
import 'package:the_meet_app/widgets/consistent_app_bar.dart';

class CreateMeetPage extends StatefulWidget {
  final String meetType;

  const CreateMeetPage({super.key, required this.meetType});

  @override
  State<CreateMeetPage> createState() => _CreateMeetPageState();
}

class _CreateMeetPageState extends State<CreateMeetPage> {
  String _selectedSubtype = '';
  final TextEditingController _customSubtypeController = TextEditingController();
  bool _isCustomSubtype = false;

  // Map of subtypes for each main meet type
  final Map<String, List<String>> _subtypes = {
    'Academic': [
      'Study Group',
      'Research Discussion',
      'Tutoring Session',
      'Project Collaboration',
      'Book Club',
      'Academic Networking',
      'Other',
    ],
    'Social': [
      'Coffee Chat',
      'New Friend Meetup',
      'Game Night',
      'Networking',
      'Language Exchange',
      'Other',
    ],
    'Food': [
      'Meal Sharing',
      'Coffee/Drinks',
      'Restaurant Exploration',
      'Potluck',
      'Food Tasting',
      'Other',
    ],
    'Wellness': [
      'Group Workout',
      'Hiking/Walking',
      'Sports Activity',
      'Meditation Session',
      'Yoga/Pilates',
      'Other',
    ],
    'SafeWalk': [
      'Evening Walk',
      'Late Night Return',
      'Campus Escort',
      'Group Walk',
      'Other',
    ],
    'Event': [
      'Concert/Performance',
      'Sporting Event',
      'Campus Event',
      'Party/Celebration',
      'Cultural Event',
      'Workshop/Seminar',
      'Other',
    ],
    'Custom': [
      'Custom (Specify)',
    ],
  };

  @override
  void initState() {
    super.initState();
    // Initialize with first subtype as default
    if (_subtypes.containsKey(widget.meetType) && _subtypes[widget.meetType]!.isNotEmpty) {
      _selectedSubtype = _subtypes[widget.meetType]![0];
    }
  }

  @override
  void dispose() {
    _customSubtypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If it's a SafeWalk meet, skip the customization and go directly to the SafeWalk form
    if (widget.meetType == 'SafeWalk') {
      return const SafeWalkForm();
    }
    
    // For all other meet types, show the regular customization page
    final subtypeList = _subtypes[widget.meetType] ?? ['Other'];
    final Color typeColor = _getColorForMeetType(widget.meetType);
    final IconData typeIcon = _getIconForMeetType(widget.meetType);

    return Scaffold(
      appBar: ConsistentAppBar(
        title: 'Customize ${widget.meetType} Meet',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meet type header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: typeColor.withOpacity(0.2),
                  child: Icon(typeIcon, color: typeColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.meetType,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Customize your ${widget.meetType} meet',
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
            const SizedBox(height: 24),

            // Subtype selection section
            const Text(
              'What kind of meet is this?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Subtype selection chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subtypeList.map((subtype) {
                final isSelected = _selectedSubtype == subtype;
                final isOther = subtype == 'Other';

                return ChoiceChip(
                  label: Text(subtype),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSubtype = selected ? subtype : '';
                      _isCustomSubtype = subtype == 'Other' && selected;
                    });
                  },
                  backgroundColor: Colors.grey[800],
                  selectedColor: typeColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? typeColor : Colors.white,
                  ),
                );
              }).toList(),
            ),

            // Custom subtype input if "Other" is selected
            if (_isCustomSubtype) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customSubtypeController,
                decoration: InputDecoration(
                  labelText: 'Specify Meet Type',
                  hintText: 'E.g. Chess Club, Coding Challenge, etc.',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(typeIcon, color: typeColor),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Additional options based on meet type
            if (widget.meetType == 'Safety') ...[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.security, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Safety Features',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Safety meets include additional features:'),
                      const SizedBox(height: 8),
                      _buildFeatureItem(
                        icon: Icons.location_on,
                        text: 'Location sharing for participants',
                      ),
                      _buildFeatureItem(
                        icon: Icons.people,
                        text: 'Group notifications when someone arrives',
                      ),
                      _buildFeatureItem(
                        icon: Icons.call,
                        text: 'Emergency contact options',
                      ),
                      _buildFeatureItem(
                        icon: Icons.timer,
                        text: 'Automatic safety check-ins',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            const SizedBox(height: 24),
            
            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Get final meet type (use custom if specified)
                  final finalSubtype = _isCustomSubtype 
                      ? _customSubtypeController.text.trim().isNotEmpty 
                          ? _customSubtypeController.text.trim()
                          : 'Other'
                      : _selectedSubtype;
                  
                  // Create a formatted meet type combining the main type and subtype
                  final finalMeetType = widget.meetType == 'Custom' 
                      ? finalSubtype 
                      : finalSubtype;
                  
                  // Navigate to the form with the specific meet type
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateMeetForm(meetType: finalMeetType),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: typeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Continue to Details',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getColorForMeetType(String meetType) {
    switch (meetType) {
      case 'Safety':
        return Colors.red;
      case 'Academic':
        return Colors.blue;
      case 'Social':
        return Colors.purple;
      case 'Food':
        return Colors.orange;
      case 'Wellness':
        return Colors.green;
      case 'Event':
        return Colors.amber;
      case 'Custom':
        return Colors.teal;
      case 'SafeWalk':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }
  
  IconData _getIconForMeetType(String meetType) {
    switch (meetType) {
      case 'Safety':
        return Icons.security;
      case 'Academic':
        return Icons.school;
      case 'Social':
        return Icons.people;
      case 'Food':
        return Icons.restaurant;
      case 'Wellness':
        return Icons.fitness_center;
      case 'Event':
        return Icons.event;
      case 'Custom':
        return Icons.add_circle_outline;
      case 'SafeWalk':
        return Icons.directions_walk;
      default:
        return Icons.group;
    }
  }
}