import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic> _userData = {};
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage;

  late TextEditingController _firstNameController;
  late TextEditingController _surNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String _selectedGender = 'Male';
  int _signupType = 0;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _surNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _apiService.getUserData();
      if (response['success'] == true && response['user'] != null) {
        setState(() {
          _userData = response['user'];
          _signupType = _userData['signupType'] ?? 0;

          _firstNameController.text = _userData['firstName'] ?? '';
          _surNameController.text = _userData['surName'] ?? '';
          _emailController.text = _userData['email'] ?? '';
          _phoneController.text = _userData['phoneNum'] ?? '';
          _selectedGender = _userData['gender'] == 0 ? 'Male' : 'Female';

          _isLoading = false;
        });
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Failed to load user data');
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading profile: ${e.toString()}');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _showImageSourceDialog() async {
    if (!_isEditing) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Change Profile Picture',
          style: TextStyle(
            color: Color(0xFF1A3D63),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF1A3D63)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF1A3D63)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_selectedImage == null) return;

    try {
      final response = await _apiService.uploadProfilePicture(_selectedImage!);
      if (response['success'] == true) {
        await _loadUserData(); // Refresh user data
        Fluttertoast.showToast(msg: 'Profile picture updated successfully');
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Failed to update profile picture');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error uploading profile picture: ${e.toString()}');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    bool hasChanges =
        _firstNameController.text != _userData['firstName'] ||
            _surNameController.text != _userData['surName'] ||
            _phoneController.text != _userData['phoneNum'] ||
            (_selectedGender == 'Male' ? 0 : 1) != _userData['gender'] ||
            (_signupType == 0 && _emailController.text != _userData['email']);

    if (!hasChanges && _selectedImage == null) {
      setState(() => _isEditing = false);
      Fluttertoast.showToast(msg: 'No changes to save');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Upload image first if selected
      if (_selectedImage != null) {
        await _uploadProfilePicture();
      }

      // Then update profile if there are changes
      if (hasChanges) {
        final response = await _apiService.updateProfile(
          firstName: _firstNameController.text,
          surName: _surNameController.text,
          email: _signupType == 0 ? _emailController.text : _userData['email'],
          phoneNum: _phoneController.text,
          gender: _selectedGender == 'Male' ? 0 : 1,
        );

        if (response['success'] == true) {
          await _loadUserData(); // Refresh user data
          Fluttertoast.showToast(msg: 'Profile updated successfully');
        } else {
          Fluttertoast.showToast(msg: response['message'] ?? 'Failed to update profile');
        }
      }

      setState(() => _isEditing = false);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error updating profile: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _selectedImage = null;
        });
      }
    }
  }

  Widget _buildProfileImage() {
    final imageUrl = _userData['photoUrl'] != null && _userData['photoUrl'].isNotEmpty
        ? _userData['photoUrl']!.contains('http')
        ? _userData['photoUrl']
        : '${ApiService.apiUrl}V4/Others/Kurt/CareAPI/profilePicture/${_userData['photoUrl']}'
        : null;

    return GestureDetector(
      onTap: _isEditing ? _showImageSourceDialog : null,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : imageUrl != null
                ? NetworkImage(imageUrl)
                : const AssetImage('assets/images/icon.png') as ImageProvider,
            child: _isLoading
                ? const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
                : null,
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3D63),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDisplayTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A3D63)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'Not set',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildEditableField(String label, TextEditingController controller,
      {bool enabled = true, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A3D63), width: 2),
          ),
        ),
        validator: validator ?? (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        items: ['Male', 'Female']
            .map((gender) => DropdownMenuItem(
          value: gender,
          child: Text(gender),
        ))
            .toList(),
        decoration: InputDecoration(
          labelText: 'Gender',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A3D63), width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _selectedGender = value!;
          });
        },
      ),
    );
  }

  String _formatJoinedDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Member since unknown';

    try {
      final date = DateTime.parse(dateString);
      return 'Joined ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return 'Member since $dateString';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6FAFD),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A3D63),
          elevation: 0,
          title: const Text('My Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3D63),
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          !_isEditing
              ? IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => setState(() => _isEditing = true),
          )
              : TextButton(
            onPressed: () => setState(() => _isEditing = false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildProfileImage(),
            const SizedBox(height: 16),
            Text(
              _isEditing ? 'Edit Profile' : _userData['userType'] == 0 ? 'Driver' : 'Shop Owner',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF1A3D63).withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            if (!_isEditing) ...[
              _buildDisplayTile(
                'Full Name',
                '${_userData['firstName']} ${_userData['surName']}',
                Icons.person,
              ),
              _buildDisplayTile('Email', _userData['email'] ?? '', Icons.email),
              _buildDisplayTile('Phone', _userData['phoneNum'] ?? '', Icons.phone),
              _buildDisplayTile(
                'Gender',
                _userData['gender'] == 0 ? 'Male' : 'Female',
                Icons.person,
              ),
              _buildDisplayTile(
                'Member Since',
                _formatJoinedDate(_userData['createdAt']),
                Icons.calendar_today,
              ),
            ] else
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildEditableField('First Name', _firstNameController),
                    _buildEditableField('Last Name', _surNameController),
                    _buildEditableField(
                      'Email',
                      _emailController,
                      enabled: _signupType == 0,
                      keyboardType: TextInputType.emailAddress,
                      validator: _signupType == 0 ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      } : null,
                    ),
                    _buildEditableField(
                      'Phone',
                      _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildGenderDropdown(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3D63),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'SAVE CHANGES',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _apiService.dispose();
    super.dispose();
  }
}