import 'package:flutter/material.dart';
import 'registerShop_contactDetails.dart';
import 'package:care/dashboard.dart';
class RegisterShopBasicInfo extends StatefulWidget {
  const RegisterShopBasicInfo({Key? key}) : super(key: key);

  @override
  _RegisterShopBasicInfoState createState() => _RegisterShopBasicInfoState();
}

class _RegisterShopBasicInfoState extends State<RegisterShopBasicInfo> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final Map<String, int> expertiseMap = {
    'Car': 0,
    'Motorcycle': 1,
    'Van': 2,
    'Truck': 3,
    'Bus': 4,
    'Jeep': 5
  };
  List<String> expertiseOptions = ['Car', 'Motorcycle', 'Van', 'Truck', 'Bus', 'Jeep'];
  List<String> selectedExpertise = [];

  @override
  void dispose() {
    _shopNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _toggleExpertise(String expertise) {
    setState(() {
      if (selectedExpertise.contains(expertise)) {
        selectedExpertise.remove(expertise);
      } else {
        selectedExpertise.add(expertise);
      }
    });
  }

  String _getExpertiseIds() {
    return selectedExpertise.map((e) => expertiseMap[e].toString()).join(',');
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && selectedExpertise.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterShopContactDetails(
            shopName: _shopNameController.text,
            location: _locationController.text,
            expertise: _getExpertiseIds(),
          ),
        ),
      );
    } else if (selectedExpertise.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one expertise')),
      );
    }
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
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const DashboardScreen()),
                        );
                      },
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Register Shop',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Information Form',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3D63),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                          decoration: _inputDecoration('Enter your shop name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your shop name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
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
                          decoration: _inputDecoration('Enter shop location'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter shop location';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
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
                        'Select the types of vehicles your shop services',
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
                            onSelected: (_) => _toggleExpertise(expertise),
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
                            visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A3D63),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: const Text(
                            'Next',
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
            ),
          ],
        ),
      ),
    );
  }
}