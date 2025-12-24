import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/manager_leave.controller.dart';
import '../controller/login.controller.dart';
import 'manager_leave_details.dart';

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    // Controller initialization
    final loginController = Get.find<LoginController>();
    final managerController = Get.put(ManagerLeaveController());

    final List<Widget> pages = [
      _buildProfileView(loginController),
      _buildDashboardView(managerController, loginController),
      const Center(child: Text("Settings Page")),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF1A56BE),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  // Dashboard View
  Widget _buildDashboardView(
    ManagerLeaveController managerController,
    LoginController loginController,
  ) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            onPressed: () => _showLogoutDialog(loginController),
          ),
          title: const Text(
            "Manager Dashboard",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {},
            ),
          ],
          bottom: TabBar(
            labelColor: const Color(0xFF1976D2),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1976D2),
            onTap: (index) => managerController.fetchLeaveRequests(),
            tabs: const [
              Tab(text: "TODO"),
              Tab(text: "HISTORY"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLeaveList(
              managerController,
              managerController.pendingRequests,
              isHistory: false,
            ),
            _buildLeaveList(
              managerController,
              managerController.historyRequests,
              isHistory: true,
            ),
          ],
        ),
      ),
    );
  }

  // Profile View
  Widget _buildProfileView(LoginController loginController) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFF0F2F5),
              child: Icon(Icons.person, size: 50, color: Color(0xFF1A56BE)),
            ),
            const SizedBox(height: 20),
            const Text(
              "Manager Name",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              loginController.emailController.text.isNotEmpty
                  ? loginController.emailController.text
                  : "manager@leaveflow.com",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            _profileOption(Icons.edit_outlined, "Edit Profile"),
            _profileOption(
              Icons.logout,
              "Logout",
              color: Colors.red,
              onTap: () => _showLogoutDialog(loginController),
            ),
          ],
        ),
      ),
    );
  }

  // Leave List
  Widget _buildLeaveList(
    ManagerLeaveController controller,
    RxList list, {
    required bool isHistory,
  }) {
    return Obx(() {
      return RefreshIndicator(
        onRefresh: () => controller.fetchLeaveRequests(),
        child: controller.isLoading.value && list.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : list.isEmpty
            ? ListView(
                // Use ListView so 'Pull to Refresh' still works on the empty screen
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Center(
                    // Push to center
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isHistory
                              ? Icons.history
                              : Icons.assignment_turned_in_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isHistory
                              ? "No history found"
                              : "No pending requests",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isHistory
                              ? "Completed requests will appear here"
                              : "You're all caught up for now!",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final request = list[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        request['employee_name'] ?? "User",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Type: ${request['leave_type'] ?? 'N/A'}"),
                      trailing: isHistory
                          ? _badge(request['status'] ?? 'pending')
                          : const Icon(Icons.chevron_right, size: 20),
                      onTap: () async {
                        // Wait for result from the Details screen
                        var refreshNeeded = await Get.to(
                          () => ManagerLeaveDetails(request: request),
                        );

                        // If successfully approved/rejected refresh the list immediately
                        if (refreshNeeded == true) {
                          controller.fetchLeaveRequests();
                        }
                      },
                    ),
                  );
                },
              ),
      );
    });
  }

  // Dialogs and UI

  // Handle secure logout and clears session data
  void _showLogoutDialog(LoginController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Center(
          child: Text(
            "Logout",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
        content: const Text(
          "Are you sure you want to logout?",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 20),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Cancel Button
              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              // Logout Button
              TextButton(
                onPressed: () {
                  controller.emailController.clear();
                  controller.passwordController.clear();
                  Get.offAllNamed('/login');
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String status) {
    final String cleanStatus = status.toLowerCase();
    Color color = cleanStatus == 'approved'
        ? Colors.green
        : (cleanStatus == 'rejected' ? Colors.red : Colors.orange);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _profileOption(
    IconData icon,
    String title, {
    Color? color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
