import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mock user data - in a real app, this would come from your API
  final Map<String, dynamic> _userData = {
    'firstName': 'John',
    'surName': 'Doe',
    'email': 'john.doe@example.com',
    'phone': '+1 234 567 8900',
    'photoUrl': '',
    'address': '123 Main St, Cityville',
    'userType': 'Vehicle Owner',
    'joinedDate': 'Joined Jan 2023',
  };

  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _surNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: _userData['firstName']);
    _surNameController = TextEditingController(text: _userData['surName']);
    _emailController = TextEditingController(text: _userData['email']);
    _phoneController = TextEditingController(text: _userData['phone']);
    _addressController = TextEditingController(text: _userData['address']);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: const Color(0xFF1A3D63).withOpacity(0.1),
          backgroundImage: _userData['photoUrl'] != null && _userData['photoUrl'].isNotEmpty
              ? NetworkImage(_userData['photoUrl'])
              : const AssetImage('assets/images/icon.png') as ImageProvider,
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A3D63),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: () {
                  // Handle image change
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1A3D63)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
  Widget _buildEditableField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF1A3D63)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1A3D63), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3D63),
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: _buildProfileImage(),
            ),
            const SizedBox(height: 16),
            Text(
              _isEditing ? 'Edit Profile' : _userData['userType'],
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF1A3D63).withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            if (!_isEditing) ...[
              _buildInfoCard('Full Name', '${_userData['firstName']} ${_userData['surName']}', Icons.person),
              _buildInfoCard('Email', _userData['email'], Icons.email),
              _buildInfoCard('Phone', _userData['phone'], Icons.phone),
              _buildInfoCard('Address', _userData['address'], Icons.location_on),
              _buildInfoCard('Member Since', _userData['joinedDate'], Icons.calendar_today),
            ] else
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildEditableField('First Name', _firstNameController),
                    _buildEditableField('Last Name', _surNameController),
                    _buildEditableField('Email', _emailController, keyboardType: TextInputType.emailAddress),
                    _buildEditableField('Phone', _phoneController, keyboardType: TextInputType.phone),
                    _buildEditableField('Address', _addressController),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3D63),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Save changes
                            setState(() {
                              _isEditing = false;
                              // In a real app, you would update the user data via API here
                              _userData['firstName'] = _firstNameController.text;
                              _userData['surName'] = _surNameController.text;
                              _userData['email'] = _emailController.text;
                              _userData['phone'] = _phoneController.text;
                              _userData['address'] = _addressController.text;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
}