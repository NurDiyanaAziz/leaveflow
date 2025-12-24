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

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double firstContainerHeight = screenHeight * 0.35;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER CONTAINER ---
            Container(
              height: firstContainerHeight,
              width: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/login.png',
                        height: firstContainerHeight * 0.4,
                        width: MediaQuery.of(context).size.width * 0.45,
                        fit: BoxFit.contain,
                      ),
                      const Text(
                        'LEAVEFLOW',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Color.fromARGB(255, 0, 78, 150),
                        ),
                      ),
                      const Text(
                        'Leave Request Management System',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- FORM CONTAINER ---
            Transform.translate(
              offset: const Offset(0, -60),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(60),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 30,
                    left: 30,
                    right: 30,
                    bottom: 20,
                  ),
                  child: Form(
                    key: controller.signupFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Create an Account',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 78, 150),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- 1. FULL NAME ---
                        const Text(
                          "Full Name",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: controller.nameController,
                          decoration: _inputDecoration('Enter your full name'),
                          keyboardType: TextInputType.name,
                          validator: controller.validateName,
                        ),
                        const SizedBox(height: 20),

                        // --- 2. EMAIL ---
                        const Text(
                          "Email Address",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: controller.emailController,
                          decoration: _inputDecoration('example@email.com'),
                          keyboardType: TextInputType.emailAddress,
                          validator: controller.validateEmail,
                        ),
                        const SizedBox(height: 20),

                        // --- 3. PASSWORD ---
                        const Text(
                          "Password",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(
                          () => TextFormField(
                            controller: controller.passwordController,
                            decoration:
                                _inputDecoration(
                                  'Enter strong password',
                                ).copyWith(
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
                            validator: controller.validatePassword,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- 4. CONFIRM PASSWORD (NEW) ---
                        const Text(
                          "Confirm Password",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(
                          () => TextFormField(
                            controller: controller.confirmPasswordController,
                            decoration: _inputDecoration('Re-enter password'),
                            // It shares the same visibility toggle as the main password
                            obscureText: !controller.showPassword.value,
                            validator: controller.validateConfirmPassword,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // --- BUTTONS ---
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
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        Center(
                          child: TextButton(
                            onPressed: () => Get.back(),
                            child: const Text(
                              'Already have an account? Login',
                              style: TextStyle(
                                color: Color.fromARGB(255, 0, 78, 150),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to keep code clean
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
    );
  }
}
