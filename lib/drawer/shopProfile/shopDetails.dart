import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ShopDetailsScreen extends StatefulWidget {
  const ShopDetailsScreen({Key? key}) : super(key: key);

  @override
  _ShopDetailsScreenState createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  File? _businessPermitFile;
  File? _governmentIdFile;
  bool _isEditing = false;

  final TextEditingController _shopNameController = TextEditingController(text: 'AutoCare Masters');
  final TextEditingController _locationController = TextEditingController(text: '123 Main Street, City Center');
  final TextEditingController _facebookController = TextEditingController(text: 'https://facebook.com/autocare');

  List<String> expertiseOptions = ['Car', 'Motorcycle', 'Van', 'Truck', 'Bus', 'Jeep'];
  List<String> selectedExpertise = ['Car', 'Motorcycle'];

  List<String> serviceOptions = [
    'Oil Change', 'Tire Repair & Vulcanizing', 'Brake Service', 'Engine Tune-Up & Repair',
    'Transmission Repair', 'Battery Check & Replacement', 'Aircon Cleaning & Repair',
    'Wheel Alignment & Balancing', 'Suspension Check & Repair', 'Exhaust System Repair',
    'Computerized Diagnostic Test', 'Electrical Wiring & Repair', 'Car Wash',
    'Interior & Exterior Detailing', 'Auto Paint & Repainting', 'Body Repair & Fender Bender',
    'Glass & Windshield Replacement', 'Rustproofing & Undercoating', 'Towing Service',
    '24/7 Roadside Assistance', 'Underwash', 'Headlight & Taillight Replacement',
    'Radiator Flush & Repair', 'Change Oil & Filter', 'Fuel System Cleaning',
    'Brake Pad Replacement', 'Muffler Repair', 'Clutch Repair', 'Car Tint Installation',
    'Dash Cam Installation'
  ];
  List<String> selectedServices = ['Oil Change', 'Brake Service', 'Car Wash'];

  TimeOfDay openingTime = TimeOfDay(hour: 8, minute: 0);
  TimeOfDay closingTime = TimeOfDay(hour: 17, minute: 0);

  List<String> daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  Map<String, bool> selectedDays = {
    'Monday': true, 'Tuesday': true, 'Wednesday': true,
    'Thursday': true, 'Friday': true, 'Saturday': false, 'Sunday': false
  };

  Future<void> _pickImage(String type, ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          if (type == 'profile') {
            _profileImage = File(pickedFile.path);
          } else if (type == 'business') {
            _businessPermitFile = File(pickedFile.path);
          } else {
            _governmentIdFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<void> _showImageSourceDialog(String type) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Options'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(type, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(type, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.file(imageFile, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview(File? file, String label) {
    if (file == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => _showFullScreenImage(file),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Uploaded $label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A3D63),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(file, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview(File? file, String label, String type) {
    // Show placeholder image when not editing and no file uploaded
    if (!_isEditing && file == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A3D63),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/placeholder.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      );
    }

    // Show uploaded file if exists
    if (file != null) {
      return GestureDetector(
        onTap: () => _showFullScreenImage(file),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Uploaded $label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A3D63),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(file, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  BoxDecoration _fieldShadowBox() {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
      borderRadius: BorderRadius.circular(12),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? openingTime : closingTime,
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          openingTime = picked;
        } else {
          closingTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return MaterialLocalizations.of(context).formatTimeOfDay(tod);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF1A3D63),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Shop Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
                      onPressed: () => setState(() => _isEditing = !_isEditing),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _isEditing ? () => _showImageSourceDialog('profile') : null,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : const AssetImage('assets/images/placeholder.png') as ImageProvider,
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
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Shop Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: _fieldShadowBox(),
                      child: TextFormField(
                        controller: _shopNameController,
                        enabled: _isEditing,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration('Enter your shop name'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: _fieldShadowBox(),
                      child: TextFormField(
                        controller: _locationController,
                        enabled: _isEditing,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration('Enter shop location'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Expertise',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Types of vehicles your shop services',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: expertiseOptions.map((expertise) {
                        bool isSelected = selectedExpertise.contains(expertise);
                        return ChoiceChip(
                          label: Text(expertise),
                          selected: isSelected,
                          onSelected: _isEditing ? (_) {
                            setState(() {
                              if (isSelected) {
                                selectedExpertise.remove(expertise);
                              } else {
                                selectedExpertise.add(expertise);
                              }
                            });
                          } : null,
                          selectedColor: const Color(0xFF1A3D63),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF1A3D63),
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF1A3D63)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Contact Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Home Page',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: _fieldShadowBox(),
                      child: TextFormField(
                        controller: _facebookController,
                        enabled: _isEditing,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration('Enter home page link'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Service Offered',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Services your shop offers',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: serviceOptions.map((service) {
                        bool isSelected = selectedServices.contains(service);
                        return ChoiceChip(
                          label: Text(service),
                          selected: isSelected,
                          onSelected: _isEditing ? (_) {
                            setState(() {
                              if (isSelected) {
                                selectedServices.remove(service);
                              } else {
                                selectedServices.add(service);
                              }
                            });
                          } : null,
                          selectedColor: const Color(0xFF1A3D63),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF1A3D63),
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF1A3D63)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Service Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Shop opening and closing hours',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _isEditing ? () => _selectTime(context, true) : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _formatTimeOfDay(openingTime),
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isEditing ? () => _selectTime(context, false) : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _formatTimeOfDay(closingTime),
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Open Days',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Days these hours apply to',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: daysOfWeek.map((day) {
                        bool isSelected = selectedDays[day]!;
                        return ChoiceChip(
                          label: Text(day),
                          selected: isSelected,
                          onSelected: _isEditing ? (_) {
                            setState(() {
                              selectedDays[day] = !isSelected;
                            });
                          } : null,
                          selectedColor: const Color(0xFF1A3D63),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF1A3D63),
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF1A3D63)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Business Documents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Business Permit Section
                    const Text(
                      'Business Permit/Barangay Clearance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A3D63),
                      ),
                    ),

                    // Show upload field only when editing
                    if (_isEditing) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showImageSourceDialog('business'),
                        child: Container(
                          decoration: _fieldShadowBox(),
                          child: TextFormField(
                            enabled: false,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Business Permit',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.cloud_upload, color: Color(0xFF1A3D63)),
                              suffixIcon: _businessPermitFile != null
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Show document preview (either uploaded file or placeholder)
                    _buildDocumentPreview(_businessPermitFile, 'Business Permit', 'business'),

                    const SizedBox(height: 16),

                    // Valid Government ID Section
                    const Text(
                      'Valid Government ID',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A3D63),
                      ),
                    ),

                    // Show upload field only when editing
                    if (_isEditing) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showImageSourceDialog('government'),
                        child: Container(
                          decoration: _fieldShadowBox(),
                          child: TextFormField(
                            enabled: false,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Government ID',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.cloud_upload, color: Color(0xFF1A3D63)),
                              suffixIcon: _governmentIdFile != null
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Show document preview (either uploaded file or placeholder)
                    _buildDocumentPreview(_governmentIdFile, 'Government ID', 'government'),

                    const SizedBox(height: 40),
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => setState(() => _isEditing = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A3D63),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}