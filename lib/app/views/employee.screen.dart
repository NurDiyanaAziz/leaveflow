import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/services/sharedprefs.dart';
import 'package:leaveflow/app/views/login.screen.dart';
import 'package:leaveflow/app/views/manager.screen.dart';
import 'package:leaveflow/app/views/profile.screen.dart';
import 'package:leaveflow/app/views/settings.screen.dart';
import 'package:leaveflow/app/views/login.screen.dart';
import 'package:leaveflow/app/views/leave.balance.screen.dart';
import 'package:leaveflow/app/views/leave.request.screen.dart';
import 'package:leaveflow/app/services/leave_api_service.dart';
import 'package:leaveflow/app/services/sharedprefs.dart';
import 'package:leaveflow/app/views/new.leave.request.screen.dart';
import 'package:leaveflow/app/widgets/home.calendar.card.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  
  List<Map<String, dynamic>> leaveBalance = [];
  List<Map<String, dynamic>> recentRequests = [];
  bool isLoading = true;
  bool isLoadingRequests = true;
  String? errorMessage;
  String? requestsErrorMessage;
  List<Map<String, dynamic>> allRequests = [];

  @override
  void initState() {
    super.initState();
    _loadLeaveBalance();
    _loadRecentRequests();
  }

  Future<void> _loadLeaveBalance() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final balance = await LeaveApiService.getLeaveBalance();
      
      if (mounted) {
        setState(() {
          leaveBalance = balance;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load leave balance';
        });
      }
      
      print('Error loading leave balance: $e');
    }
  }

  Future<void> _loadRecentRequests() async {
    if (!mounted) return;
    
    setState(() {
      isLoadingRequests = true;
      requestsErrorMessage = null;
    });

    try {
      final requests = await LeaveApiService.getRecentRequests(limit: 3);
      final all = await LeaveApiService.getAllRequests();
      
      if (mounted) {
        setState(() {
          recentRequests = requests;
          allRequests = all;
          isLoadingRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingRequests = false;
          requestsErrorMessage = 'Unable to load requests';
        });
      }
      print('Error loading recent requests: $e');
    }
  }

  // to refresh both sections
  Future<void> _refreshAll() async {
    await Future.wait([
      _loadLeaveBalance(),
      _loadRecentRequests(),
    ]);
  }

  void signout() async {
    // 1. Show Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 2. Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // 3. CRITICAL: Clear Local Storage
      // If you don't do this, the app might auto-login again
      await SharedPrefs.removeLocalStorage('token');
      await SharedPrefs.removeLocalStorage('role');
      await SharedPrefs.removeLocalStorage('name');
      await SharedPrefs.removeLocalStorage('uid');
      await SharedPrefs.removeLocalStorage('user');

      // 4. Navigate back to Login using GetX
      // This clears the navigation stack so they can't go back
      Get.offAll(() => LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: signout,
          tooltip: 'Logout',
        ),
        title: const Text(
          'LeaveFlow',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _refreshAll, 
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll, 
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(),
                const SizedBox(height: 16),
                
                // Request Status at the top
                _buildRecentRequests(),
                const SizedBox(height: 16),
                
                // Quick Actions (New Request button)
                _buildQuickActions(),
                const SizedBox(height: 16),
                
                // Calendar Card
                HomeCalendarCard(leaveRequests: allRequests),
                const SizedBox(height: 16),
                
                // Leave Balance
                _buildLeaveBalance(),
                
                // Add extra spacing at the bottom for better scrolling
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // UI Widget for Manager Portal Card
  Widget _buildManagerPortalCard() {
    return InkWell(
      onTap: () async {
        // 1. Fetch the name from local storage to ensure accuracy
        String? savedName = await SharedPrefs.getLocalStorage('name'); 

        // 2. Using GetX to move to ManagerScreen
        // Pass the name in 'arguments' so the ManagerScreen knows who is logged in without having to fetch it again
         Get.to(
          () => const ManagerScreen(),
          arguments: {
            // Use the fetched name, fallback to Firebase name, then 'Manager'
            'name': savedName ?? user?.displayName ?? 'Manager', 
          },
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[900]!, Colors.blue[700]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Icon Container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 26), // Shield icon for Manager
          ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Manager Portal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Review staff leave requests', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Welcome, ',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            Flexible(
              child: Text(
                '${user?.displayName ?? user?.email?.split('@')[0] ?? 'User'}!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
      ],
    );
  }

  Widget _buildLeaveBalance() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Leave Balance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LeaveBalanceScreen(),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorMessage != null)
            Center(
              child: Column(
                children: [
                  Icon(Icons.cloud_off_outlined, size: 48, color: Colors.orange[300]),
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your connection',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loadLeaveBalance,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
            )
          else if (leaveBalance.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text('No leave balance data available', 
                         style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else
            ...leaveBalance.map((leave) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildLeaveBalanceCard(leave),
                )),
        ],
      ),
    );
  }

  Widget _buildLeaveBalanceCard(Map<String, dynamic> leave) {
    final available = (leave['available'] ?? 0).toInt();
    final total = (leave['total'] ?? 0).toInt();
    final used = (leave['used'] ?? 0).toInt();
    final percentage = total > 0 ? (available / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leave['leave_type'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              Text(
                '$total days total',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$available',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' available',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$used',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' used',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              color: Colors.blue[700],
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      width: double.infinity, 
      child: _buildActionButton(
        'New Request',
        Icons.add_circle_outline,
        Colors.blue[700]!,
        Colors.white,
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewLeaveRequestScreen(),
            ),
          );
          
          if (result == true && mounted) {
            _refreshAll();
          }
        },
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color bgColor,
    Color textColor, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: textColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRequests() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      size: 20,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Request Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (!isLoadingRequests && recentRequests.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaveRequestScreen(),
                      ),
                    );
                    if (mounted) {
                      _refreshAll();
                    }
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Column(
              children: [
                // Loading State
                if (isLoadingRequests)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Error State
                if (!isLoadingRequests && requestsErrorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_off_outlined, 
                               size: 48, 
                               color: Colors.orange[300]),
                          const SizedBox(height: 12),
                          Text(
                            requestsErrorMessage!,
                            style: TextStyle(color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please check your connection',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _loadRecentRequests,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20, 
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Empty State
                if (!isLoadingRequests && 
                    requestsErrorMessage == null && 
                    recentRequests.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy_outlined, 
                               size: 48, 
                               color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No recent leave requests',
                            style: TextStyle(
                              color: Colors.grey[600], 
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NewLeaveRequestScreen(),
                                ),
                              );
                              if (result == true && mounted) {
                                _refreshAll();
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text('Create your first request'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // List Data
                if (!isLoadingRequests && 
                    requestsErrorMessage == null && 
                    recentRequests.isNotEmpty)
                  ...recentRequests.map((request) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRequestCard(request),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] as String;
    final isPending = status == 'Pending';
    final isApproved = status == 'Approved';

    // Format dates
    String dateRange = '';
    if (request['start_date'] != null && request['end_date'] != null) {
      final startDate = DateTime.parse(request['start_date']);
      final endDate = DateTime.parse(request['end_date']);
      
      if (startDate.day == endDate.day && 
          startDate.month == endDate.month && 
          startDate.year == endDate.year) {
        dateRange = _formatDate(startDate);
      } else {
        dateRange = '${_formatDate(startDate)} - ${_formatDate(endDate)}';
      }
    }

    return InkWell(
      onTap: () {
        // TODO: Show request details
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isPending 
                ? Colors.orange[200]! 
                : isApproved 
                    ? Colors.green[200]! 
                    : Colors.red[200]!,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isPending
              ? Colors.orange[50]
              : isApproved
                  ? Colors.green[50]
                  : Colors.red[50],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge at the top
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, 
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isPending
                              ? Colors.orange[600]
                              : isApproved
                                  ? Colors.green[600]
                                  : Colors.red[600],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        request['leave_type'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (dateRange.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14, 
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                dateRange,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time, 
                            size: 14, 
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${request['days'].toInt()} day${request['days'] > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. PROFILE BUTTON
              _buildNavItem(
                Icons.person_outline, 
                'Profile', 
                false, 
                onTap: () => Get.to(() => const ProfileScreen()), // Navigate to Profile
              ),

              // 2. HOME BUTTON (Already Here)
              _buildNavItem(
                Icons.home, 
                'Home', 
                true, 
                onTap: () {}, // Do nothing, we are already here
              ),

              // 3. SETTINGS BUTTON
              _buildNavItem(
                Icons.settings_outlined, 
                'Settings', 
                false, 
                onTap: () => Get.to(() => const SettingsScreen()), // Navigate to Settings
              ),
            ],
          ),
        ),
      ),
    );
  }
  
Widget _buildNavItem(IconData icon, String label, bool isActive, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, // Handle the click
      borderRadius: BorderRadius.circular(10), // Ripple effect shape
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Bigger touch target
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.blue[600] : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.blue[600] : Colors.grey[600],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
