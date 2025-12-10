import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _leaveBalance;
  List<dynamic>? _recentLeaves;
  int _currentIndex = 1; // Home tab selected by default

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  Future<void> _loadEmployeeData() async {
    setState(() => _isLoading = true);

    // Simulate loading delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock data for testing
    setState(() {
      _leaveBalance = {
        'annual_leave': 11,
        'annual_total': 20,
        'medical_leave': 12,
        'medical_total': 14,
      };
      _recentLeaves = [
        {
          'leave_type': 'Annual Leave',
          'start_date': '2024-08-15',
          'end_date': '2024-08-16',
          'status': 'Pending',
          'reason': 'Family vacation',
        },
        {
          'leave_type': 'Medical Leave',
          'start_date': '2024-06-23',
          'end_date': '2024-06-24',
          'status': 'Approved',
          'reason': 'Doctor appointment',
        },
        {
          'leave_type': 'Annual Leave',
          'start_date': '2024-02-09',
          'end_date': '2024-02-12',
          'status': 'Rejected',
          'reason': 'Not enough leave balance',
        },
      ];
      _isLoading = false;
    });
  }

  void _onNavBarTapped(int index) {
    setState(() => _currentIndex = index);
    
    switch (index) {
      case 0:
        // Navigate to Profile
        Get.toNamed('/profile');
        break;
      case 1:
        // Already on Home
        break;
      case 2:
        // Navigate to Settings
        Get.toNamed('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Leave Page',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEmployeeData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Types of Leave Section
                    _buildSectionHeader('Types of Leave', onViewMore: () {
                      Get.toNamed('/leave-types');
                    }),
                    const SizedBox(height: 12),
                    _buildLeaveTypesRow(),
                    const SizedBox(height: 24),

                    // Leave History Section
                    _buildSectionHeader('Leave History', onViewMore: () {
                      Get.toNamed('/leave-history');
                    }),
                    const SizedBox(height: 12),
                    _buildLeaveHistoryList(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to apply leave screen
          Get.toNamed('/apply-leave');
        },
        backgroundColor: const Color(0xFF1E40AF),
        child: const Icon(Icons.add, size: 32),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewMore}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E40AF),
          ),
        ),
        TextButton(
          onPressed: onViewMore,
          child: const Text(
            'View More',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveTypesRow() {
    final annualLeave = _leaveBalance?['annual_leave'] ?? 0;
    final annualTotal = _leaveBalance?['annual_total'] ?? 20;
    final medicalLeave = _leaveBalance?['medical_leave'] ?? 0;
    final medicalTotal = _leaveBalance?['medical_total'] ?? 14;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildLeaveTypeCard(
            'Annual Leave',
            '$annualLeave of $annualTotal Days',
            const Color(0xFFDCE4F7),
          ),
          const SizedBox(width: 12),
          _buildLeaveTypeCard(
            'Medical Leave',
            '$medicalLeave of $medicalTotal Days',
            const Color(0xFFDCE4F7),
          ),
          const SizedBox(width: 12),
          _buildLeaveTypeCard(
            'Casual Leave',
            '5 of 10 Days',
            const Color(0xFFDCE4F7),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTypeCard(String title, String balance, Color bgColor) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            balance,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveHistoryList() {
    if (_recentLeaves == null || _recentLeaves!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No leave requests yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recentLeaves!.map((leave) {
        return _buildLeaveHistoryCard(leave);
      }).toList(),
    );
  }

  Widget _buildLeaveHistoryCard(Map<String, dynamic> leave) {
    final leaveType = leave['leave_type'] ?? 'Annual Leave';
    final startDate = leave['start_date'] ?? '';
    final endDate = leave['end_date'] ?? '';
    final status = leave['status'] ?? 'Pending';

    // Parse dates
    final start = DateTime.tryParse(startDate);
    final end = DateTime.tryParse(endDate);
    
    String dateRange = '';
    String month = '';
    Color cardColor = Colors.yellow[100]!;
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.access_time;
    String statusText = 'Awaiting';

    if (start != null && end != null) {
      dateRange = '${start.day} - ${end.day}';
      month = _getMonthName(start.month);
    }

    // Set colors and icons based on status
    switch (status.toLowerCase()) {
      case 'approved':
        cardColor = Colors.green[100]!;
        statusColor = Colors.green;
        statusIcon = Icons.check;
        statusText = 'Approved';
        break;
      case 'rejected':
        cardColor = Colors.red[100]!;
        statusColor = Colors.red;
        statusIcon = Icons.close;
        statusText = 'Rejected';
        break;
      default:
        cardColor = Colors.yellow[100]!;
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusText = 'Awaiting';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Date box
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dateRange,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Leave details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leaveType,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 14,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Arrow icon
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTapped,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1E40AF),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}