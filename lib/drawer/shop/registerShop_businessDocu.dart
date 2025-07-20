import 'package:flutter/material.dart';

class RegisterShopBusinessDocu extends StatefulWidget {
  const RegisterShopBusinessDocu({Key? key}) : super(key: key);

  @override
  _RegisterShopBusinessDocuState createState() => _RegisterShopBusinessDocuState();
}

class _RegisterShopBusinessDocuState extends State<RegisterShopBusinessDocu> {
  String? _businessPermitPath;
  String? _governmentIdPath;

  Future<void> _showUploadOptions(String type) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Upload Options'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleUpload(type, 'camera');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleUpload(type, 'gallery');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleUpload(String type, String source) {
    setState(() {
      if (type == 'business') {
        _businessPermitPath = 'Uploaded from $source';
      } else {
        _governmentIdPath = 'Uploaded from $source';
      }
    });
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Business Documents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Upload Business Permit/Barangay Clearance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showUploadOptions('business'),
                      child: Container(
                        decoration: _fieldShadowBox(),
                        child: TextFormField(
                          enabled: false,
                          decoration: _inputDecoration('Tap to upload file'),
                          controller: TextEditingController(text: _businessPermitPath),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Upload Valid Government ID',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showUploadOptions('government'),
                      child: Container(
                        decoration: _fieldShadowBox(),
                        child: TextFormField(
                          enabled: false,
                          decoration: _inputDecoration('Tap to upload file'),
                          controller: TextEditingController(text: _governmentIdPath),
                        ),
                      ),
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
                              onPressed: () {
                                if (_businessPermitPath == null || _governmentIdPath == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please upload all required documents')),
                                  );
                                } else {
                                  Navigator.pushNamed(context, '/registerShop/complete');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A3D63),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: const Text(
                                'Finish',
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
          ],
        ),
      ),
    );
  }
}