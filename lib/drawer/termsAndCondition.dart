import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:care/dashboard.dart';

class TermsAndConditionScreen extends StatelessWidget {
  const TermsAndConditionScreen({Key? key}) : super(key: key);

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
                        'Terms and Conditions',
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
                                Icons.description,
                                color: Color(0xFF1A3D63),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'CARES Terms and Conditions',
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
                          'Welcome to CARES. By downloading, accessing, or using our application, you agree to comply with and be bound by the following Terms and Conditions. Please read them carefully before using the application.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildSection(
                          '1. Acceptance of Terms',
                          'By using CARES, you confirm that you are at least 18 years old and above or have parental/guardian consent, and that you agree to these Terms and Conditions, as well as our Privacy Policy. If you do not agree, please discontinue use of the app.',
                        ),
                        _buildSection(
                          '2. Services Provided',
                          'CARES provides:\n• Access to auto repair shops and mechanics within CALABARZON.\n• Emergency roadside assistance.\n• Real-time updates and service tracking (where available).',
                        ),
                        _buildSection(
                          '3. User Responsibilities',
                          'You agree to:\n• Provide accurate, complete, and updated information when registering.\n• Use the app for lawful purposes only.\n• Take responsibility for your own vehicle and safety during service engagements.\n• Pay any service charges, fees, or costs as agreed with the service provider.',
                        ),
                        _buildSection(
                          '4. Service Provider Disclaimer',
                          '• CARES does not guarantee the availability, quality.\n• All repairs, emergency responses, and transactions are the responsibility of the respective service providers.\n• CARES is not liable for damages, losses, delays, or disputes arising from services rendered by third parties.',
                        ),
                        _buildSection(
                          '5. Payments and Fees',
                          '• Certain services may require fees or charges.\n• Payments may be handled via cash, or directly with service providers.\n• CARES is not responsible for disputes regarding service charges between users and providers.',
                        ),
                        _buildSection(
                          '6. Limitation of Liability',
                          'To the maximum extent permitted by law:\n• CARES is not liable for any direct, indirect, incidental, or consequential damages arising from the use of the app or services.\n• CARES does not provide warranties regarding service outcomes, provider conduct, or emergency response times.',
                        ),
                        _buildSection(
                          '7. Account Termination',
                          'We reserve the right to suspend or terminate user accounts if:\n• Terms and Conditions are violated.\n• Fraudulent, abusive, or illegal activity is detected.',
                        ),
                        _buildSection(
                          '8. Intellectual Property',
                          'All content, logos, trademarks, and materials in the CARES app remain the property of CARES and may not be used without prior written permission.',
                        ),
                        _buildSection(
                          '9. Privacy Policy',
                          'Your personal information will be collected, stored, and processed in accordance with our Privacy Policy, which forms part of these Terms and Conditions.',
                        ),
                        _buildSection(
                          '10. Modifications to Terms',
                          'CARES reserves the right to update or revise these Terms at any time. Users will be notified of changes through the app or official communication channels. Continued use of the app means you accept the updated Terms.',
                        ),
                        _buildSection(
                          '11. Governing Law',
                          'These Terms and Conditions shall be governed by and construed under the laws of the Republic of the Philippines.',
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
                                  'By continuing to use CARES, you acknowledge that you have read, understood, and agree to these Terms and Conditions.',
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
            '12. Contact Us',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3D63),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'For questions, feedback, or support, you may contact us at:',
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