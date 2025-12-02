import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:leaveflow/app/controller/login.controller.dart';
import 'package:leaveflow/app/views/wrapper.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {

  // final LoginController controller = Get.put(LoginController());
  
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void signUp() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      Get.offAll(Wrapper());
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Sign Up Error', e.message ?? 'Authentication failed', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Sign Up Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(hintText: 'Enter Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(hintText: 'Enter Password'),
              obscureText: true,
            ),
            ElevatedButton(onPressed: (()=>signUp()), child: Text("Sign Up"))
          ],
        ),
      ),
    //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    //   body: Center(
    //     child: Card(
    //       margin: EdgeInsets.all(32),
    //       child: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           Container(
    //             margin: EdgeInsets.symmetric(vertical: 32),
    //             width: MediaQuery.of(context).size.width,
    //             child: Text(
    //               'SignUp',
    //               textAlign: TextAlign.center,
    //               style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
    //             ),
    //           ),
    //           Padding(
    //             padding: EdgeInsetsGeometry.symmetric(
    //               horizontal: 16,
    //               vertical: 8,
    //             ),
    //             child: TextField(
    //               controller: controller.emailController,
    //               decoration: InputDecoration(
    //                 border: OutlineInputBorder(),
    //                 label: Text('Email'),
    //                 hintText: 'Please enter your email',
    //               ),
    //             ),
    //           ),
    //           Padding(
    //             padding: EdgeInsetsGeometry.symmetric(
    //               horizontal: 16,
    //               vertical: 8,
    //             ),
    //             child: Obx(//function utk tukar 
    //               () => TextField(
    //                 controller: controller.passwordController,
    //                 decoration: InputDecoration(
    //                   border: OutlineInputBorder(),
    //                   label: Text('Password'),
    //                   hintText: 'Please enter your Password',
    //                   suffixIcon: IconButton(
    //                     onPressed: controller.togglePasswordView,
    //                     icon: Icon(
    //                       controller.showPassword.value
    //                           ? Icons.visibility_off
    //                           : Icons.visibility,
    //                     ),
    //                   ),
    //                 ),
    //                 keyboardType: TextInputType.visiblePassword,
    //                 obscureText: controller.showPassword.value,
    //               ),
    //             ),
    //           ),
    //           Padding(
    //             padding: const EdgeInsetsGeometry.symmetric(
    //               horizontal: 16,
    //               vertical: 8,
    //             ),
    //             child: ElevatedButton(onPressed: controller.onLogin, child: Text('Login')),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    );
  }
}