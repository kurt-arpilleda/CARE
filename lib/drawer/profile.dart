import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:care/api_service.dart';
import 'package:care/anim/dotLoading.dart';

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
  bool _hasInternet = true;
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
    _checkInternetAndLoadData();
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

  Future<void> _checkInternetAndLoadData() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _hasInternet = connectivityResult != ConnectivityResult.none;
    });

    if (_hasInternet) {
      _loadUserData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _hasInternet ? Icons.person_outline : Icons.wifi_off,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            _hasInternet ? 'No profile data found' : 'No Internet Connection',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A3D63),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _hasInternet
                ? 'Unable to load your profile information'
                : 'Please check your internet connection and try again',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (!_hasInternet)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3D63),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _checkInternetAndLoadData,
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
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
        setState(() => _isLoading = false);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading profile: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showImageSourceDialog() async {
    if (!_isEditing) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Profile Picture', style: TextStyle(color: Color(0xFF1A3D63), fontWeight: FontWeight.bold)),
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
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (_selectedImage != null) {
        final uploadResponse = await _apiService.uploadProfilePicture(_selectedImage!);
        if (uploadResponse['success'] != true) {
          throw Exception(uploadResponse['message'] ?? 'Failed to upload image');
        }
      }

      final response = await _apiService.updateProfile(
        firstName: _firstNameController.text,
        surName: _surNameController.text,
        email: _signupType == 0 ? _emailController.text : _userData['email'],
        phoneNum: _phoneController.text,
        gender: _selectedGender == 'Male' ? 0 : 1,
      );

      if (response['success'] == true) {
        await _loadUserData();
        Fluttertoast.showToast(msg: 'Profile updated successfully');
        setState(() => _isEditing = false);
      } else {
        throw Exception(response['message'] ?? 'Failed to update profile');
      }
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
        : '${ApiService.apiUrl}profilePicture/${_userData['photoUrl']}'
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
                : const AssetImage('assets/images/profilePlaceHolder.png') as ImageProvider,
            child: _isLoading
                ? const SizedBox()
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
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A3D63)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value.isNotEmpty ? value : 'Not set', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isValidName(String name) {
    final validCharacters = RegExp(r"^[a-zA-Z .,'-]+$");
    return validCharacters.hasMatch(name);
  }

  String? _nameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (!_isValidName(value)) {
      return 'Only letters, spaces, and .,-\' are allowed';
    }
    return null;
  }

  Widget _buildEditableField(String label, TextEditingController controller, {bool enabled = true, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A3D63), width: 2)),
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
        items: ['Male', 'Female'].map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
        decoration: InputDecoration(
          labelText: 'Gender',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A3D63), width: 2)),
        ),
        onChanged: (value) => setState(() => _selectedGender = value!),
      ),
    );
  }

  String _getDayWithSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
    switch (day % 10) {
      case 1: return '${day}st';
      case 2: return '${day}nd';
      case 3: return '${day}rd';
      default: return '${day}th';
    }
  }

  String _formatJoinedDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Member since unknown';
    try {
      final date = DateTime.parse(dateString);
      return 'Joined ${_getDayWithSuffix(date.day)} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return 'Member since $dateString';
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _getSignInMethodText() {
    switch (_signupType) {
      case 0:
        return 'Email';
      case 1:
        return 'Google';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6FAFD),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A3D63),
          elevation: 0,
          title: const Text('My Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        ),
        body: const DotLoading(),
      );
    }

    if (!_hasInternet || _userData.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6FAFD),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A3D63),
          elevation: 0,
          title: const Text('My Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        ),
        body: _buildNoDataView(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3D63),
        elevation: 0,
        title: const Text('My Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          !_isEditing
              ? IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => setState(() => _isEditing = true))
              : TextButton(onPressed: () => setState(() => _isEditing = false), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildProfileImage(),
            const SizedBox(height: 16),
            const SizedBox(height: 24),
            if (!_isEditing) ...[
              _buildDisplayTile('Full Name', '${_userData['firstName']} ${_userData['surName']}', Icons.person),
              _buildDisplayTile('Email', _userData['email'] ?? '', Icons.email),
              _buildDisplayTile(
                'Gender',
                _userData['gender'] == 0 ? 'Male' : 'Female',
                _userData['gender'] == 0 ? Icons.male : Icons.female,
              ),
              _buildDisplayTile('Phone', _userData['phoneNum'] ?? '', Icons.phone),
              _buildDisplayTile('Sign-in Method', _getSignInMethodText(), Icons.login),
              _buildDisplayTile('Member Since', _formatJoinedDate(_userData['createdAt']), Icons.calendar_today),
            ] else
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildEditableField('First Name', _firstNameController, validator: _nameValidator),
                    _buildEditableField('Last Name', _surNameController, validator: _nameValidator),
                    if (_signupType == 0)
                      _buildEditableField(
                        'Email',
                        _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Email is required';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    _buildGenderDropdown(),
                    _buildEditableField('Phone', _phoneController, keyboardType: TextInputType.phone),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3D63),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const DotLoading(dotColor: Colors.white, dotSize: 10)
                            : const Text('SAVE CHANGES', style: TextStyle(fontSize: 16, color: Colors.white)),
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
}