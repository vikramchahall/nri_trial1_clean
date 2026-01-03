import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../components/my_text_field.dart';
import '../cubits/profile_cubit.dart';
import 'package:nri_trial1_clean/features/profile/domain/entities/profile_user.dart';

class ProfileEditPage extends StatefulWidget {
  final ProfileUser user;
  const ProfileEditPage({super.key, required this.user});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final bioController = TextEditingController();

  Uint8List? _selectedImageBytes;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    bioController.text = widget.user.bio;
  }

  // 📸 PICK IMAGE FROM GALLERY
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  // 💾 SAVE PROFILE (BIO + IMAGE)
  Future<void> save() async {
    setState(() => _isUploading = true);

    await context.read<ProfileCubit>().updateProfile(
      uid: widget.user.uid,
      newBio: bioController.text,
      imageBytes: _selectedImageBytes,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          _isUploading
              ? const Padding(
                  padding: EdgeInsets.all(15),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  onPressed: save,
                  icon: const Icon(Icons.done),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // ================= PROFILE IMAGE PICKER =================
            GestureDetector(
              onTap: _pickImage,
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _selectedImageBytes != null
                            ? Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                              )
                            : (widget.user.profileImageUrl.isNotEmpty
                                ? Image.network(
                                    widget.user.profileImageUrl,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  )),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            const Text(
              "Tap to change profile photo",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),

            const SizedBox(height: 40),

            // ================= BIO =================
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "About Me / Bio",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            MyTextField(
              controller: bioController,
              hintText: "Tell supporters about yourself...",
              obscureText: false,
            ),
          ],
        ),
      ),
    );
  }
}
