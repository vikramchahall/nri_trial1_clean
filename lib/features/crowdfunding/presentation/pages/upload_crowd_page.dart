import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../cubits/crowd_cubit.dart';
import 'package:nri_trial1_clean/features/auth/presentation/cubits/auth_cubit.dart';


class UploadCrowdPage extends StatefulWidget {
  const UploadCrowdPage({super.key});

  @override
  State<UploadCrowdPage> createState() => _UploadCrowdPageState();
}

class _UploadCrowdPageState extends State<UploadCrowdPage> {
  final _captionController = TextEditingController();
  final _targetController = TextEditingController();
  Uint8List? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _selectedImage = bytes);
    }
  }

  void _post() {
    final user = context.read<AuthCubit>().currentUser;
    final target = double.tryParse(_targetController.text) ?? 0;

    if (_selectedImage != null && target > 0 && user != null) {
      context.read<CrowdCubit>().createCrowdPost(
        text: _captionController.text,
        imageBytes: _selectedImage!,
        target: target,
        uId: user.uid,
        uName: "Village Head", 
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create a Cause"), actions: [IconButton(onPressed: _post, icon: const Icon(Icons.done))]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200, width: double.infinity, color: Colors.grey.shade200,
                child: _selectedImage != null ? Image.memory(_selectedImage!, fit: BoxFit.cover) : const Icon(Icons.add_a_photo, size: 50),
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _targetController, decoration: const InputDecoration(labelText: "Target Money Needed (₹)"), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: _captionController, decoration: const InputDecoration(labelText: "Description / Cause")),
          ],
        ),
      ),
    );
  }
}