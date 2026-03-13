import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubits/auth_cubit.dart';
import '../../../../components/my_button.dart';

class VerificationPage extends StatefulWidget {
  final String email;
  final String? password;

  const VerificationPage({
    super.key,
    required this.email,
    this.password,
  });

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  int _secondsLeft = 60;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _secondsLeft = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

Future<void> _openGmail() async {
  // ✅ Try Gmail app first (Android intent)
  final Uri gmailAppUri = Uri.parse('intent://mail.google.com/#Intent;scheme=https;package=com.google.android.gm;end');
  final Uri gmailDirectUri = Uri.parse('googlegmail://');
  final Uri gmailWebUri = Uri.parse('https://mail.google.com');

  // Try Gmail app via package intent (Android)
  if (await canLaunchUrl(gmailDirectUri)) {
    await launchUrl(gmailDirectUri, mode: LaunchMode.externalApplication);
    return;
  }

  // Try Gmail app via intent
  if (await canLaunchUrl(gmailAppUri)) {
    await launchUrl(gmailAppUri, mode: LaunchMode.externalApplication);
    return;
  }

  // Fallback to web
  await launchUrl(gmailWebUri, mode: LaunchMode.externalApplication);
}

  void _resendEmail() {
    if (!_canResend) return;
    context.read<AuthCubit>().resendVerification(widget.email);
    _startCooldown(); // restart timer after resend
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
                "We have sent a verification link to:\n${widget.email}",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 30),

              // ✅ OPEN GMAIL BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openGmail,
                  icon: const Icon(Icons.mail, color: Colors.white, size: 22),
                  label: const Text(
                    "Open Gmail",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA4335),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ✅ I HAVE VERIFIED BUTTON
              MyButton(
                onTap: () async {
                  if (widget.password != null) {
                    await context
                        .read<AuthCubit>()
                        .login(widget.email, widget.password!);
                  } else {
                    context.read<AuthCubit>().goToLogin();
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

              // ✅ RESEND BUTTON WITH 60s COOLDOWN
              _canResend
                  ? TextButton(
                      onPressed: _resendEmail,
                      child: const Text(
                        "Resend Link",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Text(
                      "Resend available in $_secondsLeft seconds",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),

              const SizedBox(height: 10),

              // BACK TO LOGIN
              TextButton(
                onPressed: () => context.read<AuthCubit>().goToLogin(),
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