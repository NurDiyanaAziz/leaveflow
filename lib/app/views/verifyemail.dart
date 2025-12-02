import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/views/wrapper.dart';

class Verifyemail extends StatefulWidget {
  const Verifyemail({super.key});

  @override
  State<Verifyemail> createState() => _VerifyemailState();
}

class _VerifyemailState extends State<Verifyemail> {
  @override
  void initState() {
    sendverifylink();
    super.initState();
  }

  //delay function to send verify link
  DateTime? _lastSent;

  void sendverifylink() async {
    final now = DateTime.now();
    if (_lastSent != null && now.difference(_lastSent!).inSeconds < 60) {
      Get.snackbar(
        'Please wait',
        'You can only resend the verification email once every minute.',
        margin: const EdgeInsets.all(30),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.offAll(() => const Wrapper());
      return;
    }
    
    try {
      _lastSent = now;
      await user.sendEmailVerification();
      Get.snackbar(
        'Verification Email Sent',
        'Please check your email for the verification link.',
        margin: const EdgeInsets.all(30),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to send verification email: $e');
    }
  }

  void reload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.offAll(() => const Wrapper());
      return;
    }
    
    try {
      await user.reload();
      if (mounted) {
        Get.offAll(() => const Wrapper());
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to reload user: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email_outlined, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Verify Your Email',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'A verification link has been sent to your email. Please click the link to verify your account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: reload,
                child: const Text('Already Verified? Refresh'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: sendverifylink,
                child: const Text('Resend Verification Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}