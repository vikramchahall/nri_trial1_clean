import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nri_trial1_clean/components/my_button.dart';
import 'package:nri_trial1_clean/components/my_text_field.dart';

import '../cubits/auth_cubit.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final pwController = TextEditingController();
  final confirmPwController = TextEditingController();

  void register() {
    final email = emailController.text;
    final pw = pwController.text;
    final confirmPw = confirmPwController.text;

    if (pw == confirmPw && email.isNotEmpty) {
      context.read<AuthCubit>().register(email, pw);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add, size: 80, color: Colors.green),
              const SizedBox(height: 25),
              const Text("C R E A T E  A C C O U N T", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              MyTextField(controller: emailController, hintText: "Email", obscureText: false),
              const SizedBox(height: 10),
              MyTextField(controller: pwController, hintText: "Password", obscureText: true),
              const SizedBox(height: 10),
              MyTextField(controller: confirmPwController, hintText: "Confirm Password", obscureText: true),
              const SizedBox(height: 25),
              MyButton(onTap: register, text: "Register"),
              const SizedBox(height: 25),
              GestureDetector(
                onTap: widget.onTap,
                child: const Text("Already a member? Login here", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}