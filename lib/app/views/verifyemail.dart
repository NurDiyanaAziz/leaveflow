import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/views/wrapper.dart';
import 'package:leaveflow/app/views/homepage.dart';

class Verifyemail extends StatefulWidget {
  const Verifyemail({super.key});

  @override
  State<Verifyemail> createState() => _VerifyemailState();
}

class _VerifyemailState extends State<Verifyemail> {
  // --- Timer Variables ---
  Timer? _timer;
  bool _isTimerActive = false;
  int _countdown = 0;

  //delay function to send verify link
  DateTime? _lastSent;

  @override
  void initState() {
    //sendverifylink(); // The email was sent during the signup process (the first request).
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  //to start 2 minutes(120 seconds) timer for resend verify link
  void _startTimer() {
    _timer?.cancel(); // stop any existing timer

    _countdown = 120;
    _isTimerActive = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _isTimerActive = false;
          timer.cancel();
        }
      });
    });
  }

  void sendverifylink() async {
    final now = DateTime.now();
    // if (_lastSent != null && now.difference(_lastSent!).inSeconds < 120) {
    if (_isTimerActive) {
      if (_lastSent != null && now.difference(_lastSent!).inSeconds < 120) {
        Get.snackbar(
          'Please wait',
          'You can only resend the verification email once every 2 minute.',
          duration: const Duration(seconds: 5),
          margin: const EdgeInsets.all(30),
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.offAll(() => const Wrapper());
      return;
    }

    try {
      await user.sendEmailVerification();
      _lastSent = now;
      _startTimer();
      Get.snackbar(
        'Verification Email Sent',
        'Please check your email for the verification link.',
        margin: const EdgeInsets.all(30),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send verification email: $e',
        duration: const Duration(seconds: 5),
      );
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
      // get refreshed user instance
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser != null && refreshedUser.emailVerified) {
        // Email verified — navigate to home
        Get.offAll(() => const Homepage());
      } else {
        Get.snackbar(
          'Unverified Email',
          'Email is still not verified. Please check your inbox.',
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reload user: $e',
        duration: const Duration(seconds: 5),
      );
    }
  }

  //format seconds to mm:ss
  String formatCountdown(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingsecs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingsecs';
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
              //resend button with timer
              Column(
                children: [
                  ElevatedButton(
                    //disable button if timer is active
                    onPressed: _isTimerActive ? null : sendverifylink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTimerActive ? Colors.grey : Colors.green.shade400,
                    ),
                    child: const Text('Resend Verification Email'),
                  ),
                  const SizedBox(height: 5),
                  if (_isTimerActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Resend available in: ${formatCountdown(_countdown)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    const Text('Resend available now',
                        style: TextStyle(color: Colors.green))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
