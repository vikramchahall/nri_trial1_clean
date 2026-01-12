import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/auth_cubit.dart';
import '../../../../components/my_button.dart';

class VerificationPage extends StatelessWidget {
  final String email;
  const VerificationPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.green),
              const SizedBox(height: 25),
              const Text("VERIFY YOUR EMAIL", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Text(
                "We have sent a verification link to:\n$email",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 30),
              
              // THE MAIN BUTTON
              MyButton(
               onTap: () => context.read<AuthCubit>().checkVerificationStatus(email),
  text: "I have verified my email",
              ),
              
              const SizedBox(height: 15),
              
              // RESEND BUTTON
              TextButton(
                onPressed: () {
                  context.read<AuthCubit>().authRepo.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link re-sent!")));
                },
                child: const Text("Resend Link", style: TextStyle(color: Colors.green)),
              ),
              
              const SizedBox(height: 10),
              
              // BACK TO LOGIN
              TextButton(
                onPressed: () => context.read<AuthCubit>().logout(),
                child: const Text("Back to Login", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}