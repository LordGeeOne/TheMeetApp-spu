import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_meet_app/providers/auth_provider.dart';
import 'package:the_meet_app/models/user_model.dart';
import 'package:the_meet_app/screens/verification_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String name;
  final String userType; // 'spu', 'gmail', 'other'

  const ProfileSetupScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.name,
    required this.userType,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _customInterestController = TextEditingController();
  
  // Selected interests
  final List<String> _selectedInterests = [];
  bool _isLoading = false;
  
  // Image picker and file for profile picture
  final ImagePicker _picker = ImagePicker();
  File? _profileImageFile;
  String? _profileImageUrl;
  bool _isUploadingImage = false;
  
  // Common interests to choose from
  final List<String> _commonInterests = [
    'Sports', 'Music', 'Arts', 'Technology', 'Science', 
    'Reading', 'Travel', 'Cooking', 'Gaming', 'Photography',
    'Fitness', 'Movies', 'Nature', 'Fashion', 'History'
  ];

  @override
  void dispose() {
    _bioController.dispose();
    _customInterestController.dispose();
    super.dispose();
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  void _addCustomInterest(String interest) {
    if (interest.isNotEmpty && !_selectedInterests.contains(interest)) {
      setState(() {
        _selectedInterests.add(interest);
      });
    }
  }

  // Method to pick an image from gallery
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
    }
  }
  
  // Method to take a photo with camera
  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
    }
  }

  // Show options to change profile picture
  void _showImageSourceOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Upload profile image to Firebase Storage
  Future<String?> _uploadProfileImage() async {
    if (_profileImageFile == null) return null;
    
    setState(() {
      _isUploadingImage = true;
    });
    
    try {
      // Compress image before uploading
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        _profileImageFile!.path,
        minWidth: 500,
        minHeight: 500,
        quality: 80,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      
      File? compressedFile;
      int quality = 80;
      List<int>? result = compressedBytes;
      
      // Further compress if still too large (>100kb)
      while ((result != null && result.length > 100 * 1024) && quality > 10) {
        quality -= 10;
        result = await FlutterImageCompress.compressWithFile(
          _profileImageFile!.path,
          minWidth: 500,
          minHeight: 500,
          quality: quality,
          format: CompressFormat.jpeg,
          keepExif: false,
        );
      }
      
      if (result != null) {
        final tempDir = Directory.systemTemp;
        final tempFile = await File('${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg').create();
        await tempFile.writeAsBytes(result);
        compressedFile = tempFile;
      }
      
      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('user_images/${widget.userId}.jpg');
      
      // Add metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': widget.userId},
      );
      
      // Upload with metadata
      final uploadTask = storageRef.putFile(
        compressedFile ?? _profileImageFile!,
        metadata,
      );
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Profile image upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      }, onError: (error) {
        print('Upload error: $error');
      });
      
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      setState(() {
        _isUploadingImage = false;
        _profileImageUrl = downloadUrl;
      });
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      setState(() {
        _isUploadingImage = false;
      });
      return null;
    }
  }

  Future<void> _submitProfileInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Upload profile image if selected
      String? photoURL;
      if (_profileImageFile != null) {
        photoURL = await _uploadProfileImage();
      }
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Create a UserModel with the form data
      final updatedUser = UserModel(
        uid: widget.userId,
        email: widget.email,
        displayName: widget.name,
        bio: _bioController.text,
        interests: _selectedInterests,
        photoURL: photoURL ?? '',
      );
      
      // Update user profile in Firebase
      final success = await authProvider.updateProfileForNewUser(
        updatedUser: updatedUser,
        userType: widget.userType,
        isVerified: widget.userType == 'spu', // Auto-verify SPU users
      );
      
      if (success && mounted) {
        if (widget.userType == 'spu') {
          // SPU users skip verification and go directly to the home screen
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Non-SPU users need verification
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const VerificationScreen()),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false, // No back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tell us about yourself',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This information helps us personalize your experience',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImageFile != null ? FileImage(_profileImageFile!) : null,
                      child: _profileImageFile == null
                          ? Text(
                              widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt),
                          color: Colors.white,
                          onPressed: _isUploadingImage ? null : _showImageSourceOptions,
                        ),
                      ),
                    ),
                    if (_isUploadingImage)
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Bio
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell others a bit about yourself',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  return null; // Bio is optional
                },
              ),
              const SizedBox(height: 24),
              
              // Interests
              const Text(
                'Interests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select or add your interests to find meets that match your preferences',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              
              // Interests chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonInterests.map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: (_) => _toggleInterest(interest),
                    backgroundColor: Colors.grey[200],
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87,
                    ),
                  );
                }).toList(),
              ),
              
              // Custom interest input
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Add custom interest',
                        hintText: 'Enter your interest',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.add_circle_outline),
                      ),
                      onFieldSubmitted: _addCustomInterest,
                      controller: _customInterestController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_customInterestController.text.isNotEmpty) {
                        _addCustomInterest(_customInterestController.text);
                        _customInterestController.clear();
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              
              // Selected interests
              const SizedBox(height: 16),
              if (_selectedInterests.isNotEmpty) ...[
                const Text(
                  'Selected Interests:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedInterests.map((interest) {
                    return Chip(
                      label: Text(interest),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _toggleInterest(interest),
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Continue button
              ElevatedButton(
                onPressed: (_isLoading || _isUploadingImage) ? null : _submitProfileInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.userType == 'spu' 
                            ? 'COMPLETE SETUP' 
                            : 'CONTINUE TO VERIFICATION',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}