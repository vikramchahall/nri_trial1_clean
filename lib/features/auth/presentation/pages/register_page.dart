import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/auth_cubit.dart';
import '../cubits/auth_states.dart';
import '../../../../components/my_button.dart';
import '../../../../components/my_text_field.dart';

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

  // ================= STATE =================
  String selectedUserType = 'Sarpanch';

  @override
  void dispose() {
    emailController.dispose();
    pwController.dispose();
    confirmPwController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    cityController.dispose();
    townController.dispose();
    blockController.dispose();
    panchayatIdController.dispose();
    super.dispose();
  }

  // ================= REGISTER =================
  void onRegisterTapped() {
    final pw = pwController.text;
    final cpw = confirmPwController.text;

    if (pw != cpw) {
      _showError("Passwords do not match!");
      return;
    }

    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        pw.isEmpty) {
      _showError("Please fill all basic details");
      return;
    }

    if (selectedUserType == 'Sarpanch') {
      if (phoneController.text.isEmpty ||
          panchayatIdController.text.isEmpty) {
        _showError("Phone and Panchayat ID are mandatory for Sarpanch");
        return;
      }
    }

    // 🔥 SINGLE REGISTRATION CALL
    context.read<AuthCubit>().registerWithoutOtp(
          email: emailController.text,
          password: pw,
          username: usernameController.text,
          phone: phoneController.text,
          city: cityController.text,
          town: townController.text,
          blockName: blockController.text,
          panchayatId: panchayatIdController.text,
          userType: selectedUserType,
        );
  }

  void _showError(String msg) {
    final cleanMsg = msg.replaceAll("Exception: ", "");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(cleanMsg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                const Icon(Icons.account_balance,
                    size: 60, color: Colors.green),
                const SizedBox(height: 20),
                const Text(
                  "CREATE ACCOUNT",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 25),

                ToggleButtons(
                  isSelected: [
                    selectedUserType == 'Sarpanch',
                    selectedUserType == 'Supporter'
                  ],
                  onPressed: (index) {
                    setState(() {
                      selectedUserType =
                          index == 0 ? 'Sarpanch' : 'Supporter';
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text("Sarpanch"),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text("Supporter"),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                MyTextField(
                  controller: usernameController,
                  hintText: "Unique Username",
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
                  controller: pwController,
                  hintText: "Create Password",
                  obscureText: true,
                ),
                const SizedBox(height: 10),

                MyTextField(
                  controller: confirmPwController,
                  hintText: "Confirm Password",
                  obscureText: true,
                ),

                if (selectedUserType == 'Sarpanch') ...[
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: phoneController,
                    hintText: "Phone Number",
                    obscureText: false,
                  ),
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
                    hintText: "City / District",
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: townController,
                    hintText: "Village Name",
                    obscureText: false,
                  ),
                ],

                const SizedBox(height: 25),
                MyButton(
                  onTap: onRegisterTapped,
                  text: "Register",
                ),

                const SizedBox(height: 20),
                GestureDetector(
                  onTap: widget.onTap,
                  child: const Text("Already a member? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
