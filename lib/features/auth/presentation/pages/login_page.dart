import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nri_trial1_clean/components/my_button.dart';
import 'package:nri_trial1_clean/components/my_text_field.dart';

import '../cubits/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final pwController = TextEditingController();

  void login() {
    final email = emailController.text;
    final pw = pwController.text;
    if (email.isNotEmpty && pw.isNotEmpty) {
      context.read<AuthCubit>().login(email, pw);
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
              // 🟢 PUNJAB GOVERNMENT LOGO
 Image.asset(
  'assets/logo.png', // Make sure this matches your filename exactly
  height: 150,       // You can change this to make it bigger or smaller
  fit: BoxFit.contain,
),

              const SizedBox(height: 25),

              const Text(
                "N R I  C O N N E C T",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              MyTextField(
                controller: emailController,
                hintText: "Email",
                obscureText: false,
              ),

              const SizedBox(height: 10),

              MyTextField(
                controller: pwController,
                hintText: "Password",
                obscureText: true,
              ),

              const SizedBox(height: 25),

              MyButton(
                onTap: login,
                text: "Login",
              ),

              const SizedBox(height: 25),

              GestureDetector(
                onTap: widget.onTap,
                child: const Text(
                  "Not a member? Register now",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
