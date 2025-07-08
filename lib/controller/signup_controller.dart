import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  get validateName => null;

  get validateUsername => null;

  get validateEmail => null;

  get validatePhone => null;

  get validatePassword => null;

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

        // 🔐 Send email verification
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
