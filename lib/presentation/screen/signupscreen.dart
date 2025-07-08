import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:varatalapp/controller/signup_controller.dart';
import 'package:varatalapp/core/common/custom_button.dart';
import 'package:varatalapp/core/common/custom_text_field.dart';
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

  Future<void> handleSignup() async {
    setState(() => _isLoading = true);

    final error = await controller.signUpUser();
    setState(() => _isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("✅ Signup successful. Please verify your email.")),
      );

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Verify Your Email"),
          content: const Text(
              "A verification link has been sent to your email. Please verify it before logging in."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ $error")),
      );
    }
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
                  validator: controller.validateName,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  onChanged: (_) {}, // ✅ Required
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: controller.usernameController,
                  focusNode: controller.usernameFocus,
                  hintText: "Username",
                  validator: controller.validateUsername,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  onChanged: (_) {}, // ✅ Required
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: controller.emailController,
                  focusNode: controller.emailFocus,
                  hintText: "Email",
                  validator: controller.validateEmail,
                  prefixIcon: const Icon(Icons.email_outlined),
                  onChanged: (_) {}, // ✅ Required
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: controller.phoneController,
                  focusNode: controller.phoneFocus,
                  hintText: "Phone Number",
                  validator: controller.validatePhone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  onChanged: (_) {}, // ✅ Required
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: controller.passwordController,
                  focusNode: controller.passwordFocus,
                  hintText: "Password",
                  validator: controller.validatePassword,
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
                  onChanged: (_) => setState(() {}), // ✅ Required for strength checker
                ),
                const SizedBox(height: 4),

                // 👇 Password Strength Text
                Text(
                  controller.getPasswordStrengthText(),
                  style: TextStyle(
                    color: controller.getPasswordStrengthColor(),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 30),
                CustomButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          if (_formKey.currentState?.validate() ?? false) {
                            handleSignup();
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
