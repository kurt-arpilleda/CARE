import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'registerShop_businessDocu.dart';
import 'package:care/options.dart';

class RegisterShopContactDetails extends StatefulWidget {
  final String shopName;
  final String location;
  final String expertise;
  final double latitude;
  final double longitude;

  const RegisterShopContactDetails({
    Key? key,
    required this.shopName,
    required this.location,
    required this.expertise,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  _RegisterShopContactDetailsState createState() => _RegisterShopContactDetailsState();
}

class _RegisterShopContactDetailsState extends State<RegisterShopContactDetails> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _facebookFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  List<String> selectedServices = [];
  TimeOfDay? openingTime;
  TimeOfDay? closingTime;
  Map<String, bool> selectedDays = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };

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

  void _toggleDay(String day) {
    setState(() {
      selectedDays[day] = !selectedDays[day]!;
    });
  }

  void _toggleAllDays() {
    setState(() {
      bool allSelected = selectedDays.values.every((value) => value);
      for (var day in selectedDays.keys) {
        selectedDays[day] = !allSelected;
      }
    });
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

  Future<void> _selectTime(BuildContext context, bool isOpening) async {
    _facebookFocusNode.unfocus();
    _phoneFocusNode.unfocus();
    FocusScope.of(context).requestFocus(FocusNode());
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isOpening) {
          openingTime = picked;
          if (closingTime != null && picked.hour > closingTime!.hour) {
            closingTime = TimeOfDay(hour: (picked.hour + 1) % 24, minute: 0);
          }
        } else {
          if (openingTime == null || picked.hour > openingTime!.hour) {
            closingTime = picked;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Closing time must be after opening time')),
            );
          }
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay? tod) {
    if (tod == null) return '';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = MaterialLocalizations.of(context).formatTimeOfDay(tod);
    return format;
  }

  String _formatTimeForAPI(TimeOfDay? tod) {
    if (tod == null) return '';
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}:00';
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && selectedServices.isNotEmpty) {
      if (openingTime == null || closingTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set both opening and closing times')),
        );
        return;
      }

      if (!selectedDays.containsValue(true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one day for the service times')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterShopBusinessDocu(
            shopName: widget.shopName,
            location: widget.location,
            expertise: widget.expertise,
            homePage: _facebookController.text.isNotEmpty ? _facebookController.text : null,
            phoneNum: _phoneController.text,
            services: selectedServices.join(','),
            startTime: _formatTimeForAPI(openingTime),
            closeTime: _formatTimeForAPI(closingTime),
            dayIndex: _getDayIndexes(),
            latitude: widget.latitude,
            longitude: widget.longitude,
          ),
        ),
      );
    } else if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service')),
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
  void dispose() {
    _facebookController.dispose();
    _phoneController.dispose();
    _facebookFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
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
                        'Contact Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3D63),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Home Page (Optional)',
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
                          focusNode: _facebookFocusNode,
                          decoration: _inputDecoration('Enter home page link'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Contact Number',
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
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _inputDecoration('Enter contact number'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter contact number';
                            }
                            if (value.length < 10) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
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
                        'Select the services your shop offers',
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
                            visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
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
                        'Set your shop opening and closing hours',
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
                              onTap: () => _selectTime(context, true),
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
                                  openingTime != null
                                      ? _formatTimeOfDay(openingTime)
                                      : 'Opening Time',
                                  style: TextStyle(
                                    color: openingTime == null ? Colors.grey[500] : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(context, false),
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
                                  closingTime != null
                                      ? _formatTimeOfDay(closingTime)
                                      : 'Closing Time',
                                  style: TextStyle(
                                    color: closingTime == null ? Colors.grey[500] : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Days',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A3D63),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select the days these hours apply to',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...daysOfWeek.map((day) {
                            bool isSelected = selectedDays[day]!;
                            return ChoiceChip(
                              label: Text(day),
                              selected: isSelected,
                              onSelected: (_) => _toggleDay(day),
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
                          ChoiceChip(
                            label: const Text('Select All'),
                            selected: selectedDays.values.every((value) => value),
                            onSelected: (_) => _toggleAllDays(),
                            selectedColor: const Color(0xFF1A3D63),
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: selectedDays.values.every((value) => value)
                                  ? Colors.white
                                  : const Color(0xFF1A3D63),
                              fontWeight: FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: selectedDays.values.every((value) => value)
                                    ? const Color(0xFF1A3D63)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            showCheckmark: false,
                            visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Color(0xFF1A3D63)),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Back',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF1A3D63),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
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
                          ),
                        ],
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