// ============================================
// FILE 4: faq_page.dart (NEW)
// ============================================
import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[900],
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFAQItem(
            question: 'What is Connect NRI?',
            answer:
                'Connect NRI is a district-level community engagement platform initiated by the Jalandhar district administration team to facilitate communication and awareness.',
          ),
          _buildFAQItem(
            question: 'Is this an official government app?',
            answer:
                'No, this is a district initiative application, not an official Government of India or Punjab Government app. It is a community platform for public engagement.',
          ),
          _buildFAQItem(
            question: 'Who can use this app?',
            answer:
                'Anyone can download and use this app. Different user roles (Admin, DC, Contributors, Public) have access to different features based on their responsibilities.',
          ),
          _buildFAQItem(
            question: 'How do I create an account?',
            answer:
                'Tap on "Sign Up" on the login screen, fill in your details including username, email, and password, and complete the registration process.',
          ),
          _buildFAQItem(
            question: 'Can I make donations through this app?',
            answer:
                'Currently, the app does not support financial transactions or donations. A voluntary contribution feature may be introduced in future updates.',
          ),
          _buildFAQItem(
            question: 'How do I report an issue?',
            answer:
                'You can contact us at sevapani08@gmail.com with details of your issue, and our team will assist you as soon as possible.',
          ),
          _buildFAQItem(
            question: 'How do I delete my account?',
            answer:
                'Go to Settings > Delete Account. Please note that this action is permanent and cannot be undone.',
          ),
          _buildFAQItem(
            question: 'Is my data safe?',
            answer:
                'Yes, we take data privacy seriously. Please refer to our Privacy Policy for detailed information about how we handle your data .',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
