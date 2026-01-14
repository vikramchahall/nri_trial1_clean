// ============================================
// FILE 5: privacy_policy_page.dart (NEW)
// ============================================
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[900],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            _buildSection(
              title: '1. Information We Collect',
              content:
                  'We collect information that you provide directly to us, including:\n\n'
                  '• Account information (username, email, password)\n'
                  '• Profile information (bio, profile picture)\n'
                  '• Location information (city, town, panchayat ID)\n'
                  '• Content you post (posts, comments, interactions)',
            ),
            _buildSection(
              title: '2. How We Use Your Information',
              content:
                  'We use the information we collect to:\n\n'
                  '• Provide and maintain our services\n'
                  '• Improve user experience\n'
                  '• Communicate with you about updates\n'
                  '• Ensure platform security',
            ),
            _buildSection(
              title: '3. Data Security',
              content:
                  'We implement appropriate security measures to protect your personal information. However, no method of transmission over the internet is 100% secure.',
            ),
            _buildSection(
              title: '4. Third-Party Services',
              content:
                  'We use Supabase for backend services. Your data is stored securely according to their privacy standards.',
            ),
            _buildSection(
              title: '5. Your Rights',
              content:
                  'You have the right to:\n\n'
                  '• Access your personal data\n'
                  '• Correct inaccurate data\n'
                  '• Request deletion of your data\n'
                  '• Object to data processing',
            ),
            _buildSection(
              title: '6. Contact Us',
              content:
                  'If you have any questions about this Privacy Policy, please contact us at:\n\n'
                  'sevapani08@gmail.com',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
