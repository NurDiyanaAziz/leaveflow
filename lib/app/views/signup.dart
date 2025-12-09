
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/controller/signup.controller.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final SignupController controller = Get.put(SignupController());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    //get screen size
    final double screenHeight = MediaQuery.of(context).size.height;
    //set half screen height
    final double firstContainerHeight = screenHeight * 0.4;
    final double secondContainerHeight = screenHeight * 0.6;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            //first container with image
            Container(
              height: firstContainerHeight,
              width: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/login.png',
                        height: firstContainerHeight * 0.6,
                        fit: BoxFit.contain,
                      ),
                      // const SizedBox(height: 5),
                      const Text(
                        'LEAVEFLOW',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Color.fromARGB(255, 0, 78, 150),
                        ),
                      ),
                      //subtitle
                      const Text(
                        'Leave Request Management System',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            //second layer with textfields and buttons
            Container(
              height: secondContainerHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(60),
                  // topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: const Offset(0, -3), // changes position of shadow
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 20,
                  left: 30,
                  right: 30,
                  bottom: 20,
                ),
                //form fields
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: controller.nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter Full Name',
                          labelText: 'Full Name',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 15,
                          ),
                        ),
                        keyboardType: TextInputType.name,
                        validator: controller.validateName,
                      ),
                      TextFormField(
                        controller: controller.emailController,
                        decoration: InputDecoration(
                          hintText: 'Enter Email',
                          labelText: 'Email',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 15,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: controller.validateEmail,
                      ),
                      TextFormField(
                        controller: controller.passwordController,
                        decoration: InputDecoration(
                          hintText: 'Enter Password',
                          labelText: 'Password',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 15,
                          ),
                          suffixIcon: IconButton(
                            onPressed: controller.togglePasswordView,
                            icon: Icon(
                              controller.showPassword.value
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        obscureText: !controller.showPassword.value,
                        validator: controller
                            .validatePassword, // Apply strong validation
                      ),
                      const SizedBox(height: 30),
                      //signup button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              0,
                              78,
                              150,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      //navigate to login screen
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                          },
                          child: const Text(
                            'Already have an account? Login',
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 78, 150),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
