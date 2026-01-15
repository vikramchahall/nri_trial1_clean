// ============================================
// FILE 6: terms_conditions_page.dart (NEW)
// ============================================
import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
              'Terms & Conditions',
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
              title: '1. Acceptance of Terms',
              content:
                  'By accessing and using SevaPani, you accept and agree to be bound by these Terms and Conditions.',
            ),
            _buildSection(
              title: '2. User Responsibilities',
              content:
                  'You agree to:\n\n'
                  '• Provide accurate information\n'
                  '• Maintain account security\n'
                  '• Use the platform responsibly\n'
                  '• Not post harmful or illegal content\n'
                  '• Respect other users',
            ),
            _buildSection(
              title: '3. Content Ownership',
              content:
                  'You retain ownership of content you post. By posting, you grant us a license to use, display, and distribute your content on the platform.',
            ),
            _buildSection(
              title: '4. Prohibited Activities',
              content:
                  'You may not:\n\n'
                  '• Impersonate others\n'
                  '• Post spam or misleading content\n'
                  '• Attempt to hack or disrupt services\n'
                  '• Use the platform for illegal purposes',
            ),
            _buildSection(
              title: '5. Disclaimer',
              content:
                  'This is a district initiative application, not an official government app. Information is provided for community engagement purposes.',
            ),
            _buildSection(
              title: '6. Account Termination',
              content:
                  'We reserve the right to suspend or terminate accounts that violate these terms.',
            ),
            _buildSection(
              title: '7. Changes to Terms',
              content:
                  'We may modify these terms at any time. Continued use of the platform constitutes acceptance of modified terms.',
            ),
            _buildSection(
              title: '8. Contact',
              content:
                  'For questions about these terms, contact:\n\n'
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