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
  final _captionController = TextEditingController();
  final _targetController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImage;
  bool _isUploading = false;

  // 🔥 Donation toggle
  bool _isDonationPost = false;

  Future<void> _pickImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _selectedImage = bytes);
    }
  }

  void _upload() async {
    final user = context.read<AuthCubit>().currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    // 🎯 Target amount logic
    double targetValue = 0;
    if (_isDonationPost) {
      targetValue = double.tryParse(_targetController.text) ?? 0;
      if (targetValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid donation amount"),
          ),
        );
        return;
      }
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      return;
    }

    setState(() => _isUploading = true);

    await context.read<CrowdCubit>().createCrowdPost(
          text: _captionController.text,
          imageBytes: _selectedImage!,
          target: targetValue, // 0 if toggle OFF
          uId: user.uid,
          uName: user.username,
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Post"),
        actions: [
          IconButton(
            onPressed: _isUploading ? null : _upload,
            icon: const Icon(Icons.done),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 📷 IMAGE PICKER
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _selectedImage != null
                    ? Image.memory(_selectedImage!, fit: BoxFit.cover)
                    : const Icon(Icons.add_a_photo, size: 50),
              ),
            ),

            const SizedBox(height: 20),

            // 💰 DONATION TOGGLE
            SwitchListTile(
              title: const Text(
                "Post for Donation?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Enable this to ask for funds"),
              value: _isDonationPost,
              activeColor: Colors.green,
              onChanged: (val) => setState(() => _isDonationPost = val),
            ),

            const SizedBox(height: 10),

            // 💸 TARGET AMOUNT
            if (_isDonationPost)
              TextField(
                controller: _targetController,
                decoration: const InputDecoration(
                  labelText: "Target Money Needed (₹)",
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),

            const SizedBox(height: 15),

            // 📝 DESCRIPTION
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
