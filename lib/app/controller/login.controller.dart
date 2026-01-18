import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 👇 Import this
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/services/api.service.dart';
import 'package:leaveflow/app/services/sharedprefs.dart';
import 'package:leaveflow/app/views/login.screen.dart';
import 'package:leaveflow/app/views/employee.screen.dart';

class LoginController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  var showPassword = true.obs;

  void togglePasswordView() => showPassword.value = !showPassword.value;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------
  // 👇 UPDATED: Remove FCM Token from DB before logging out
  // ---------------------------------------------------------
  Future<void> clearSession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Tell backend to delete this device's token
        // This prevents notifications from going to the wrong user if devices are shared
        await api.postJson('/users/remove-fcm', {
          'uid': user.uid, 
        });
      }
    } catch (e) {
      log("Error removing FCM token: $e");
    }

    await FirebaseAuth.instance.signOut();
    await SharedPrefs.removeLocalStorage('token');
    await SharedPrefs.removeLocalStorage('user');
    await SharedPrefs.removeLocalStorage('role');
    await SharedPrefs.removeLocalStorage('name');
    await SharedPrefs.removeLocalStorage('uid');
  }

  void onLogin() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (credential.user != null) {
        await FirebaseAuth.instance.currentUser?.reload();
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          Get.snackbar('Error', 'User not found after sign-in.');
          return;
        }

        if (user.emailVerified) {
          final token = await user.getIdToken();
          await SharedPrefs.setLocalStorage('token', token ?? '');
          await SharedPrefs.setLocalStorage('user', user.email ?? '');

          try {
            // ---------------------------------------------------------
            // 👇 NEW: Save FCM Token to Database immediately on Login
            // ---------------------------------------------------------
            String? fcmToken = await FirebaseMessaging.instance.getToken();
            if (fcmToken != null) {
              print("📲 Updating FCM Token for user: ${user.uid}");
              // We send this separately to ensure it updates even if login_details logic changes
              await api.postJson('/users/update-fcm', {
                'uid': user.uid,
                'fcm_token': fcmToken,
              });
            }

            // Continue with standard login flow...
            var response = await api.postJson('/users/login_details', {
              'uid': user.uid,
            });

            if (response != null && response.statusCode == 200) {
              String role = response.data['role'];
              String name = response.data['name'];

              await SharedPrefs.setLocalStorage('role', role);
              await SharedPrefs.setLocalStorage('name', name);
              await SharedPrefs.setLocalStorage('uid', user.uid);

              emailController.clear();
              passwordController.clear();

              Get.snackbar('Success', 'Welcome back, $name ($role)');

              if (role == 'Manager') {
                 // Get.off(() => const ManagerScreen()); 
                 Get.off(() => const EmployeeScreen()); 
              } else {
                Get.off(() => const EmployeeScreen());
              }
            } else {
               Get.snackbar("Database Error", "User profile not found in database."); 
               await clearSession();
            }
          } catch (e) {
            print("API Error: $e");
            Get.snackbar("Connection Error", "Could not connect to server.");
          }
        } else {
          // ... (Existing Email Verification Logic - Unchanged) ...
          _handleVerificationLogic(user); // Extracted for cleaner code below
        }
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Login Failed', e.message ?? 'Authentication failed');
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred');
    }
  }

  // Helper to keep onLogin clean (Paste your existing verification logic here)
  void _handleVerificationLogic(User user) async {
      try {
        final lastSentIso = await SharedPrefs.getLocalStorage('last_verify_sent');
        DateTime? lastSent;
        if (lastSentIso != null && lastSentIso.isNotEmpty) {
            lastSent = DateTime.tryParse(lastSentIso);
        }
        final now = DateTime.now();
        final canSend = lastSent == null || now.difference(lastSent).inSeconds >= 120;

        if (canSend) {
            await user.sendEmailVerification();
            await SharedPrefs.setLocalStorage('last_verify_sent', now.toIso8601String());
            Get.snackbar('Verification Sent', 'Check your email.');
        } else {
            Get.snackbar('Please wait', 'Cooldown active.');
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to send email.');
      }
      await clearSession();
      Get.offAll(() => LoginScreen());
  }
}