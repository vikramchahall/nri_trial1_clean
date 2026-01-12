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

  // 🔑 TRACK MEDIA TYPE
  bool _isFileTypeVideo = false;

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
        maxDuration: const Duration(seconds: 30),
      );
    } else {
      file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        imageQuality: 70,
      );
    }

    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedMediaBytes = bytes;
        _isFileTypeVideo = isVideo; // ✅ SAVE TYPE
      });
    }
  }

  // ===============================
  // ⬆️ UPLOAD POST (FIXED)
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

    // ✅ DYNAMIC FILE EXTENSION (THE FIX)
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    if (_isFileTypeVideo) {
      fileName += ".mp4";
    } else {
      fileName += ".jpg";
    }

    await context.read<CrowdCubit>().createCrowdPost(
          text: _captionController.text,
          imageBytes: _selectedMediaBytes!,
          target: targetValue,
          uId: user.uid,
          uName: user.username,
          customFileName: fileName, // ✅ PASSED TO CUBIT
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
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickMedia(false),
                    child: _pickerTile(
                      icon: Icons.image,
                      label: "Pick Image",
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickMedia(true),
                    child: _pickerTile(
                      icon: Icons.videocam,
                      label: "Pick Video",
                    ),
                  ),
                ),
              ],
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

  Widget _pickerTile({required IconData icon, required String label}) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
