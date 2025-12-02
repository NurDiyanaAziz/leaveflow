import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  }

  @override
  Widget build(BuildContext context) {
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