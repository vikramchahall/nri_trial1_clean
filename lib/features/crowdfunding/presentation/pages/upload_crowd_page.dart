import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:image_picker/image_picker.dart';

import '../cubits/crowd_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import 'package:nri_trial1_clean/utlis/image_converter.dart';

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
  String? _selectedFileName;

  bool _isUploading = false;
  bool _isDonationPost = false;

  // ===============================
  // 📷 PICK IMAGE (HEIC SAFE)
  // ===============================
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return;

    final String lowerName = image.name.toLowerCase();

    // 🚫 BLOCK HEIC ON WEB (CRITICAL)
    if (kIsWeb &&
        (lowerName.endsWith('.heic') || lowerName.endsWith('.heif'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "HEIC images are not supported on web. Please upload JPG or PNG.",
          ),
        ),
      );
      return;
    }

    final bytes = await image.readAsBytes();

    setState(() {
      _selectedImage = bytes;
      _selectedFileName = image.name;
    });
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

    if (_selectedImage == null || _selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      return;
    }

    setState(() => _isUploading = true);

    // ===============================
    // 🧠 IMAGE PREPARATION
    // ===============================
    final String nameLower = _selectedFileName!.toLowerCase();
    final bool isHeic =
        nameLower.endsWith('.heic') || nameLower.endsWith('.heif');

    // Convert ONLY on mobile
    final Uint8List safeBytes =
        convertToJpegIfNeeded(_selectedImage!, _selectedFileName!);

    await context.read<CrowdCubit>().createCrowdPost(
          text: _captionController.text,
          imageBytes: safeBytes,
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
            onPressed: _isUploading ? null : _upload,
            icon: const Icon(Icons.done),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
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
                    ? Image.memory(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 50),
                      )
                    : const Icon(Icons.add_a_photo, size: 50),
              ),
            ),

            const SizedBox(height: 20),

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

            if (_isDonationPost) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Target Money Needed (₹)",
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 15),

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
