import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:leaveflow/app/services/sharedprefs.dart';
import 'package:leaveflow/app/views/login.screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifs = true;
  bool _darkMode = Get.isDarkMode;

  void _logout() async {
    // 1. Show Confirmation Dialog (Matches Homepage logic)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      await SharedPrefs.removeLocalStorage('token');
      await SharedPrefs.removeLocalStorage('role');
      await SharedPrefs.removeLocalStorage('name');
      await SharedPrefs.removeLocalStorage('uid');
      await SharedPrefs.removeLocalStorage('user');
      Get.offAll(() => LoginScreen());
    }
  }

  void _resetPassword() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      Get.snackbar(
        "Email Sent", 
        "Check your inbox to reset your password.",
        backgroundColor: Colors.white,
        colorText: Colors.black87,
        boxShadows: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // MATCHED
      appBar: AppBar(
        backgroundColor: Colors.white, // MATCHED
        elevation: 1,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- 1. ACCOUNT SETTINGS ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: _commonDecoration(),
              child: Column(
                children: [
                  _buildHeader("Account"),
                  _buildTile(Icons.lock_outline, "Change Password", onTap: _resetPassword),
                  _buildDivider(),
                  _buildSwitch(Icons.notifications_outlined, "Email Notifications", _emailNotifs, (val) => setState(() => _emailNotifs = val)),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // --- 2. APP SETTINGS ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: _commonDecoration(),
              child: Column(
                children: [
                  _buildHeader("Application"),
                  // _buildSwitch(
                  //     Icons.dark_mode_outlined, 
                  //     "Dark Mode", 
                  //     _darkMode, 
                  //     (val) {
                  //       setState(() => _darkMode = val); // Update the switch UI
                        
                  //       // THE MAGIC LINE: Actually switch the theme
                  //       Get.changeTheme(val ? ThemeData.dark() : ThemeData.light());
                  //     }
                  //   ),
                  //_buildDivider(),
                  _buildTile(Icons.info_outline, "About LeaveFlow", onTap: () {}),
                  _buildDivider(),
                  _buildTile(Icons.privacy_tip_outlined, "Privacy Policy", onTap: () {}),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 3. LOGOUT BUTTON (Red Styled) ---
            InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50], // Light red background
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Text(
                        "Log Out",
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            Text("Version 1.0.0", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // --- STYLING HELPERS ---

  BoxDecoration _commonDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.grey[700], size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildSwitch(IconData icon, String title, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.grey[700], size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: Switch(
        value: value,
        activeColor: Colors.blue[700],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 60);
  }
}