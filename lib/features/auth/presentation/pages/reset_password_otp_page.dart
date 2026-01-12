import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/auth_cubit.dart';
import '../../../../components/my_button.dart';
import '../../../../components/my_text_field.dart';

class ResetPasswordOtpPage extends StatefulWidget {
  final String email;
  const ResetPasswordOtpPage({super.key, required this.email});

  @override
  State<ResetPasswordOtpPage> createState() => _ResetPasswordOtpPageState();
}

class _ResetPasswordOtpPageState extends State<ResetPasswordOtpPage> {
  final otpController = TextEditingController();
  final passController = TextEditingController();

  void onResetTapped() {
    if (otpController.text.length < 6 || passController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fill all fields (min 6 chars)")));
      return;
    }
    context.read<AuthCubit>().verifyAndReset(
      email: widget.email,
      otp: otpController.text,
      newPassword: passController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_reset, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              const Text("Set New Password", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Enter the 6-digit code sent to ${widget.email}", textAlign: TextAlign.center),
              const SizedBox(height: 30),
              
              MyTextField(controller: otpController, hintText: "6-Digit OTP Code", obscureText: false),
              const SizedBox(height: 10),
              MyTextField(controller: passController, hintText: "New Password", obscureText: true),
              
              const SizedBox(height: 25),
              MyButton(onTap: onResetTapped, text: "Reset Password"),
              
              TextButton(
                onPressed: () => context.read<AuthCubit>().goToLogin(),
                child: const Text("Back to Login", style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}