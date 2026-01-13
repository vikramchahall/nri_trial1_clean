import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
            _showNewsDialog(context);
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

// ---------------- NEWS ----------------
void _showNewsDialog(BuildContext context) {
  final title = TextEditingController();
  final message = TextEditingController();

  _baseDialog(
    context,
    title: "New Announcement",
    children: [
      TextField(controller: title, decoration: const InputDecoration(hintText: "Title")),
      const SizedBox(height: 10),
      TextField(controller: message, maxLines: 3, decoration: const InputDecoration(hintText: "Message")),
    ],
    onSubmit: () async {
      await Supabase.instance.client.from('official_updates').insert({
        'title': title.text,
        'message': message.text,
      });
      Navigator.pop(context);
    },
  );
}

// ---------------- ACHIEVEMENT ----------------
void _showAchievementDialog(BuildContext context) {
  final title = TextEditingController();
  final shortDesc = TextEditingController();

  _baseDialog(
    context,
    title: "Add Achievement",
    children: [
      TextField(controller: title, decoration: const InputDecoration(hintText: "Achievement Title")),
      const SizedBox(height: 10),
      TextField(controller: shortDesc, decoration: const InputDecoration(hintText: "Short Description")),
    ],
    onSubmit: () async {
      await Supabase.instance.client.from('achievements').insert({
        'title': title.text,
        'short_description': shortDesc.text,
        'timestamp': DateTime.now().toIso8601String(),
      });
      Navigator.pop(context);
    },
  );
}

// ---------------- COMMON DIALOG UI ----------------
void _baseDialog(
  BuildContext context, {
  required String title,
  required List<Widget> children,
  required VoidCallback onSubmit,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...children,
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onSubmit, child: const Text("Submit")),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
