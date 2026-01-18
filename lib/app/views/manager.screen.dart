import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Ensure you have intl package
import 'package:leaveflow/app/views/employee.screen.dart';
import '../controller/manager_leave.controller.dart';
import 'manager_leave_details.dart';

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> with SingleTickerProviderStateMixin {
  final ManagerLeaveController managerController = Get.put(ManagerLeaveController());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    managerController.fetchLeaveRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args = Get.arguments;
    final String managerName = args?['name'] ?? 'Manager';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Softer grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Get.off(() => const EmployeeScreen()),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Staff Requests",
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              "Welcome back, $managerName",
              style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.refresh, color: Colors.blue, size: 20),
            ),
            onPressed: () => managerController.fetchLeaveRequests(),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
            controller: _tabController,
            onTap: (index) => managerController.fetchLeaveRequests(),
            
            // 👇 1. REMOVE the 'indicator' BoxDecoration entirely
            // flutter defaults to an underline, but we can override it with a shape:
            indicator: BoxDecoration(
              color: Colors.blue.shade700, // Active Color
              borderRadius: BorderRadius.circular(50), // Fully rounded pill
            ),
            indicatorSize: TabBarIndicatorSize.tab, // Make it fill the space
            dividerColor: Colors.transparent, // Remove line at bottom

            // 👇 2. UPDATE Colors for contrast
            labelColor: Colors.white, // Active Text Color
            unselectedLabelColor: Colors.grey[600], // Inactive Text Color
            
            tabs: const [
              Tab(text: "Pending Actions"),
              Tab(text: "History Log"),
            ],
          ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaveList(managerController.pendingRequests, isHistory: false),
          _buildLeaveList(managerController.historyRequests, isHistory: true),
        ],
      ),
    );
  }

  Widget _buildLeaveList(RxList list, {required bool isHistory}) {
    return Obx(() {
      if (managerController.isLoading.value && list.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (list.isEmpty) {
        return _buildEmptyState(isHistory);
      }

      return RefreshIndicator(
        onRefresh: () => managerController.fetchLeaveRequests(),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final request = list[index];
            return _buildEnhancedCard(request, isHistory);
          },
        ),
      );
    });
  }

  Widget _buildEnhancedCard(Map<String, dynamic> request, bool isHistory) {
    String status = request['status'] ?? 'Pending';
    String leaveType = request['leave_type'] ?? 'Leave';
    String name = request['employee_name'] ?? 'Unknown Employee';
    String duration = "${request['days_requested'] ?? 1} Days";
    
    // Attempt to format dates nicely
    String dateRange = "Date info unavailable";
    if (request['start_date'] != null && request['end_date'] != null) {
      try {
        DateTime start = DateTime.parse(request['start_date'].toString());
        DateTime end = DateTime.parse(request['end_date'].toString());
        dateRange = "${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}";
      } catch (e) {
        dateRange = "${request['start_date']} - ${request['end_date']}";
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          var refreshNeeded = await Get.to(() => ManagerLeaveDetails(request: request));
          if (refreshNeeded == true) managerController.fetchLeaveRequests();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Avatar / Initials
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _getColorForType(leaveType).withOpacity(0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                      style: TextStyle(
                        color: _getColorForType(leaveType),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // 2. Main Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            // Duration Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                duration,
                                style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 6),
                            Text(
                              dateRange,
                              style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.category_outlined, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 6),
                            Text(
                              leaveType,
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // 3. Status Footer (Only if history)
              if (isHistory) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Status: ",
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    _statusBadge(status),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'approved': color = Colors.green; icon = Icons.check_circle_outline; break;
      case 'rejected': color = Colors.red; icon = Icons.cancel_outlined; break;
      case 'cancelled': color = Colors.grey; icon = Icons.remove_circle_outline; break;
      default: color = Colors.orange; icon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Color _getColorForType(String type) {
    if (type.toLowerCase().contains('medical')) return Colors.redAccent;
    if (type.toLowerCase().contains('annual')) return Colors.blueAccent;
    return Colors.purpleAccent;
  }

  Widget _buildEmptyState(bool isHistory) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(
              isHistory ? Icons.history_toggle_off : Icons.inbox_outlined,
              size: 50, color: Colors.grey[400]
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isHistory ? "No History Log" : "All Caught Up!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            isHistory 
              ? "Past requests will appear here." 
              : "No pending requests awaiting your approval.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}