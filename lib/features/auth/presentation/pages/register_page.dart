import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart'; // kIsWeb

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
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();
  final townController = TextEditingController();
  final otpController = TextEditingController();

  // ================= STATE =================
  String selectedUserType = 'Sarpanch';
  bool isOtpSent = false;

  // ================= OTP HANDLES =================
  dynamic webConfirmationResult;     // Web
  String mobileVerificationId = "";  // Android / iOS

  @override
  void dispose() {
    emailController.dispose();
    pwController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    cityController.dispose();
    townController.dispose();
    otpController.dispose();
    super.dispose();
  }

  // ================= STEP 1: REGISTER / SEND OTP =================
  void onRegisterTapped() async {
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        pwController.text.isEmpty) {
      _showError("Please fill all basic details");
      return;
    }

    if (selectedUserType == 'Sarpanch') {
      if (phoneController.text.isEmpty ||
          cityController.text.isEmpty ||
          townController.text.isEmpty) {
        _showError("Phone, City, and Town are required for Sarpanch");
        return;
      }

      try {
        final result = await context
            .read<AuthCubit>()
            .authRepo
            .sendOtp(phoneController.text);

        setState(() {
          if (kIsWeb) {
            webConfirmationResult = result;
          } else {
            mobileVerificationId = result;
          }
          isOtpSent = true;
        });
      } catch (e) {
        _showError(e.toString());
      }
    } else {
      // ✅ SUPPORTER REGISTRATION (NO OTP)
      context.read<AuthCubit>().registerSimple(
            email: emailController.text,
            password: pwController.text,
            username: usernameController.text,
          );
    }
  }

  // ================= STEP 2: VERIFY OTP =================
  void verifySarpanch() {
    if (otpController.text.isEmpty) {
      _showError("Please enter OTP");
      return;
    }

    context.read<AuthCubit>().registerSarpanchVerified(
          email: emailController.text,
          password: pwController.text,
          username: usernameController.text,
          phone: phoneController.text,
          city: cityController.text,
          town: townController.text,
          otp: otpController.text,
          webResult: webConfirmationResult,
          vId: mobileVerificationId,
        );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
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

                // ================= FORM =================
                if (!isOtpSent) ...[
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
                    hintText: "Password",
                    obscureText: true,
                  ),

                  if (selectedUserType == 'Sarpanch') ...[
                    const SizedBox(height: 10),
                    MyTextField(
                      controller: phoneController,
                      hintText: "10-Digit Mobile Number",
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
                      hintText: "Town / Village",
                      obscureText: false,
                    ),
                  ],

                  const SizedBox(height: 25),
                  MyButton(
                    onTap: onRegisterTapped,
                    text: selectedUserType == 'Sarpanch'
                        ? "Verify Mobile (OTP)"
                        : "Register",
                  ),
                ],

                // ================= OTP =================
                if (isOtpSent) ...[
                  const Text("Enter the OTP sent to your phone"),
                  const SizedBox(height: 15),
                  MyTextField(
                    controller: otpController,
                    hintText: "6-Digit OTP",
                    obscureText: false,
                  ),
                  const SizedBox(height: 20),
                  MyButton(
                    onTap: verifySarpanch,
                    text: "Complete Registration",
                  ),
                  TextButton(
                    onPressed: () => setState(() => isOtpSent = false),
                    child: const Text("Go Back"),
                  ),
                ],

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
