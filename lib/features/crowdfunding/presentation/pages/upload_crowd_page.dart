import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../cubits/crowd_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';

class UploadCrowdPage extends StatefulWidget {
  const UploadCrowdPage({super.key});

  @override
  State<UploadCrowdPage> createState() => _UploadCrowdPageState();
}

class _UploadCrowdPageState extends State<UploadCrowdPage> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();

  Uint8List? _selectedMediaBytes;
  bool _isVideo = false;

  bool _isUploading = false;
  bool _isDonationPost = false;

  // ===============================
  // 📷 PICK IMAGE OR VIDEO
  // ===============================
  Future<void> _pickMedia(bool isVideo) async {
    final ImagePicker picker = ImagePicker();
    XFile? file;

    if (isVideo) {
      file = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30), // ⛔ LIMIT VIDEO
      );
    } else {
      file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,     // 📉 COMPRESS IMAGE
        imageQuality: 70,   // 📉 COMPRESS IMAGE
      );
    }

    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedMediaBytes = bytes;
        _isVideo = isVideo;
      });
    }
  }

  // ===============================
  // ⬆️ UPLOAD POST
  // ===============================
  Future<void> _upload() async {
    final user = context.read<AuthCubit>().currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    if (_selectedMediaBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image or video")),
      );
      return;
    }

    double targetValue = 0;
    if (_isDonationPost) {
      targetValue = double.tryParse(_targetController.text) ?? 0;
      if (targetValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter valid donation amount")),
        );
        return;
      }
    }

    setState(() => _isUploading = true);

    await context.read<CrowdCubit>().createCrowdPost(
          text: _captionController.text,
          imageBytes: _selectedMediaBytes!, // video support later
          target: targetValue,
          uId: user.uid,
          uName: user.username,
        );

    if (mounted) Navigator.pop(context);
  }

  // ===============================
  // 🖥 UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Post"),
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: _isUploading ? null : _upload,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // MEDIA PICKER
            GestureDetector(
              onTap: () => _pickMedia(false), // image for now
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedMediaBytes != null
                    ? const Icon(Icons.check_circle,
                        size: 60, color: Colors.green)
                    : const Icon(Icons.add_a_photo, size: 50),
              ),
            ),

            const SizedBox(height: 20),

            // DONATION SWITCH
            SwitchListTile(
              title: const Text(
                "Post for Donation?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Enable this to ask for funds"),
              value: _isDonationPost,
              onChanged: (val) =>
                  setState(() => _isDonationPost = val),
              activeColor: Colors.green,
            ),

            if (_isDonationPost) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Target Amount (₹)",
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 15),

            // CAPTION
            TextField(
              controller: _captionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Caption / Description",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
