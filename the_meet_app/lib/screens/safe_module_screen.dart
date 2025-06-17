import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/safe_button_provider.dart';
import '../models/safe_button.dart';

class SafeModuleScreen extends StatefulWidget {
  const SafeModuleScreen({super.key});

  @override
  State<SafeModuleScreen> createState() => _SafeModuleScreenState();
}

class _SafeModuleScreenState extends State<SafeModuleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _buttonNameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buttonNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Module'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Setup', icon: Icon(Icons.add)),
            Tab(text: 'Manage', icon: Icon(Icons.list)),
            Tab(text: 'Test', icon: Icon(Icons.touch_app)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSetupTab(),
                _buildManageTab(),
                _buildTestTab(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              '© Copyright Echoless',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Setup tab - for registering new buttons
  Widget _buildSetupTab() {
    return Consumer<SafeButtonProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Register Safe Buttons',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Safe buttons allow you to quickly trigger emergency actions during your walks. '
                'Register volume buttons to use them without looking at your screen.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              
              // Button count indicator
              Text(
                'Registered buttons: ${provider.safeButtons.length}/2',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: provider.safeButtons.length >= 2 
                    ? Colors.red 
                    : Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              
              // Button name input
              TextField(
                controller: _buttonNameController,
                decoration: const InputDecoration(
                  labelText: 'Button Name',
                  hintText: 'e.g., "Emergency Call", "Send Alert"',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Recording status and timer
              if (provider.isRecordingButton)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Press any volume button...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time remaining: ${provider.remainingTime} seconds',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => provider.cancelRecording(),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
              // Detected button info
              if (!provider.isRecordingButton && provider.lastButtonPressed != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Button Detected!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Action: ${provider.lastButtonPressed}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _buttonNameController.text.isNotEmpty && provider.safeButtons.length < 2
                                ? () {
                                    provider.addSafeButton(
                                      _buttonNameController.text.trim(),
                                      provider.lastButtonPressed!,
                                      'volume',
                                    );
                                    _buttonNameController.clear();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Safe button added successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Button'),
                          ),
                          TextButton.icon(
                            onPressed: () => provider.startRecordingButton(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
              const Spacer(),
                // Start recording button
              if (!provider.isRecordingButton && provider.safeButtons.length < 2)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => provider.startRecordingButton(),
                        icon: const Icon(Icons.touch_app),
                        label: const Text('Start Button Detection', style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: provider.isListening ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            provider.isListening ? "Listening for button presses" : "Not listening",
                            style: TextStyle(
                              fontSize: 12,
                              color: provider.isListening ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                // Max buttons reached message
              if (!provider.isRecordingButton && provider.safeButtons.length >= 2)
                const Center(
                  child: Text(
                    'Maximum of 2 buttons reached.\nRemove a button to add a new one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
              
              // Debug info section - helpful during development
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ExpansionTile(
                  title: const Text('Debug Info'),
                  initiallyExpanded: false,
                  children: [
                    ListTile(
                      title: const Text('Listening Status'),
                      subtitle: Text(provider.isListening ? 'Active' : 'Inactive'),
                      trailing: Switch(
                        value: provider.isListening,
                        onChanged: (value) {
                          if (value) {
                            provider.startListening();
                          } else {
                            provider.stopListening();
                          }
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Recording Status'),
                      subtitle: Text(provider.isRecordingButton ? 'Recording' : 'Not Recording'),
                    ),
                    ListTile(
                      title: const Text('Last Button Pressed'),
                      subtitle: Text(provider.lastButtonPressed ?? 'None'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Refreshed listening state'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          // Force a refresh of the listening state
                          if (provider.isListening) {
                            provider.stopListening().then((_) {
                              provider.startListening();
                            });
                          }
                        },
                        child: const Text('Refresh Listener'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Manage tab - for managing existing buttons
  Widget _buildManageTab() {
    return Consumer<SafeButtonProvider>(
      builder: (context, provider, child) {
        if (provider.safeButtons.isEmpty) {
          return const Center(
            child: Text(
              'No safe buttons registered yet.\nGo to Setup tab to add buttons.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.safeButtons.length,
          itemBuilder: (context, index) {
            final button = provider.safeButtons[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            button.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showDeleteConfirmation(context, provider, button),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Button Type'),
                      subtitle: Text(button.type),
                      leading: const Icon(Icons.category),
                    ),
                    ListTile(
                      title: const Text('Action'),
                      subtitle: Text(button.action),
                      leading: const Icon(Icons.touch_app),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getButtonDescription(button),
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Test tab - for testing registered buttons
  Widget _buildTestTab() {
    return Consumer<SafeButtonProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Test Your Safe Buttons',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Press your registered buttons to verify they are working correctly. '
                'You should see feedback below when a button is detected.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              
              // Button testing status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: provider.isListening ? Colors.blue.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      provider.isListening 
                          ? 'Listening for button presses...' 
                          : 'Press Start to begin testing',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: provider.isListening ? Colors.blue.shade800 : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    provider.isListening
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Last detected button
              if (provider.isListening && provider.lastDetectedButton != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Button Detected!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Name: ${provider.lastDetectedButton!.name}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Action: ${provider.lastDetectedButton!.action}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Type: ${provider.lastDetectedButton!.type}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              
              // Display when button pressed but not registered
              if (provider.isListening && provider.lastButtonPressed != null && provider.lastDetectedButton == null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Button Detected but Not Registered',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Action: ${provider.lastButtonPressed}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Text(
                        'Type: volume',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This button is not registered as a safe button.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const Spacer(),
              
              // Start/Stop testing button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (provider.isListening) {
                      provider.stopListening();
                    } else {
                      provider.startListening();
                    }
                  },
                  icon: Icon(provider.isListening ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    provider.isListening ? 'Stop Testing' : 'Start Testing',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.isListening ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, SafeButtonProvider provider, SafeButton button) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Safe Button?'),
        content: Text('Are you sure you want to delete the "${button.name}" button?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.removeSafeButton(button.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Safe button removed successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  String _getButtonDescription(SafeButton button) {
    if (button.action == 'volume_up') {
      return 'Triggered by pressing the Volume Up button';
    } else if (button.action == 'volume_down') {
      return 'Triggered by pressing the Volume Down button';
    } else {
      return 'Triggered by custom action: ${button.action}';
    }
  }
}