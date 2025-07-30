import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:care/api_service.dart';
import 'package:care/anim/dotLoading.dart';
import 'package:care/options.dart';

class ShopDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> shopData;

  const ShopDetailsScreen({Key? key, required this.shopData}) : super(key: key);

  @override
  _ShopDetailsScreenState createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  File? _shopLogoFile;
  File? _businessPermitFile;
  File? _governmentIdFile;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isSaving = false;

  late TextEditingController _shopNameController;
  late TextEditingController _locationController;
  late TextEditingController _facebookController;

  late Map<String, dynamic> _currentShopData;
  late List<String> selectedExpertise;
  late List<String> selectedServices;
  late TimeOfDay openingTime;
  late TimeOfDay closingTime;
  late Map<String, bool> selectedDays;

  @override
  void initState() {
    super.initState();
    _currentShopData = Map<String, dynamic>.from(widget.shopData);
    _initializeData();
  }

  void _initializeData() {
    _shopNameController = TextEditingController(text: _currentShopData['shop_name'] ?? '');
    _locationController = TextEditingController(text: _currentShopData['location'] ?? '');
    _facebookController = TextEditingController(text: _currentShopData['home_page'] ?? '');

    selectedExpertise = [];
    if (_currentShopData['expertise'] != null) {
      final expertiseIds = (_currentShopData['expertise'] as String).split(',');
      for (var id in expertiseIds) {
        switch (id) {
          case '0': selectedExpertise.add('Car'); break;
          case '1': selectedExpertise.add('Motorcycle'); break;
          case '2': selectedExpertise.add('Van'); break;
          case '3': selectedExpertise.add('Truck'); break;
          case '4': selectedExpertise.add('Bus'); break;
          case '5': selectedExpertise.add('Jeep'); break;
        }
      }
    }

    selectedServices = [];
    if (_currentShopData['services'] != null) {
      selectedServices = (_currentShopData['services'] as String).split(',');
    }

    final startTime = _currentShopData['start_time']?.toString() ?? '08:00:00';
    final closeTime = _currentShopData['close_time']?.toString() ?? '17:00:00';
    openingTime = TimeOfDay(
      hour: int.parse(startTime.split(':')[0]),
      minute: int.parse(startTime.split(':')[1]),
    );
    closingTime = TimeOfDay(
      hour: int.parse(closeTime.split(':')[0]),
      minute: int.parse(closeTime.split(':')[1]),
    );

    selectedDays = {
      'Monday': false,
      'Tuesday': false,
      'Wednesday': false,
      'Thursday': false,
      'Friday': false,
      'Saturday': false,
      'Sunday': false,
    };
    if (_currentShopData['day_index'] != null) {
      final dayIndexes = (_currentShopData['day_index'] as String).split(',');
      for (var index in dayIndexes) {
        final dayIndex = int.tryParse(index);
        if (dayIndex != null && dayIndex >= 0 && dayIndex < daysOfWeek.length) {
          selectedDays[daysOfWeek[dayIndex]] = true;
        }
      }
    }
  }
  void _toggleService(String service) {
    setState(() {
      if (service == 'Select All') {
        if (selectedServices.contains('Select All')) {
          selectedServices.clear();
        } else {
          selectedServices = List.from(serviceOptions);
        }
      } else {
        if (selectedServices.contains(service)) {
          selectedServices.remove(service);
          selectedServices.remove('Select All');
        } else {
          selectedServices.add(service);
          if (selectedServices.length == serviceOptions.length - 1) {
            selectedServices.add('Select All');
          }
        }
      }
    });
  }
  Future<void> _refreshShopData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getShops();
      if (response['success'] == true) {
        final shops = List<Map<String, dynamic>>.from(response['shops'] ?? []);
        final updatedShop = shops.firstWhere(
              (shop) => shop['id'].toString() == _currentShopData['id'].toString(),
          orElse: () => _currentShopData,
        );

        setState(() {
          _currentShopData = Map<String, dynamic>.from(updatedShop);
          _isLoading = false;
        });

        _initializeData();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(String type, ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          if (type == 'shopLogo') {
            _shopLogoFile = File(pickedFile.path);
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

  Widget _buildDocumentPreview(String? imageName, File? file, String label, String type) {
    final String imageUrl;
    if (type == 'business') {
      imageUrl = '${ApiService.apiUrl}businessDocu/$imageName';
    } else if (type == 'government') {
      imageUrl = '${ApiService.apiUrl}validID/$imageName';
    } else {
      imageUrl = '${ApiService.apiUrl}shopLogo/$imageName';
    }

    if (!_isEditing && file == null && (imageName == null || imageName.isEmpty)) {
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
                'assets/images/placeholder.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      );
    }

    if (file != null) {
      return GestureDetector(
        onTap: () => _showFullScreenImage(FileImage(file)),
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

    if (imageName != null && imageName.isNotEmpty) {
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
          GestureDetector(
            onTap: () => _showFullScreenImage(NetworkImage(imageUrl)),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/placeholder.jpg',
                      fit: BoxFit.cover,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showFullScreenImage(ImageProvider imageProvider) {
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
              child: Image(image: imageProvider, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
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
    return MaterialLocalizations.of(context).formatTimeOfDay(tod);
  }

  String _formatTimeForAPI(TimeOfDay tod) {
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}:00';
  }

  String _getExpertiseIds() {
    final expertiseMap = {
      'Car': '0',
      'Motorcycle': '1',
      'Van': '2',
      'Truck': '3',
      'Bus': '4',
      'Jeep': '5'
    };
    return selectedExpertise.map((e) => expertiseMap[e]).join(',');
  }

  String _getDayIndexes() {
    List<int> indexes = [];
    for (int i = 0; i < daysOfWeek.length; i++) {
      if (selectedDays[daysOfWeek[i]]!) {
        indexes.add(i);
      }
    }
    return indexes.join(',');
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final response = await _apiService.updateShop(
        shopId: int.parse(_currentShopData['id'].toString()),
        shopName: _shopNameController.text,
        location: _locationController.text,
        expertise: _getExpertiseIds(),
        homePage: _facebookController.text.isNotEmpty ? _facebookController.text : null,
        services: selectedServices.join(','),
        startTime: _formatTimeForAPI(openingTime),
        closeTime: _formatTimeForAPI(closingTime),
        dayIndex: _getDayIndexes(),
        shopLogoFile: _shopLogoFile,
        businessDocuFile: _businessPermitFile,
        validIdFile: _governmentIdFile,
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop details updated successfully')),
        );
        setState(() {
          _isEditing = false;
          _shopLogoFile = null;
          _businessPermitFile = null;
          _governmentIdFile = null;
        });

        await _refreshShopData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to update shop details')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
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
                        onPressed: () => Navigator.pop(context, true),
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
                      child: _isSaving
                          ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                          : IconButton(
                        icon: Icon(
                          _isEditing ? Icons.close : Icons.edit,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (_isEditing) {
                            setState(() {
                              _isEditing = false;
                              _shopLogoFile = null;
                              _businessPermitFile = null;
                              _governmentIdFile = null;
                              _initializeData();
                            });
                          } else {
                            setState(() => _isEditing = true);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const DotLoading(),
                      const SizedBox(height: 16),
                      const Text(
                        'Refreshing shop data...',
                        style: TextStyle(
                          color: Color(0xFF1A3D63),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24).copyWith(bottom: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: _isEditing
                                  ? () => _showImageSourceDialog('shopLogo')
                                  : (_currentShopData['shopLogo'] != null && _currentShopData['shopLogo'].isNotEmpty)
                                  ? () => _showFullScreenImage(NetworkImage('${ApiService.apiUrl}shopLogo/${_currentShopData['shopLogo']}'))
                                  : null,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 80,
                                    backgroundColor: Colors.grey.shade300,
                                    backgroundImage: _shopLogoFile != null
                                        ? FileImage(_shopLogoFile!)
                                        : (_currentShopData['shopLogo'] != null && _currentShopData['shopLogo'].isNotEmpty)
                                        ? NetworkImage('${ApiService.apiUrl}shopLogo/${_currentShopData['shopLogo']}')
                                        : const AssetImage('assets/images/placeholderCar.png') as ImageProvider,
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
                          const SizedBox(height: 32),
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
                          if (_isEditing) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Types of vehicles your shop services',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _isEditing
                                ? expertiseOptions.map((expertise) {
                              bool isSelected = selectedExpertise.contains(expertise);
                              return ChoiceChip(
                                label: Text(expertise),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    if (isSelected) {
                                      selectedExpertise.remove(expertise);
                                    } else {
                                      selectedExpertise.add(expertise);
                                    }
                                  });
                                },
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
                            }).toList()
                                : selectedExpertise.map((expertise) {
                              return Chip(
                                label: Text(expertise),
                                backgroundColor: const Color(0xFF1A3D63),
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Color(0xFF1A3D63)),
                                ),
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
                          if (_isEditing) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Services your shop offers',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _isEditing
                                ? serviceOptions.map((service) {
                              bool isSelected = selectedServices.contains(service);
                              return ChoiceChip(
                                label: Text(service),
                                selected: isSelected,
                                onSelected: (_) => _toggleService(service),
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
                            }).toList()
                                : selectedServices
                                .where((s) => s != 'Select All')
                                .map((service) {
                              return Chip(
                                label: Text(service),
                                backgroundColor: const Color(0xFF1A3D63),
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Color(0xFF1A3D63)),
                                ),
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
                          if (_isEditing) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Days these hours apply to',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _isEditing
                                ? daysOfWeek.map((day) {
                              bool isSelected = selectedDays[day]!;
                              return ChoiceChip(
                                label: Text(day),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    selectedDays[day] = !isSelected;
                                  });
                                },
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
                            }).toList()
                                : daysOfWeek.where((day) => selectedDays[day]!).map((day) {
                              return Chip(
                                label: Text(day),
                                backgroundColor: const Color(0xFF1A3D63),
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Color(0xFF1A3D63)),
                                ),
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
                          const Text(
                            'Business Permit/Barangay Clearance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A3D63),
                            ),
                          ),
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
                          _buildDocumentPreview(
                              _currentShopData['business_docu'],
                              _businessPermitFile,
                              'Business Permit',
                              'business'
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Valid Government ID',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A3D63),
                            ),
                          ),
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
                          _buildDocumentPreview(
                              _currentShopData['valid_id'],
                              _governmentIdFile,
                              'Government ID',
                              'government'
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A3D63),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
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
      ),
    );
  }
}