import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/auth_cubit.dart';
import '../../../../components/my_button.dart';

class VerificationPage extends StatelessWidget {
  final String email;
  final String? password; // Optional: if you pass it from registration
  
  const VerificationPage({
    super.key, 
    required this.email,
    this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 25),
              const Text(
                "VERIFY YOUR EMAIL",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Text(
                "We have sent a verification link to:\n$email",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 30),

              // ✅ AUTO-LOGIN BUTTON
              MyButton(
                onTap: () async {
                  if (password != null) {
                    // If we have the password, auto-login directly
                    await context.read<AuthCubit>().login(email, password!);
                  } else {
                    // Otherwise, just go back to login page (pre-filled)
                    context.read<AuthCubit>().logout();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Great! Please login to continue.",
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                text: "I have verified my email",
              ),

              const SizedBox(height: 15),

              // RESEND BUTTON
              TextButton(
                onPressed: () {
                  context.read<AuthCubit>().authRepo.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Verification link re-sent!"),
                    ),
                  );
                },
                child: const Text(
                  "Resend Link",
                  style: TextStyle(color: Colors.green),
                ),
              ),

              const SizedBox(height: 10),

              // BACK TO LOGIN
              TextButton(
                onPressed: () => context.read<AuthCubit>().logout(),
                child: const Text(
                  "Back to Login",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}