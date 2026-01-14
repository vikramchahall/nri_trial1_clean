// ============================================
// FILE 2: settings_page.dart (NEW)
// Location: lib/features/profile/presentation/pages/settings_page.dart
// ============================================
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
// 👇 ADD THESE
import 'about_application_page.dart';
import 'faq_page.dart';
import 'privacy_policy_page.dart';
import 'terms_conditions_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings & Support'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[900],
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            title: 'About',
            items: [
              _SettingsItem(
                icon: Icons.info_outline,
                title: 'About Application',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutApplicationPage(),
                  ),
                ),
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'Support',
            items: [
              _SettingsItem(
                icon: Icons.email_outlined,
                title: 'Contact Us',
                subtitle: 'sevapani08@gmail.com',
                onTap: () => _launchEmail(context),
              ),
              _SettingsItem(
                icon: Icons.help_outline,
                title: 'FAQ',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FAQPage(),
                  ),
                ),
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'Legal',
            items: [
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyPage(),
                  ),
                ),
              ),
              _SettingsItem(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TermsConditionsPage(),
                  ),
                ),
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'Account',
            items: [
              _SettingsItem(
                icon: Icons.delete_outline,
                title: 'Delete Account',
                textColor: Colors.red,
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(
            children: items.map((item) {
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon, color: item.textColor ?? Colors.green[700]),
                    title: Text(
                      item.title,
                      style: TextStyle(color: item.textColor),
                    ),
                    subtitle: item.subtitle != null
                        ? Text(item.subtitle!)
                        : null,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                    onTap: item.onTap,
                  ),
                  if (items.last != item)
                    Divider(height: 1, indent: 72, color: Colors.grey[200]),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'sevapani08@gmail.com',
      query: 'subject=Support Request&body=Hi, I need help with...',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email app. Please email us at sevapani08@gmail.com'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening email app'),
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDeleteAccount(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    // TODO: Implement account deletion logic with Supabase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account deletion will be implemented soon'),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? textColor;
  final VoidCallback onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.textColor,
    required this.onTap,
  });
}