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
  bool _isFileTypeVideo = false;

  bool _isUploading = false;
  bool _isDonationPost = false;

  // ===============================
  // 📷 PICK MEDIA
  // ===============================
  Future<void> _pickMedia(bool isVideo) async {
    if (_isUploading) return;

    final picker = ImagePicker();
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
        _isFileTypeVideo = isVideo;
      });
    }
  }

  // ===============================
  // ⬆️ UPLOAD (ZERO LAG FIX)
  // ===============================
  Future<void> _upload() async {
    // 🔥 SHOW LOADING IMMEDIATELY
    setState(() => _isUploading = true);

    // ⏳ LET UI RENDER FIRST
    await Future.delayed(const Duration(milliseconds: 10));

    final user = context.read<AuthCubit>().currentUser;

    if (user == null) {
      _stopLoading("User not logged in");
      return;
    }

    if (_selectedMediaBytes == null) {
      _stopLoading("Please select an image or video");
      return;
    }

    double targetValue = 0;
    if (_isDonationPost) {
      targetValue = double.tryParse(_targetController.text) ?? 0;
      if (targetValue <= 0) {
        _stopLoading("Enter valid donation amount");
        return;
      }
    }

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    fileName += _isFileTypeVideo ? ".mp4" : ".jpg";

    try {
      await context.read<CrowdCubit>().createCrowdPost(
            text: _captionController.text,
            imageBytes: _selectedMediaBytes!,
            target: targetValue,
            uId: user.uid,
            uName: user.username,
            customFileName: fileName,
          );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _stopLoading("Upload failed. Try again.");
    }
  }

  void _stopLoading(String message) {
    setState(() => _isUploading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ===============================
  // 🖥 UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                // PREVIEW
                if (_selectedMediaBytes != null)
                  Container(
                    height: 220,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _isFileTypeVideo
                          ? const Center(
                              child: Icon(Icons.videocam,
                                  color: Colors.white, size: 50),
                            )
                          : Image.memory(
                              _selectedMediaBytes!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),

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

                SwitchListTile(
                  title: const Text(
                    "Post for Donation?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: _isDonationPost,
                  onChanged:
                      _isUploading ? null : (v) => setState(() => _isDonationPost = v),
                ),

                if (_isDonationPost)
                  TextField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Target Amount (₹)",
                    ),
                  ),

                const SizedBox(height: 15),

                TextField(
                  controller: _captionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Caption / Description",
                  ),
                ),
              ],
            ),
          ),
        ),

        // 🔥 FULLSCREEN LOADING OVERLAY (NO LAG)
        if (_isUploading)
          Container(
            color: Colors.black.withOpacity(0.35),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
      ],
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
