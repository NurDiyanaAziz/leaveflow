
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/views/wrapper.dart';

class SignupController extends GetxController{
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  var showPassword = false.obs;

  void togglePasswordView() {
    showPassword.value = !showPassword.value;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void visiblePasswordFunction() {
    showPassword.value = !showPassword.value;
  }

// void signUp() async {
//     try {
//       await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: emailController.text.trim(),
//         password: passwordController.text,
//       );
//       Get.offAll(Wrapper());
//     } on FirebaseAuthException catch (e) {
//       Get.snackbar('Sign Up Error', e.message ?? 'Authentication failed', snackPosition: SnackPosition.BOTTOM);
//     } catch (e) {
//       Get.snackbar('Sign Up Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
//     }
//   }

  void onSignUp() async {
    try {
      // Sign up with Firebase
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (credential.user != null) {
        // Ensure latest user state
        await FirebaseAuth.instance.currentUser?.reload();
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          Get.snackbar(
            'Error',
            'User not found after sign-up.',
            duration: const Duration(seconds: 5),
          );
          return;
        }

        log('User email: ${user.email}, emailVerified: ${user.emailVerified}');
        if (user.emailVerified) {
          Get.offAll(Wrapper());
        } else {
          Get.snackbar(
            'Verification Required',
            'Please verify your email before logging in.',
            duration: const Duration(seconds: 5),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Sign Up Error',
        e.message ?? 'Authentication failed',
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      Get.snackbar(
        'Sign Up Error',
        e.toString(),
        duration: const Duration(seconds: 5),
      );
    }
  }
}