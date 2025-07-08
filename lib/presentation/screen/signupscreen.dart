import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:varatalapp/core/common/custom_button.dart';
import 'package:varatalapp/core/common/custom_text_field.dart';
import 'package:varatalapp/controller/signup_controller.dart';
import 'package:varatalapp/presentation/screen/loginscreen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final SignupController controller = SignupController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> signUp(String email, String password) async {
    setState(() => _isLoading = true);

    try {
      // Step 1: Create Auth user
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Step 2: Get current user UID
      User? user = FirebaseAuth.instance.currentUser;

      // Step 3: Save additional user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'uid': user.uid,
        'name': controller.nameController.text.trim(),
        'username': controller.usernameController.text.trim(),
        'email': controller.emailController.text.trim(),
        'phone': controller.phoneController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Account created successfully")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return "Please enter your full name";
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return "Please enter your username";
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Please enter your email";
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return "Invalid email address";
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Please enter your phone number";
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    if (!phoneRegex.hasMatch(value)) return "Invalid phone number";
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Please enter a password";
    if (value.length < 6) return "Password must be at least 6 characters";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create Account",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Please fill in the details to continue",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 30),

                CustomTextField(
                  controller: controller.nameController,
                  focusNode: controller.nameFocus,
                  hintText: "Full Name",
                  validator: _validateName,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: controller.usernameController,
                  focusNode: controller.usernameFocus,
                  hintText: "Username",
                  validator: _validateUsername,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: controller.emailController,
                  focusNode: controller.emailFocus,
                  hintText: "Email",
                  validator: _validateEmail,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: controller.phoneController,
                  focusNode: controller.phoneFocus,
                  hintText: "Phone Number",
                  validator: _validatePhone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: controller.passwordController,
                  focusNode: controller.passwordFocus,
                  hintText: "Password",
                  validator: _validatePassword,
                  obscureText: !_isPasswordVisible,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                CustomButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          if (_formKey.currentState?.validate() ?? false) {
                            signUp(
                              controller.emailController.text.trim(),
                              controller.passwordController.text.trim(),
                            );
                          }
                        },
                  text: _isLoading ? "Creating..." : "Create Account",
                ),
                const SizedBox(height: 20),

                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account?  ",
                      style: TextStyle(color: Colors.grey[600]),
                      children: [
                        TextSpan(
                          text: "Login",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
