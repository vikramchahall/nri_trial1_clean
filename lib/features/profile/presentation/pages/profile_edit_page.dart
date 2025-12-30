import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nri_trial1_clean/components/my_text_field.dart';
import 'package:nri_trial1_clean/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:nri_trial1_clean/features/profile/domain/entities/profile_user.dart';

class ProfileEditPage extends StatefulWidget {
  final ProfileUser user;
  const ProfileEditPage({super.key, required this.user});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    bioController.text = widget.user.bio;
  }

  void save() {
    context.read<ProfileCubit>().updateBio(widget.user.uid, bioController.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Bio"), actions: [IconButton(onPressed: save, icon: const Icon(Icons.done))]),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const Text("Write something about yourself:"),
            const SizedBox(height: 25),
            MyTextField(controller: bioController, hintText: "Enter bio...", obscureText: false),
          ],
        ),
      ),
    );
  }
}