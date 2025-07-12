import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:varatalapp/controller/login_controller.dart';
import 'package:varatalapp/core/common/custom_button.dart';
import 'package:varatalapp/core/common/custom_text_field.dart';
import 'package:varatalapp/presentation/screen/signupscreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final LoginController controller = LoginController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    setState(() => _isLoading = true);

    final email = controller.emailController.text.trim();
    final password = controller.passwordController.text.trim();

    final error = await controller.loginUser(email, password);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Logged in successfully")),
      );
      Navigator.pushReplacementNamed(context, '/chatList');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Login failed: $error")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Text(
                  "Welcome to Vartalap",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Sign in to continue",
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  controller: controller.emailController,
                  focusNode: controller.emailFocus,
                  hintText: "Email",
                  validator: controller.validateEmail,
                  prefixIcon: const Icon(Icons.email_outlined),
                  onChanged: (_) {}, // ✅ Required by CustomTextField
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
                  onChanged: (_) {}, // ✅ Required by CustomTextField
                ),
                const SizedBox(height: 8),

                // ✅ Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Replace with your actual route
                      Navigator.pushNamed(context, '/forgotPassword');
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                CustomButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          if (_formKey.currentState?.validate() ?? false) {
                            handleLogin();
                          }
                        },
                  text: _isLoading ? "Logging in..." : "Login",
                ),
                const SizedBox(height: 20),
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account?  ",
                      style: TextStyle(color: Colors.grey[600]),
                      children: [
                        TextSpan(
                          text: "Sign up",
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
                                  builder: (context) => const SignupScreen(),
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
