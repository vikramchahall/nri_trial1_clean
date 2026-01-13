import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ================= ENTRY POINT =================
void showOfficialPostDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.campaign),
          title: const Text("Post Announcement"),
          onTap: () {
            Navigator.pop(context);
            _showAnnouncementDialog(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.stars),
          title: const Text("Add Achievement"),
          onTap: () {
            Navigator.pop(context);
            _showAchievementDialog(context);
          },
        ),
      ],
    ),
  );
}

//////////////////////////////////////////////////
/// --------------- ANNOUNCEMENT ----------------
//////////////////////////////////////////////////

void _showAnnouncementDialog(BuildContext context) {
  final titleCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  XFile? pickedFile;

  _baseDialog(
    context,
    title: "New Announcement",
    children: [
      TextField(
        controller: titleCtrl,
        decoration: const InputDecoration(hintText: "Title"),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: messageCtrl,
        maxLines: 3,
        decoration: const InputDecoration(hintText: "Message"),
      ),
      const SizedBox(height: 15),

      /// 📎 MEDIA PICKER
      StatefulBuilder(
        builder: (context, setState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: Text(
                  pickedFile == null ? "Add Photo / Video" : "Change Media",
                ),
                onPressed: () async {
                  final picker = ImagePicker();
                  final file = await picker.pickMedia();
                  if (file != null) {
                    setState(() => pickedFile = file);
                  }
                },
              ),
              if (pickedFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    pickedFile!.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
    onSubmit: () async {
      try {
        final supabase = Supabase.instance.client;

        String? mediaUrl;
        String? mediaType;
        String? storagePath;

        if (pickedFile != null) {
          final ext = pickedFile!.name.split('.').last.toLowerCase();
          final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
          mediaType = isVideo ? 'video' : 'image';

          storagePath = 'announcements/${DateTime.now().millisecondsSinceEpoch}_${pickedFile!.name}';

          if (kIsWeb) {
            final bytes = await pickedFile!.readAsBytes();
            await supabase.storage.from('official_media').uploadBinary(
                  storagePath,
                  bytes,
                  fileOptions: FileOptions(
                    contentType: isVideo ? 'video/$ext' : 'image/$ext',
                  ),
                );
          } else {
            final file = File(pickedFile!.path);
            await supabase.storage.from('official_media').upload(
                  storagePath,
                  file,
                  fileOptions: FileOptions(
                    contentType: isVideo ? 'video/$ext' : 'image/$ext',
                  ),
                );
          }

          mediaUrl = supabase.storage.from('official_media').getPublicUrl(storagePath);
        }

        /// 📥 INSERT ROW INTO TABLE
        final insertData = {
          'title': titleCtrl.text.trim(),
          'message': messageCtrl.text.trim(),
        };

        if (mediaUrl != null) insertData['media_url'] = mediaUrl;
        if (mediaType != null) insertData['media_type'] = mediaType;

        await supabase.from('official_updates').insert(insertData);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Announcement posted successfully!")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    },
  );
}

//////////////////////////////////////////////////
/// --------------- ACHIEVEMENT -----------------
//////////////////////////////////////////////////

void _showAchievementDialog(BuildContext context) {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final fullDetailsCtrl = TextEditingController();
  XFile? pickedImage;

  _baseDialog(
    context,
    title: "Add Achievement",
    children: [
      TextField(
        controller: titleCtrl,
        decoration: const InputDecoration(
          hintText: "Achievement Title",
          labelText: "Title",
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: descCtrl,
        decoration: const InputDecoration(
          hintText: "Short Description (for card)",
          labelText: "Short Description",
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: fullDetailsCtrl,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: "Full details about the achievement",
          labelText: "Full Details",
        ),
      ),
      const SizedBox(height: 15),

      /// 📎 IMAGE PICKER
      StatefulBuilder(
        builder: (context, setState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.image),
                label: Text(
                  pickedImage == null ? "Add Image" : "Change Image",
                ),
                onPressed: () async {
                  final picker = ImagePicker();
                  final file = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (file != null) {
                    setState(() => pickedImage = file);
                  }
                },
              ),
              if (pickedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    pickedImage!.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
    onSubmit: () async {
      if (titleCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a title")),
        );
        return;
      }

      try {
        final supabase = Supabase.instance.client;
        String? imageUrl;
        String? storagePath;

        if (pickedImage != null) {
          final ext = pickedImage!.name.split('.').last.toLowerCase();
          storagePath = 'achievements/${DateTime.now().millisecondsSinceEpoch}_${pickedImage!.name}';

          if (kIsWeb) {
            final bytes = await pickedImage!.readAsBytes();
            await supabase.storage.from('official_media').uploadBinary(
                  storagePath,
                  bytes,
                  fileOptions: FileOptions(
                    contentType: 'image/$ext',
                  ),
                );
          } else {
            final file = File(pickedImage!.path);
            await supabase.storage.from('official_media').upload(
                  storagePath,
                  file,
                  fileOptions: FileOptions(
                    contentType: 'image/$ext',
                  ),
                );
          }

          imageUrl = supabase.storage.from('official_media').getPublicUrl(storagePath);
        }

        /// 📥 INSERT INTO TABLE
        final insertData = {
          'title': titleCtrl.text.trim(),
        };

        if (descCtrl.text.trim().isNotEmpty) {
          insertData['short_description'] = descCtrl.text.trim();
        }
        if (fullDetailsCtrl.text.trim().isNotEmpty) {
          insertData['full_details'] = fullDetailsCtrl.text.trim();
        }
        if (imageUrl != null) insertData['image_url'] = imageUrl;

        await supabase.from('achievements').insert(insertData);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Achievement added successfully!")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    },
  );
}

//////////////////////////////////////////////////
/// --------------- COMMON UI -------------------
//////////////////////////////////////////////////

void _baseDialog(
  BuildContext context, {
  required String title,
  required List<Widget> children,
  required Future<void> Function() onSubmit,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...children,
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async => await onSubmit(),
                child: const Text("Submit"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
} 