import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/services/api.service.dart';
import 'package:leaveflow/app/services/sharedprefs.dart';
//import 'package:leaveflow/app/views/homepage.dart';
import 'package:leaveflow/app/views/login.screen.dart';
// import 'package:leaveflow/app/widgets/navigationbar.widget.dart';
import 'package:leaveflow/app/views/employee.screen.dart';

class LoginController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  var showPassword = true.obs;

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

  Future<void> clearSession() async {
    await FirebaseAuth.instance.signOut();
    await SharedPrefs.removeLocalStorage('token');
    await SharedPrefs.removeLocalStorage('user');
    await SharedPrefs.removeLocalStorage('role'); // Added
    await SharedPrefs.removeLocalStorage('name'); // Added
    await SharedPrefs.removeLocalStorage('uid');  // Added
  }

  void onLogin() async {
    try {
      // Sign in with Firebase
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (credential.user != null) {
        // Ensure latest user state (emailVerified may be updated)
        await FirebaseAuth.instance.currentUser?.reload();
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          Get.snackbar(
            'Error',
            'User not found after sign-in.',
            duration: const Duration(seconds: 5),
          );
          return;
        }

        log('User email: ${user.email}, emailVerified: ${user.emailVerified}');
        if (user.emailVerified) {
          // Get ID token
          final token = await user.getIdToken();

          // Store token and user info in SharedPrefs
          await SharedPrefs.setLocalStorage('token', token ?? '');
          await SharedPrefs.setLocalStorage('user', user.email ?? '');

          try {
            print("Fetching user role from MySQL...");

            print("--------------------------------------------------");
            print("LOGGING IN...");
            print("Flutter sends UID: ${user.uid}"); 
            print("--------------------------------------------------");
            
            var response = await api.postJson('/users/login_details', {
              'uid': user.uid,
            });

            if (response != null && response.statusCode == 200) {
              // 1. Extract Role & Name from Database
              String role = response.data['role']; // "Manager" or "Employee"
              String name = response.data['name'];

              // 2. Save to Local Storage for usage in other screens
              await SharedPrefs.setLocalStorage('role', role);
              await SharedPrefs.setLocalStorage('name', name);
              await SharedPrefs.setLocalStorage('uid', user.uid);

              // 3. Clear controllers
              emailController.clear();
              passwordController.clear();

              // 4. Navigate based on Role
              Get.snackbar('Success', 'Welcome back, $name ($role)');

              if (role == 'Manager') {
                // TODO: Point this to ManagerScreen() when you build it
                // Get.off(() => const ManagerScreen()); 
                Get.off(() => const EmployeeScreen()); // For now, use EmployeeScreen
              } else {
                Get.off(() => const EmployeeScreen());
              }
            } else {
               // Critical Error: User exists in Firebase but NOT in MySQL
               Get.snackbar("Database Error", "User profile not found in database."); 
               await clearSession();
            }
          } catch (e) {
            print("API Error: $e");
            Get.snackbar("Connection Error", "Could not connect to server.");
          }
        } else {
          // User not verified: attempt to send verification email (with cooldown)
          try {
            // Check cooldown stored in SharedPrefs
            final lastSentIso = await SharedPrefs.getLocalStorage(
              'last_verify_sent',
            );
            DateTime? lastSent;
            if (lastSentIso != null && lastSentIso.isNotEmpty) {
              lastSent = DateTime.tryParse(lastSentIso);
            }

            final now = DateTime.now();
            final canSend =
                lastSent == null || now.difference(lastSent).inSeconds >= 120;

            if (canSend) {
              await user.sendEmailVerification();
              await SharedPrefs.setLocalStorage(
                'last_verify_sent',
                now.toIso8601String(),
              );
              Get.snackbar(
                'Verification Email Sent',
                'Please check your email for the verification link.',
                duration: const Duration(seconds: 15),
              );
            } else {
              final DateTime last = lastSent;
              final wait = 120 - now.difference(last).inSeconds;
              Get.snackbar(
                'Please wait',
                'You can resend verification email in $wait seconds.',
                duration: const Duration(seconds: 15),
              );
            }
          } catch (e) {
            Get.snackbar(
              'Error',
              'Failed to send verification email: $e',
              duration: const Duration(seconds: 15),
            );
          }

          // Sign the user out to prevent unverified access
          await clearSession();

          // Send user back to login screen
          Get.offAll(() => LoginScreen());
        }
      }
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth Error: ${e.code} - ${e.message}');
      Get.snackbar(
        'Login Failed',
        e.message ?? 'Authentication failed',
        duration: const Duration(seconds: 15),
      );
    } catch (e) {
      log('Login Error: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        duration: const Duration(seconds: 15),
      );
    }
  }
}  