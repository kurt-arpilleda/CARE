import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:care/dashboard.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1A3D63),
            padding: const EdgeInsets.only(top: 30),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFFF6FAFD)),
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const DashboardScreen()),
                                  (Route<dynamic> route) => false,
                            );
                          },
                        ),
                      ),
                      const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: Color(0xFFF6FAFD),
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A3D63).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.privacy_tip,
                                color: Color(0xFF1A3D63),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A3D63),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Welcome to CARES. This Privacy Policy explains how we collect, use, disclose, and protect your personal information when you use the CARES mobile application (the "App") and its related services.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildSection(
                          '1. Introduction',
                          'Welcome to CARES.\nThis Privacy Policy explains how we collect, use, disclose, and protect your personal information when you use the CARES mobile application (the "App") and its related services.\n\nBy using the CARES App, you agree to the terms outlined in this Privacy Policy. If you do not agree, please stop using the App.',
                        ),
                        _buildSection(
                          '2. Information We Collect',
                          'We collect information to provide and improve our services. This may include:\n\na. Personal Information\n• Full name, email address, and contact number\n• Account login credentials\n• Vehicle details (plate number, model, brand, etc.)\n• Shop details (name, business permit, contact info, service types) for repair shop users\n\nb. Location Information\n• Real-time GPS location for service requests, tracking, and navigation\n• Approximate location for nearby shop listings and emergency assistance\n\nc. Usage Data\n• In-app interactions such as messages, ratings, and reports\n• Error logs and crash reports to improve system performance\n\nd. Uploaded Media\n• Photos or documents uploaded for verification, service requests, or reporting issues',
                        ),
                        _buildSection(
                          '3. How We Use Your Information',
                          'Your information helps us provide a secure and efficient platform. Specifically, we use it to:\n• Create and manage your user or repair shop account\n• Match customers with nearby repair shops or service providers\n• Provide location-based emergency services (e.g., roadside assistance)\n• Improve app performance and user experience\n• Enforce community guidelines and penalties for misconduct\n• Send important notices or policy updates',
                        ),
                        _buildSection(
                          '4. How We Share Information',
                          'We respect your privacy and only share data when necessary:\n• With service providers: To connect vehicle owners and repair shops for repair or emergency assistance\n• With administrators: For monitoring reports, complaints, and enforcing app policies\n• With law enforcement: When required by law, court order, or to protect user safety\n\nWe do not sell, rent, or trade your personal information to any third party.',
                        ),
                        _buildSection(
                          '5. Data Retention',
                          '• CARES retains personal data only as long as necessary to provide services or comply with legal obligations.',
                        ),
                        _buildSection(
                          '6. Data Security',
                          'We take data protection seriously. CARES implements:\n• Encryption of sensitive information during transmission\n• Secure authentication for account access\n• Regular monitoring to prevent unauthorized access or misuse\n\nHowever, no system is 100% secure. You use the app at your own risk, and we encourage you to protect your account credentials.',
                        ),
                        _buildSection(
                          '7. User Rights',
                          'You have the right to:\n• Access and review your personal data\n• Request correction or deletion of your data\n• File a complaint if you believe your data has been misused',
                        ),
                        _buildSection(
                          '8. Account Suspension and Ban Policy',
                          'As part of maintaining safety and fairness:\n• The Administrator may suspend or ban any account (vehicle owner or repair shop) that violates the app\'s rules.\n• Suspension lasts up to 1 week; bans last up to 3 weeks.\n• The Administrator sets the duration and automatic reactivation date of penalties.',
                        ),
                        _buildSection(
                          '9. Children\'s Privacy',
                          'CARES does not knowingly collect information from users under 18 years old. If we become aware that we have collected such data, we will delete it immediately.',
                        ),
                        _buildSection(
                          '10. Changes to This Privacy Policy',
                          'CARES may update this Privacy Policy from time to time. Continued use of the app means you accept the updated policy.',
                        ),
                        _buildContactSection(),
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A3D63).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1A3D63).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: const Color(0xFF1A3D63),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'By continuing to use CARES, you acknowledge that you have read, understood, and agree to this Privacy Policy.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF1A3D63),
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3D63),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '11. Contact Us',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3D63),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'If you have questions, concerns, or complaints about this Privacy Policy, contact us at:',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('mailto:cares8865@gmail.com')),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3D63).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF1A3D63),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'cares8865@gmail.com',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1A3D63),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('tel:09918289771')),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3D63).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.phone_outlined,
                          color: Color(0xFF1A3D63),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '09918289771',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1A3D63),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}