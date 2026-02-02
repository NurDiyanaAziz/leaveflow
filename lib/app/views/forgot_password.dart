import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leaveflow/app/views/reset.password.screen.dart';
import 'dart:convert'; 

class ForgotPassword extends StatefulWidget {
  final String? email; // Add this line
  const ForgotPassword({super.key, this.email}); // Update constructor

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  
  bool isOtpSent = false; // Toggles the UI between Email and OTP mode
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  void initState() {
  super.initState();
  if (widget.email != null) {
    emailController.text = widget.email!; // Pre-fill the text box
  }
  }

  // 1. Send OTP Logic
  Future<void> requestOtp() async {
    setState(() => isLoading = true);

    try {
      // Use 10.0.2.2 for Android Emulator
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/users/request-otp'), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": emailController.text.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() => isOtpSent = true); // Switch UI to OTP mode
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'OTP Sent! Check your email.')),
        );
      } else {
        _showError(data['error'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      _showError('Connection Error: Is the server running?');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 2. Verify OTP Logic
  Future<void> verifyOtp() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/users/verify-otp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text.trim(),
          "otp": otpController.text.trim()
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verified! Redirecting...')),
        );
        
        // Navigate to the "New Password" Screen
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(email: emailController.text.trim())
          )
        );
      } else {
        _showError(data['error'] ?? 'Invalid Code');
      }
    } catch (e) {
      _showError('Connection Error');
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
    // Your custom blue color
    const customBlue = Color.fromARGB(255, 0, 78, 150);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Forgot Password', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView( // Added scrolling for smaller screens
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // HEADER TEXT
                Text(
                  isOtpSent ? 'ENTER CODE' : 'OH NO!',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: customBlue,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isOtpSent ? 'We sent a 6-digit code to your email.' : 'YOU FORGOT YOUR PASSWORD?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16, // Slightly smaller to fit description
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: customBlue,
                  ),
                ),
                
                const SizedBox(height: 30),

                // STEP 1: EMAIL INPUT
                if (!isOtpSent)
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Enter Email',
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

                // STEP 2: OTP INPUT
                if (isOtpSent)
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 5),
                    decoration: InputDecoration(
                      hintText: '000000',
                      counterText: "", // Hides the character counter below
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

                const SizedBox(height: 20),

                // MAIN ACTION BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading 
                      ? null 
                      : (isOtpSent ? verifyOtp : requestOtp),
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
                      : Text(
                          isOtpSent ? "Verify Code" : "Send Link",
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                  ),
                ),

                // CHANGE EMAIL BUTTON (Only show if OTP was sent)
                if (isOtpSent)
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          isOtpSent = false;
                          otpController.clear();
                        });
                      },
                      child: const Text("Change Email", style: TextStyle(color: Colors.grey)),
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