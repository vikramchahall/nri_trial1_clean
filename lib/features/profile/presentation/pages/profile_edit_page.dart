import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../components/my_text_field.dart';
import '../cubits/profile_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import 'package:nri_trial1_clean/features/profile/domain/entities/profile_user.dart';

import 'package:cached_network_image/cached_network_image.dart';

class ProfileEditPage extends StatefulWidget {
  final ProfileUser user;
  const ProfileEditPage({super.key, required this.user});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final bioController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();
  final townController = TextEditingController();
  final blockController = TextEditingController();
  final panchayatIdController = TextEditingController();

  Uint8List? _selectedImageBytes;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    bioController.text = widget.user.bio;
    usernameController.text = widget.user.username;
    phoneController.text = widget.user.phone ?? '';
    cityController.text = widget.user.city ?? '';
    townController.text = widget.user.town ?? '';
    blockController.text = widget.user.block;
    panchayatIdController.text = widget.user.panchayatId ?? '';
  }

  @override
  void dispose() {
    bioController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    cityController.dispose();
    townController.dispose();
    blockController.dispose();
    panchayatIdController.dispose();
    super.dispose();
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

  /// 💾 SAVE PROFILE (ALL FIELDS)
Future<void> save() async {
  setState(() => _isUploading = true);

  await context.read<ProfileCubit>().updateProfile(
    uid: widget.user.uid,
    authCubit: context.read<AuthCubit>(),
    newBio: bioController.text,
    newUsername: usernameController.text,
    newPhone: phoneController.text,
    newCity: cityController.text,
    newTown: townController.text,
    newBlock: blockController.text,
    newPanchayatId: panchayatIdController.text,
    imageBytes: _selectedImageBytes,
  );

  // ✅ FETCH THE UPDATED PROFILE
  await context.read<ProfileCubit>().fetchUserProfile(widget.user.uid);

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
    ? CachedNetworkImage(
        imageUrl: widget.user.imageVersion > 0
            ? "${widget.user.profileImageUrl}?v=${widget.user.imageVersion}"
            : widget.user.profileImageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Icon(
          Icons.person,
          size: 60,
          color: Colors.grey,
        ),
        errorWidget: (context, url, error) => const Icon(
          Icons.person,
          size: 60,
          color: Colors.grey,
        ),
      )
    : const Icon(
        Icons.person,
        size: 60,
        color: Colors.grey,
      ))
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

            // ================= USERNAME =================
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Username",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            MyTextField(
              controller: usernameController,
              hintText: "Username",
              obscureText: false,
            ),

            const SizedBox(height: 20),

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

            const SizedBox(height: 20),

            // ================= PHONE =================
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Phone Number",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            MyTextField(
              controller: phoneController,
              hintText: "Phone Number",
              obscureText: false,
            ),

            // ================= PIND USER FIELDS =================
            if (widget.user.userType == 'Pind') ...[
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Panchayat ID",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              MyTextField(
                controller: panchayatIdController,
                hintText: "Panchayat ID",
                obscureText: false,
              ),

              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Block Name",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              MyTextField(
                controller: blockController,
                hintText: "Block Name",
                obscureText: false,
              ),

              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "City",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              MyTextField(
                controller: cityController,
                hintText: "City",
                obscureText: false,
              ),

              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Town / Village",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              MyTextField(
                controller: townController,
                hintText: "Town / Village",
                obscureText: false,
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}