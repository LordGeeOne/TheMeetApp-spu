import 'package:flutter/material.dart';
import 'package:the_meet_app/widgets/consistent_app_bar.dart';
import 'create_meet_page.dart';

class MeetTemplatesPage extends StatelessWidget {
  const MeetTemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the bottom padding to account for navigation bars
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      appBar: const ConsistentAppBar(
        title: 'Create a Meet',
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a Meet Type',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a template as a starting point, then customize it to your needs.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              
              // SafeWalk template (previously Safety Meet)
              _buildTemplateCard(
                context,
                title: 'SafeWalk',
                description: 'SPU Students Only: Campus security escorted walks with emergency features',
                icon: Icons.security,
                color: Colors.red,
                onTap: () => _navigateToCreateMeet(context, 'SafeWalk'),
                isPriority: true,
              ),
              
              // Academic Meet template
              _buildTemplateCard(
                context,
                title: 'Academic Meet',
                description: 'For study groups, research discussions, tutoring sessions, or academic networking',
                icon: Icons.school,
                color: Colors.blue,
                onTap: () => _navigateToCreateMeet(context, 'Academic'),
              ),
              
              // Social Meet template
              _buildTemplateCard(
                context,
                title: 'Social Meet',
                description: 'For coffee chats, casual hangouts, networking, or making new friends',
                icon: Icons.people,
                color: Colors.purple,
                onTap: () => _navigateToCreateMeet(context, 'Social'),
              ),
              
              // Food & Drinks template
              _buildTemplateCard(
                context,
                title: 'Food & Drinks',
                description: 'For dining out, potlucks, exploring restaurants, or any food-centered gathering',
                icon: Icons.restaurant,
                color: Colors.orange,
                onTap: () => _navigateToCreateMeet(context, 'Food'),
              ),
              
              // Wellness & Activity template
              _buildTemplateCard(
                context,
                title: 'Wellness & Activity',
                description: 'For sports, hiking, fitness, meditation, or any physical or wellness activity',
                icon: Icons.fitness_center,
                color: Colors.green,
                onTap: () => _navigateToCreateMeet(context, 'Wellness'),
              ),
              
              // Event template
              _buildTemplateCard(
                context,
                title: 'Event',
                description: 'For concerts, games, performances, parties, or any special occasion',
                icon: Icons.event,
                color: Colors.amber,
                onTap: () => _navigateToCreateMeet(context, 'Event'),
              ),
              
              // Custom meet template
              _buildTemplateCard(
                context,
                title: 'Custom Meet',
                description: 'Start from scratch and create a completely custom meet for any purpose',
                icon: Icons.add_circle_outline,
                color: Colors.teal,
                onTap: () => _navigateToCreateMeet(context, 'Custom'),
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Tips for a Successful Meet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildTipItem(
                icon: Icons.description,
                text: 'Provide a clear description of your meet\'s purpose',
              ),
              _buildTipItem(
                icon: Icons.schedule,
                text: 'Set a specific date, time and duration',
              ),
              _buildTipItem(
                icon: Icons.location_on,
                text: 'Choose a convenient and safe location',
              ),
              _buildTipItem(
                icon: Icons.people,
                text: 'Specify any requirements or what to bring',
              ),
              _buildTipItem(
                icon: Icons.security,
                text: 'For campus safety, use the SafeWalk option (SPU Students only)',
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPriority = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isPriority ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPriority ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isPriority) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color),
                            ),
                            child: const Text(
                              'SAFETY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateMeet(BuildContext context, String meetType) {
    // Special case for SafeWalk
    if (meetType == 'SafeWalk') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('SPU SafeWalk Service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SPU STUDENTS ONLY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              const Text('SafeWalk service includes:'),
              const SizedBox(height: 8),
              const Text('• Campus security notification of your route'),
              const Text('• Emergency alert by pressing power button 5 times'),
              const Text('• Real-time location monitoring by security'),
              const Text('• Priority response to any incidents'),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Student ID verification required',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to create form for further customization
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateMeetPage(meetType: meetType),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue to SafeWalk'),
            ),
          ],
        ),
      );
      return;
    }
    // For all other meet types, navigate to CreateMeetPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMeetPage(meetType: meetType),
      ),
    );
  }
}
