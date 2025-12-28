import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/manager_leave.controller.dart';
import 'manager_leave_details.dart';

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  final ManagerLeaveController managerController = Get.put(ManagerLeaveController());

  @override
  void initState() {
    super.initState();
    // Fetch data as soon as the manager enters the screen
    managerController.fetchLeaveRequests();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args = Get.arguments;

    // Retrieve arguments passed from Employee Screen
    final String managerName = args?['name'] ?? 'Manager';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          // Leading to a back button to return to Employee Hub
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Get.back(),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Staff Requests",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                "Logged in as $managerName", // Manager name appears here
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              onPressed: () => managerController.fetchLeaveRequests(),
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

  Widget _badge(String status) {
    final String cleanStatus = status.toLowerCase();
    Color color = cleanStatus == 'approved'
        ? Colors.green
        : (cleanStatus == 'rejected' ? Colors.red : Colors.orange);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
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
}