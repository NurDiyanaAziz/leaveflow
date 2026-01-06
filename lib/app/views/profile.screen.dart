import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/controller/profile.controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final ProfileController controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 1,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.blue[700]),
            onPressed: controller.updateProfile,
            tooltip: 'Save',
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        var user = controller.userProfile;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- 1. HEADER CARD (Avatar + Name) ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: _commonDecoration(), 
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue[50],
                      child: Text(
                        (user['name'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(fontSize: 30, color: Colors.blue[700], fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user['name'] ?? 'Loading...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900], 
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['position'] ?? 'Employee',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),

              // --- 2. EMPLOYMENT DETAILS (Read Only) ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _commonDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Employment Details'),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.work_outline, 'Department', user['department'] ?? 'General'),
                    _buildDivider(),
                    _buildInfoRow(Icons.supervisor_account_outlined, 'Reports To', user['manager_name'] ?? 'None'),
                    _buildDivider(),
                    _buildInfoRow(Icons.email_outlined, 'Email', user['email'] ?? ''),
                    _buildDivider(),
                    _buildInfoRow(Icons.calendar_today_outlined, 'Joined', _formatDate(user['joined_at'])),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- 3. EDITABLE CONTACT INFO ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _commonDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle('Contact Details'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("Editable", style: TextStyle(fontSize: 10, color: Colors.blue[700], fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone Input
                    _buildLabel('Phone Number'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.phoneController,
                      decoration: _inputDecoration(Icons.phone_outlined),
                    ),

                    const SizedBox(height: 16),

                    // Address Input
                    _buildLabel('Home Address'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.addressController,
                      decoration: _inputDecoration(Icons.home_outlined),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 20),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  // --- STYLING HELPERS (Matching Homepage) ---

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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700]),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[100], height: 24);
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue[700]!, width: 1.5),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      return dateString.split('T')[0];
    } catch (e) {
      return dateString;
    }
  }
}