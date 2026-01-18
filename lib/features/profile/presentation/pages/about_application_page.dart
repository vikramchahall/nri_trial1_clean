import 'package:flutter/material.dart';

class AboutApplicationPage extends StatelessWidget {
  const AboutApplicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('About Application'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[900],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.handshake,
                  size: 60,
                  color: Colors.green[700],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Connect NRI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildInfoCard(
              title: 'What is this app?',
              content:
                  'NRI Connect is a district-led community engagement and awareness platform initiated by the Jalandhar district administration team. It serves as a digital bridge between the district administration and the public.',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Purpose',
              content:
                  'This platform is designed for public communication, awareness, and community engagement. It helps share achievements, official-style updates, and public welfare information with transparency and efficiency.',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Key Features',
              content:
                  '• Community announcements and updates\n'
                  '• District achievements showcase\n'
                  '• Role-based access for different users\n'
                  '• Public engagement and participation\n'
                  '• Transparent communication platform',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Important Note',
              content:
                  'This is a district initiative application, not an official Government of India or Punjab Government app. It is a community platform developed to facilitate better communication and engagement at the district level.',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Future Updates',
              content:
                  'A voluntary contribution feature may be introduced in future updates to support district-led initiatives and community welfare programs.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
