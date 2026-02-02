import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leaveflow/app/views/login.screen.dart';
import 'dart:convert';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  
  bool isLoading = false;
  bool _obscureText = true; // For toggling password visibility

  @override
  void dispose() {
    passController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  Future<void> submitNewPassword() async {
    // 1. Client-Side Validation
    if (passController.text.trim().isEmpty) {
      _showError("Password cannot be empty");
      return;
    }
    if (passController.text != confirmPassController.text) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    try {
      // 2. API Call
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/users/reset-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "newPassword": passController.text.trim()
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        
        // Success Message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password updated! Please Login."),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to Login and remove history
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => LoginScreen()), 
          (route) => false
        );
      } else {
        _showError(data['error'] ?? "Failed to reset");
      }
    } catch (e) {
      _showError("Connection Error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Your Custom Brand Color
    const customBlue = Color.fromARGB(255, 0, 78, 150);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('New Password', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // HEADER
                const Text(
                  'RESET NOW',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: customBlue,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Create a new strong password.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),

                // PASSWORD FIELD
                TextField(
                  controller: passController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15, horizontal: 15,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // CONFIRM PASSWORD FIELD
                TextField(
                  controller: confirmPassController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15, horizontal: 15,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // UPDATE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submitNewPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: customBlue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text(
                          "Update Password",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}