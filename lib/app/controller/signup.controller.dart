import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:leaveflow/app/services/api.service.dart';
import 'package:leaveflow/app/views/wrapper.dart';

class SignupController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

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
    confirmPasswordController.dispose();
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

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  void signUp() async {
    if (signupFormKey.currentState == null || !signupFormKey.currentState!.validate()) {
      return; // Stop if the form is not ready or validation fails
    }

    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text;

    // Show loading dialog
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    print("--- SIGNUP STARTING ---"); // DEBUG LOG

    try {
      // 1. Attempt Firebase Creation
      print("1. Contacting Firebase...");
      //firebase registration
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        print("2. Firebase Success! UID: ${user.uid}");
        
        await user.updateDisplayName(name);
        // await user.sendEmailVerification(); // Comment this out for testing speed if you want

        // 2. Attempt MySQL Creation
        print("3. Contacting MySQL Backend...");
        
        // Note: Make sure your ApiServices path starts with /users if your server.js uses /api
        // Based on your code: url = baseUrl + path
        // url = "http://10.0.2.2:3000/api" + "/users/register_mysql" 

        // STEP B: MySQL Database Registration
        // Use the new api.postJson method
        Response? response = await api.postJson('/users/register_mysql', {
          'id': user.uid,
          'name': name,
          'email': email,
          'role': 'Employee',
        });

        // Close the Loading Dialog
        if (Get.isDialogOpen!) Get.back();

        if (response != null &&
            (response.statusCode == 201 || response.statusCode == 200)) {
          //clear textfield
          nameController.clear();
          emailController.clear();
          passwordController.clear();

          print("4. MySQL Success! Redirecting...");

          Get.offAll(() => const Wrapper());
        } else {
          // CRITICAL ERROR: MySQL record failed. Clean up Firebase account.
          // Check for a non-201 status code
          String errorBody =
              response?.data?['message'] ??
              response?.statusMessage ??
              "Unknown Error";

              // CRITICAL ERROR LOGGING
          print("!!! MySQL FAILED !!!");
          print("Status Code: ${response?.statusCode}");
          print("Error Message: ${response?.data}");

          Get.snackbar('Setup Failed', 'Database setup failed.');
          
          // Cleanup: Delete the Firebase user so we don't get stuck in "Zombie" mode
          print("5. Cleaning up Firebase user...");
          //clean firebase
          await user.delete();

          Get.snackbar(
            'Database Sync Failed',
            'Account removed from Firebase because MySQL failed. Error: $errorBody',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Display specific Firebase errors
      if (Get.isDialogOpen!) Get.back();

      print("!!! FIREBASE ERROR !!!: ${e.code}"); // This will tell us if email is duplicate
      Get.snackbar(
        'Sign Up Error',
        e.message ?? 'Authentication failed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } on DioException catch (e) {
      // Handle network or Dio specific errors
      Get.snackbar(
        'Network Error',
        e.response?.data?.toString() ?? 'Cannot reach server.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      print("!!! UNKNOWN ERROR !!!: $e");
      Get.snackbar(
        'Sign Up Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
