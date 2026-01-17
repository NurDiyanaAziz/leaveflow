import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:leaveflow/app/views/employee.screen.dart';
import 'package:leaveflow/app/views/homepage.dart';
import 'package:leaveflow/app/views/login.screen.dart';
import 'package:leaveflow/app/views/verifyemail.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            //if snapshot got data it will redirect to home screen
            if (snapshot.data!.emailVerified) {
              return EmployeeScreen(); //home screen
            } else {
              return Verifyemail();
            }
          } else {
            //if snapshot has no data it will redirect to login screen
            return LoginScreen(); //login screen
          }
        },
      ),
    );
  }
}
