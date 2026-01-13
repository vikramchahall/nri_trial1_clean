import 'package:flutter/material.dart';

void showOfficialPostDialog(BuildContext context) {
  final titleController = TextEditingController();
  final messageController = TextEditingController();

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
          const Text("New Official Update",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: "Update Title"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: messageController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: "Detailed Message"),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Post to Village"),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
