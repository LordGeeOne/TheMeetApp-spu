import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:the_meet_app/models/meet.dart';
import 'package:the_meet_app/providers/theme_provider.dart';

class MeetCard extends StatelessWidget {
  final Meet meet;
  final VoidCallback? onTap;

  const MeetCard({
    super.key,
    required this.meet,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
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

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: themeProvider.cardBorderColor,
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type icon
            Container(
              padding: const EdgeInsets.all(8),
              color: typeColor.withOpacity(0.2),
              child: Row(
                children: [
                  Icon(typeIcon, color: typeColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    meet.type,
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('h:mm a').format(meet.time),
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    meet.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: themeProvider.iconColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          meet.location,
                          style: TextStyle(fontSize: 12, color: themeProvider.secondaryTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Participants
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: themeProvider.iconColor),
                      const SizedBox(width: 4),
                      Text(
                        '${meet.participantIds.length}/${meet.maxParticipants}',
                        style: TextStyle(
                          fontSize: 12, 
                          color: meet.participantIds.length >= meet.maxParticipants
                              ? Colors.red
                              : themeProvider.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: themeProvider.iconColor),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('h:mm a').format(meet.time),
                            style: TextStyle(
                              fontSize: 12,
                              color: themeProvider.secondaryTextColor,
                            ),
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
    );
  }
}