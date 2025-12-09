
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:leaveflow/app/services/api.service.dart';
import 'package:leaveflow/app/views/wrapper.dart';

class SignupController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiServices api = ApiServices();
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


  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Requires at least one uppercase letter.';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Requires at least one lowercase letter.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Requires at least one number.';
    }
    return null; // Validation passed
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required.';
    }
    // Simple email format check
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full Name is required.';
    }
    if (value.length < 3) {
      return 'Name must be at least 3 characters.';
    }
    return null;
  }

  void signUp() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return; // Stop if the form is not ready or validation fails
    }

    final String name = nameController.text.trim();
    final String email = emailController.text.trim();

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email,
            password: passwordController.text,
          );

      User? user = userCredential.user;

      if (user != null) {
        // 1. Update Firebase profile with the actual user's name
        await user.updateDisplayName(name);

        await user.sendEmailVerification();

        // STEP B: MySQL Database Registration
        // Use the new api.postJson method
        Response? response = await api.postJson('/users/register_mysql', {
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': 'Employee',
        });

        Get.back();

        if (response != null && response.statusCode == 201) {
          // Success in both Firebase and MySQL
          Get.offAll(() => const Wrapper());
        } else {
          // CRITICAL ERROR: MySQL record failed. Clean up Firebase account.
          // Check for a non-201 status code
          String errorBody =
              response?.data?.toString() ??
              'Unknown error during MySQL registration.';
          Get.snackbar(
            'Setup Failed',
            'Database setup failed. Error: $errorBody',
            snackPosition: SnackPosition.BOTTOM,
          );
          // Attempt to delete user from Firebase to prevent partial registration
          await user.delete();
        }
      }
    } on FirebaseAuthException catch (e) {
      // Display specific Firebase errors
      Get.snackbar(
        'Sign Up Error',
        e.message ?? 'Authentication failed',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on DioException catch (e) {
      // Handle network or Dio specific errors
      Get.snackbar(
        'Network Error',
        e.response?.data?.toString() ?? 'Cannot reach server.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Sign Up Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
