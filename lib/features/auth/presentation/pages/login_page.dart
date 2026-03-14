import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nri_trial1_clean/components/my_button.dart';
import 'package:nri_trial1_clean/components/my_text_field.dart';
import 'package:nri_trial1_clean/services/translations.dart';

import '../cubits/auth_cubit.dart';
import '../cubits/language_cubit.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final pwController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authCubit = context.read<AuthCubit>();
    if (authCubit.prefillEmail != null) {
      emailController.text = authCubit.prefillEmail!;
    }
    if (authCubit.prefillPassword != null) {
      pwController.text = authCubit.prefillPassword!;
    }
  }

  void login() {
    final email = emailController.text.trim();
    final pw = pwController.text;
    if (email.isNotEmpty && pw.isNotEmpty) {
      context.read<AuthCubit>().login(email, pw);
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (innerContext) => AlertDialog(
        title: const Text("Select Language"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("English"),
              onTap: () {
                context.read<LanguageCubit>().changeLanguage(AppLanguage.english);
                Navigator.pop(innerContext);
              },
            ),
            ListTile(
              title: const Text("हिंदी"),
              onTap: () {
                context.read<LanguageCubit>().changeLanguage(AppLanguage.hindi);
                Navigator.pop(innerContext);
              },
            ),
            ListTile(
              title: const Text("ਪੰਜਾਬੀ"),
              onTap: () {
                context.read<LanguageCubit>().changeLanguage(AppLanguage.punjabi);
                Navigator.pop(innerContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, AppLanguage>(
      builder: (context, lang) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _showLanguageDialog,
            child: const Icon(Icons.translate, color: Colors.green),
          ),
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    Image.asset(
                      'assets/logo.png',
                      height: 150,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "An initiative by District Administration Jalandhar",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 25),

                    Text(
                      AppTexts.get('welcome', lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 25),

                    MyTextField(
                      controller: emailController,
                      hintText: AppTexts.get('email', lang),
                      obscureText: false,
                    ),

                    const SizedBox(height: 10),

                    MyTextField(
                      controller: pwController,
                      hintText: AppTexts.get('password', lang),
                      obscureText: true,
                    ),

                    // ✅ FIXED FORGOT PASSWORD
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          if (emailController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter your email first"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          context
                              .read<AuthCubit>()
                              .forgotPassword(emailController.text.trim());
                        },
                        child: Text(
                          AppTexts.get('forgot_pw', lang),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    MyButton(
                      onTap: login,
                      text: AppTexts.get('login', lang),
                    ),

                    const SizedBox(height: 25),

                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        AppTexts.get('no_account', lang),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          children: [
                            const TextSpan(
                              text: 'By signing up, you agree to our ',
                            ),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _launchUrl('https://connect-nri.github.io/terms/');
                                },
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _launchUrl('https://connect-nri.github.io/policy/');
                                },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}