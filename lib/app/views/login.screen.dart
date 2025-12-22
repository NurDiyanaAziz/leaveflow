import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/controller/login.controller.dart';
import 'package:leaveflow/app/views/signup.dart';
// import 'package:leaveflow/app/views/forgot_password.dart';
// import 'package:leaveflow/app/views/signup.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    //get screen size
    final double screenHeight = MediaQuery.of(context).size.height;
    //set half screen height
    final double containerHeight = screenHeight * 0.5;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            //first container with image
            Container(
              height: containerHeight,
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
                        height: containerHeight * 0.6,
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
              height: containerHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      'Sign in to continue',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    //textfield email
                    TextField(
                      controller: controller.emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter Email',
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
                    ),
                    const SizedBox(height: 10),
                    //textfield password
                    Obx(
                      () => TextField(
                        controller: controller.passwordController,
                        decoration: InputDecoration(
                          hintText: 'Enter Password',
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
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        obscureText: controller.showPassword.value,
                        keyboardType: TextInputType.visiblePassword,
                      ),
                    ),
                    const SizedBox(height: 30),
                    //login button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.onLogin,
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
                          "Login",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    //register button & forgot password button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            controller.clearForm(); // ✅ clear inputs
                            Get.to(() => const Signup());
                          },
                          // onPressed: (() => Get.to(() => const Signup())),
                          child: const Text(
                            "Register Now!",
                            style: TextStyle(
                              // fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            controller.clearForm(); // ✅ clear inputs
                            Get.to(() => const Signup());
                          },
                          // onPressed: (() => Get.to(() => const ForgotPassword())),
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              // fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
