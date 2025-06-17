import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_meet_app/providers/theme_provider.dart';

/// A consistent app bar used across the app for secondary screens
/// Implements the same styling as the main navigation bar app bar
class ConsistentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ConsistentAppBar({
    super.key,
    this.title = '',  // Default to empty, the app name will be shown
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Use provided colors or defaults from theme
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
    final fgColor = foregroundColor ?? Theme.of(context).colorScheme.onSurface;

    return AppBar(
      title: Row(
        children: [
          // App name with flexible sizing
          Flexible(
            child: Text(
              'The MeetApp',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: fgColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Only show title if provided
          if (title.isNotEmpty)
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: fgColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: fgColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      centerTitle: false,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton 
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: fgColor),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            ) 
          : null,
      actions: actions,
      toolbarHeight: 48, // Smaller height for the header
      elevation: 0,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      flexibleSpace: backgroundColor == null ? Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.85),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ) : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}