import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupController {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  final nameFocus = FocusNode();
  final usernameFocus = FocusNode();
  final emailFocus = FocusNode();
  final phoneFocus = FocusNode();
  final passwordFocus = FocusNode();

  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();

    nameFocus.dispose();
    usernameFocus.dispose();
    emailFocus.dispose();
    phoneFocus.dispose();
    passwordFocus.dispose();
  }

  // 🔒 Validation Methods
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username is required';
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) return 'Enter valid 10-digit phone number';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  // 🔐 Password Strength Helpers
  String getPasswordStrengthText() {
    final password = passwordController.text;
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Very Weak';
    if (password.length < 8) return 'Weak';
    if (!RegExp(r'(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~])').hasMatch(password)) {
      return 'Moderate';
    }
    return 'Strong';
  }

  Color getPasswordStrengthColor() {
    final strength = getPasswordStrengthText();
    switch (strength) {
      case 'Very Weak':
        return Colors.red;
      case 'Weak':
        return Colors.orange;
      case 'Moderate':
        return Colors.amber;
      case 'Strong':
        return Colors.green;
      default:
        return Colors.transparent;
    }
  }

  // 📩 Firebase Signup Method
  Future<String?> signUpUser() async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': nameController.text.trim(),
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'createdAt': Timestamp.now(),
        });

        // 📧 Send email verification
        if (!user.emailVerified) {
          await user.sendEmailVerification();
        }

        return null; // success
      }

      return "Unknown error occurred";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Something went wrong: $e";
    }
  }
}
