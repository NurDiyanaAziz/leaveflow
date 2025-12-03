import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/views/login.screen.dart';
import 'package:leaveflow/app/views/wrapper.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}


class _HomepageState extends State<Homepage> {

//to get all the details of the current user login
  final user = FirebaseAuth.instance.currentUser;

  void signout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Get.offAll(() => LoginScreen());
    }
  }

  @override
  void initState() {
    super.initState();
    // Safety check: if user is not verified, redirect to wrapper which will route to verification
    if (user != null && !user!.emailVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAll(() => const Wrapper());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Additional safety check in build
    if (user == null || !user!.emailVerified) {
      return const Scaffold(
        body: Center(child: Text('Please verify your email')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homepage'),
      ),
      body: Center(child: Text('${user!.email}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (()=>signout()),
        child: const Icon(Icons.logout),
      ),
    );
  }
}