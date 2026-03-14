import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/auth_cubit.dart';
import '../cubits/auth_states.dart';
import '../../../../components/my_button.dart';
import '../../../../components/my_text_field.dart';

// 🔹 LANGUAGE
import 'package:nri_trial1_clean/features/auth/presentation/cubits/language_cubit.dart';


class RegisterPage extends StatefulWidget {
  final void Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ================= CONTROLLERS =================
  final emailController = TextEditingController();
  final pwController = TextEditingController();
  final confirmPwController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();
  final townController = TextEditingController();
  final blockController = TextEditingController();
  final panchayatIdController = TextEditingController();

  String selectedUserType = 'Pind';

  // ================= REGISTER =================
  void register() {
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        pwController.text.isEmpty) {
      _showError("Please fill all details");
      return;
    }

    if (pwController.text != confirmPwController.text) {
      _showError("Passwords do not match");
      return;
    }

    context.read<AuthCubit>().registerUser(
      email: emailController.text,
      password: pwController.text,
      username: usernameController.text,
      userType: selectedUserType,
      city: cityController.text,
      town: townController.text,
      block: blockController.text,
      panchayatId: panchayatIdController.text,
      phone: phoneController.text,
    );
  }

  // ================= ERROR HANDLER =================
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.replaceAll("Exception: ", "")),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ================= LANGUAGE DIALOG =================
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Language / भाषा चुनें"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("English"),
              onTap: () {
                context.read<LanguageCubit>().changeLanguage(AppLanguage.english);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("हिंदी"),
              onTap: () {
                context.read<LanguageCubit>().changeLanguage(AppLanguage.hindi);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("ਪੰਜਾਬੀ"),
              onTap: () {
                context.read<LanguageCubit>().changeLanguage(AppLanguage.punjabi);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    // Hint text changes based on selected type — same controller, same backend
    final usernameHint = selectedUserType == 'Pind'
        ? "Pind Name"
        : "Unique Username";

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        // ✅ FLOATING LANGUAGE BUTTON
        floatingActionButton: FloatingActionButton(
          mini: true,
          backgroundColor: Colors.white,
          onPressed: () => _showLanguageDialog(context),
          child: const Icon(Icons.translate, color: Colors.green),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              25, 25, 25,
              25 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.account_balance,
                  size: 60,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),

                const Text(
                  "CREATE ACCOUNT",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 25),

                ToggleButtons(
                  isSelected: [
                    selectedUserType == 'Pind',
                    selectedUserType == 'User'
                  ],
                  onPressed: (index) {
                    setState(() {
                      selectedUserType = index == 0 ? 'Pind' : 'User';
                      usernameController.clear(); // clear on switch
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text("Pind"),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text("User"),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // ✅ Hint changes — backend field stays the same
                MyTextField(
                  controller: usernameController,
                  hintText: usernameHint,
                  obscureText: false,
                ),
                const SizedBox(height: 10),

                MyTextField(
                  controller: emailController,
                  hintText: "Email",
                  obscureText: false,
                ),
                const SizedBox(height: 10),

                MyTextField(
                  controller: phoneController,
                  hintText: "Phone Number",
                  obscureText: false,
                ),
                const SizedBox(height: 10),

                MyTextField(
                  controller: pwController,
                  hintText: "Password",
                  obscureText: true,
                ),
                const SizedBox(height: 10),

                MyTextField(
                  controller: confirmPwController,
                  hintText: "Confirm Password",
                  obscureText: true,
                ),

                if (selectedUserType == 'Pind') ...[
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: panchayatIdController,
                    hintText: "Panchayat ID",
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: blockController,
                    hintText: "Block Name",
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: cityController,
                    hintText: "City",
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: townController,
                    hintText: "Town / Village",
                    obscureText: false,
                  ),
                ],

                const SizedBox(height: 25),
                MyButton(
                  onTap: register,
                  text: "Register",
                ),

                const SizedBox(height: 10),
                const Text(
                  "After registering, verify your email to continue.\n"
                  "Check Spam or Promotions if needed.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 20),
                GestureDetector(
                  onTap: widget.onTap,
                  child: const Text("Back to Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}