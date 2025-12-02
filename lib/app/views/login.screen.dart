import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/controller/login.controller.dart';
import 'package:leaveflow/app/views/forgot_password.dart';
import 'package:leaveflow/app/views/signup.dart';
// import 'package:leaveflow/app/views/forgot_password.dart';
// import 'package:leaveflow/app/views/signup.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: controller.emailController,
              decoration: const InputDecoration(hintText: 'Enter Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            Obx(
              () => TextField(
                controller: controller.passwordController,
                decoration: InputDecoration(
                  hintText: 'Enter Password',
                  suffixIcon: IconButton(
                    onPressed: controller.togglePasswordView,
                    icon: Icon(controller.showPassword.value ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
                obscureText: controller.showPassword.value,
                keyboardType: TextInputType.visiblePassword,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: controller.onLogin, child: const Text("Login")),
            ElevatedButton(onPressed: (() => Get.to(() => const Signup())), child: const Text("Register Now!")),
            ElevatedButton(onPressed: (() => Get.to(() => const ForgotPassword())), child: const Text("Forgot Password?")),
          ],
        ),
      ),
    );
  }
}
