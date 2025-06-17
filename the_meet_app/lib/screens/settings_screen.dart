import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_meet_app/providers/auth_provider.dart';
import 'package:the_meet_app/providers/theme_provider.dart';
import 'package:the_meet_app/screens/safe_module_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification settings - assuming default values for now
  bool _pushEnabled = true;
  bool _meetRemindersEnabled = true;
  bool _newMeetAlertsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 1,
      ),
      body: ListView(
        children: <Widget>[
          _buildSectionTitle(context, 'Appearance'),
          ListTile(
            leading: Icon(Icons.palette_outlined, color: themeProvider.theme.iconTheme.color),
            title: const Text('Theme'),
            subtitle: Text(themeProvider.currentTheme.toString().split('.').last),
            onTap: () => _showThemeSelectionDialog(context, themeProvider),
          ),
          const Divider(),
          _buildSectionTitle(context, 'Notifications'),
          SwitchListTile(
            secondary: Icon(Icons.notifications_active_outlined, color: themeProvider.theme.iconTheme.color),
            title: const Text('Push Notifications'),
            value: _pushEnabled,
            onChanged: (bool value) {
              setState(() {
                _pushEnabled = value;
                // TODO: Implement logic to save this preference
              });
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.event_available_outlined, color: themeProvider.theme.iconTheme.color),
            title: const Text('Meet Reminders'),
            value: _meetRemindersEnabled,
            onChanged: (bool value) {
              setState(() {
                _meetRemindersEnabled = value;
                // TODO: Implement logic to save this preference
              });
            },
          ),          SwitchListTile(
            secondary: Icon(Icons.new_releases_outlined, color: themeProvider.theme.iconTheme.color),
            title: const Text('New Meet Alerts'),
            value: _newMeetAlertsEnabled,
            onChanged: (bool value) {
              setState(() {
                _newMeetAlertsEnabled = value;
                // TODO: Implement logic to save this preference
              });
            },          ),
          const Divider(),
          _buildSectionTitle(context, 'Safety'),
          ListTile(
            leading: Icon(Icons.shield_outlined, color: themeProvider.theme.iconTheme.color),
            title: const Text('Safe Module'),
            subtitle: const Text('Manage safety features'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SafeModuleScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionTitle(context, 'Account'),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            title: const Text('Sign Out'),
            onTap: () => _showSignOutConfirmation(context, authProvider),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
            title: const Text('Delete Account'),
            onTap: () => _showDeleteAccountConfirmation(context, authProvider),
          ),
          const Divider(),
          _buildSectionTitle(context, 'Help & Support'),
          ListTile(
            leading: Icon(Icons.help_outline, color: themeProvider.theme.iconTheme.color),
            title: const Text('Help Center'),
            onTap: () => _showHelpSupportDialog(context, 'Help Center', 'FAQs and support articles.'),
          ),
          ListTile(
            leading: Icon(Icons.feedback_outlined, color: themeProvider.theme.iconTheme.color),
            title: const Text('Send Feedback'),
            onTap: () => _showHelpSupportDialog(context, 'Send Feedback', 'Report an issue or suggest a feature.'),
          ),          ListTile(
            leading: Icon(Icons.info_outline, color: themeProvider.theme.iconTheme.color),
            title: const Text('About'),
            onTap: () => _showHelpSupportDialog(context, 'About The Meet App', 'Version 1.0.0\n© 2024 The Meet App Devs'),
          ),
          const SizedBox(height: 20),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                '© Copyright Echoless',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _showThemeSelectionDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: SizedBox( 
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: ThemeType.values.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                childAspectRatio: 0.9, // Adjusted for a more card-like appearance
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (BuildContext context, int index) {
                final theme = ThemeType.values[index];
                return _buildCreativeThemeCard(dialogContext, theme, themeProvider);
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCreativeThemeCard(BuildContext context, ThemeType themeType, ThemeProvider themeProvider) {
    final isSelected = themeProvider.currentTheme == themeType;
    final themeData = themeProvider.getThemeDataByType(themeType);
    final String themeName = themeProvider.getThemeName(themeType);

    return InkWell(
      onTap: () {
        themeProvider.setTheme(themeType);
        Navigator.of(context).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme changed to $themeName'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12), // Match container's border radius
      child: Container(
        decoration: BoxDecoration(
          color: themeData.cardColor, // Use cardColor for the base of the mini-preview
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? themeData.colorScheme.primary : themeData.dividerColor.withOpacity(0.5),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeData.colorScheme.primary.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: ClipRRect( // Clip the contents to the rounded border
          borderRadius: BorderRadius.circular(11), // Slightly less than container to avoid border clipping issues
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mini AppBar representation
              Container(
                height: 30,
                color: themeData.colorScheme.primary,
                child: Center(
                  child: Text(
                    themeName.split(' ').first, // Show first word of theme name on app bar
                    style: TextStyle(
                      color: themeData.colorScheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Mini Body representation
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: themeData.scaffoldBackgroundColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Example content representation
                      Container(
                        height: 15,
                        width: 50,
                        decoration: BoxDecoration(
                          color: themeData.colorScheme.secondary.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 5),
                       Container(
                        height: 8,
                        width: 40,
                        decoration: BoxDecoration(
                          color: themeData.textTheme.bodyLarge?.color?.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Theme Name and Selection Indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: themeData.cardColor, // Match base card color
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSelected)
                      Icon(Icons.check_circle, color: themeData.colorScheme.primary, size: 14),
                    if (isSelected)
                      const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        themeName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: themeData.textTheme.bodySmall?.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );  }

  void _showSignOutConfirmation(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog
                await authProvider.signOut();
                // Ensure proper navigation after sign out, e.g., to login screen
                // This might involve checking mounted status if async operations are involved before navigation
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context, AuthProvider authProvider) {
    final TextEditingController passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Delete Account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                      'This action is irreversible. All your data will be permanently deleted. Please enter your password to confirm.'),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: isLoading ? null : () async {
                    if (passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password is required to delete account.')),
                      );
                      return;
                    }
                    setDialogState(() => isLoading = true);
                    try {
                      bool success = await authProvider.deleteUserAccount(passwordController.text); // Corrected method name
                      setDialogState(() => isLoading = false);

                      if (success) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Account deleted successfully.')),
                        );
                        // Ensure proper navigation after account deletion
                        if (mounted) {
                           Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to delete account. Check password or try again later.')),
                        );
                      }
                    } catch (e) {
                       setDialogState(() => isLoading = false);
                       ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}')),
                       );
                    }
                  },
                  child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)) : const Text('Delete'),
                ),
              ],
            );
          }
        );
      },
    ).then((_) => passwordController.dispose());
  }

  void _showHelpSupportDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}