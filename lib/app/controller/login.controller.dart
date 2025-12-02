import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/services/sharedprefs.dart';
import 'package:leaveflow/app/views/homepage.dart';
// import 'package:leaveflow/app/widgets/navigationbar.widget.dart';

class LoginController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  var showPassword = false.obs;

  void togglePasswordView() {
    showPassword.value = !showPassword.value;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  //ShowPassword function
  void showPasswordFunction() {
    showPassword.value = !showPassword.value;
  }

  void onLogin() async {
    try {
      // Sign in with Firebase
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (credential.user != null) {
        // Get ID token
        final token = await credential.user!.getIdToken();
        
        // Store token and user info in SharedPrefs
        await SharedPrefs.setLocalStorage('token', token ?? '');
        await SharedPrefs.setLocalStorage('user', credential.user!.email ?? '');

        // Clear controllers
        emailController.clear();
        passwordController.clear();

        // Navigate to home
        // Get.off(() => Navigationbar());
        Get.off(() => Homepage());
        Get.snackbar('Success', 'Login successful');
      }
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth Error: ${e.code} - ${e.message}');
      Get.snackbar('Login Failed', e.message ?? 'Authentication failed');
    } catch (e) {
      log('Login Error: $e');
      Get.snackbar('Error', 'An unexpected error occurred');
    }
  }
}