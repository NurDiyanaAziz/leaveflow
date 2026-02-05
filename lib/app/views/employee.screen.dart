import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/services/sharedprefs.dart';
import 'package:leaveflow/app/views/leave.detail.screen.dart';
import 'package:leaveflow/app/views/login.screen.dart';
import 'package:leaveflow/app/views/manager.screen.dart';
import 'package:leaveflow/app/views/new.leave.request.dart';
import 'package:leaveflow/app/views/profile.screen.dart';
import 'package:leaveflow/app/views/settings.screen.dart';
import 'package:leaveflow/app/views/leave.balance.screen.dart';
import 'package:leaveflow/app/views/leave.request.screen.dart';
import 'package:leaveflow/app/services/leave_api_service.dart';
import 'package:leaveflow/app/views/new.leave.request.screen.dart';
import 'package:leaveflow/app/widgets/home.calendar.card.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  //final user = FirebaseAuth.instance.currentUser;
  
  List<Map<String, dynamic>> leaveBalance = [];
  List<Map<String, dynamic>> recentRequests = [];
  bool isLoading = true;
  bool isLoadingRequests = true;
  String? errorMessage;
  String? requestsErrorMessage;
  List<Map<String, dynamic>> allRequests = [];
  List<Map<String, dynamic>> publicHolidays = [];
  int pendingCount = 0;

  String displayName = 'User';
  String userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPendingCount();
    _loadUserName();
    _loadLeaveBalance();
    _loadRecentRequests();
    _loadHolidays();
  }

  Future<void> _loadPendingCount() async {
    // Only load if user is a manager (to save data)
    // If you don't have an 'isManager' check yet, just run it anyway.
    int count = await LeaveApiService.getPendingCount();
    if (mounted) {
      setState(() {
        pendingCount = count;
      });
    }
  }

  Future<void> _loadUserData() async {
    // 1. Get Name
    String? name = await SharedPrefs.getLocalStorage('name');
    
    // 2. Get Role (Make sure your Login screen saves this key: 'role')
    String? role = await SharedPrefs.getLocalStorage('role');

    // Fallback if name is missing
    if (name == null || name.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      name = user?.displayName ?? user?.email?.split('@')[0];
    }

    if (mounted) {
      setState(() {
        displayName = name ?? 'User';
        userRole = role ?? 'Employee'; // Default to Employee if missing
      });
    }
  }

  Future<void> _loadUserName() async {
    // Try to get the name from Local Storage (SharedPrefs) first
    // This is what your Login screen saved, so it's the most accurate.
    String? name = await SharedPrefs.getLocalStorage('name');

    // If empty, fallback to Firebase
    if (name == null || name.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload(); // Force refresh from Firebase
      name = user?.displayName ?? user?.email?.split('@')[0];
    }

    if (mounted) {
      setState(() {
        displayName = name ?? 'User';
      });
    }
  }

  // Future<void> _loadLeaveBalance() async {
  //   if (!mounted) return;
    
  //   setState(() {
  //     isLoading = true;
  //     errorMessage = null;
  //   });

  //   try {
  //     final balance = await LeaveApiService.getLeaveBalance();
      
  //     if (mounted) {
  //       setState(() {
  //         leaveBalance = balance;
  //         isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() {
  //         isLoading = false;
  //         errorMessage = 'Failed to load leave balance';
  //       });
  //     }
      
  //     print('Error loading leave balance: $e');
  //   }
  // }

  Future<void> _loadLeaveBalance() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 1. Call the new API
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
      // 1. Fetch data from API
      final requests = await LeaveApiService.getRecentRequests(limit: 3);
      final all = await LeaveApiService.getAllRequests();
      
      // 2. 🔥 ADD THIS SORTING LOGIC 🔥
      // This forces 'Pending' requests to the top of the list
      requests.sort((a, b) {
        // If A is Pending and B is not, A goes first (-1)
        if (a['status'] == 'Pending' && b['status'] != 'Pending') return -1;
        // If B is Pending and A is not, B goes first (1)
        if (a['status'] != 'Pending' && b['status'] == 'Pending') return 1;
        // Otherwise, keep original order (sorted by date from SQL)
        return 0; 
      });

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
      _loadHolidays(),
      _loadPendingCount(),
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

  Future<void> _loadHolidays() async {
    try {
      // Assuming you have this method in LeaveApiService
      final holidays = await LeaveApiService.getCalendarHolidays();
      if (mounted) {
        setState(() {
          publicHolidays = holidays;
        });
      }
    } catch (e) {
      print("Error loading holidays: $e");
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
                _buildManagerPortalCard(),
                const SizedBox(height: 16),
                // Request Status at the top
                _buildRecentRequests(),
                const SizedBox(height: 16),
                
                // Quick Actions (New Request button)
                _buildQuickActions(),
                const SizedBox(height: 16),
                
                // Calendar Card
                HomeCalendarCard(leaveRequests: allRequests,publicHolidays: publicHolidays,),
                const SizedBox(height: 16),
                
                // Leave Balance
                _buildLeaveBalance(),
                
                // Add extra spacing at the bottom for better scrolling
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // UI Widget for Manager Portal Card
  // ignore: unused_element
  // Widget _buildManagerPortalCard() {
  //   return InkWell(
  //     onTap: () async {
  //       // 1. Fetch the name from local storage to ensure accuracy
  //       String? savedName = await SharedPrefs.getLocalStorage('name'); 

  //       // 2. Using GetX to move to ManagerScreen
  //       // Pass the name in 'arguments' so the ManagerScreen knows who is logged in without having to fetch it again
  //        Get.to(
  //         () => const ManagerScreen(),
  //         arguments: {
  //           // Use the fetched name, fallback to Firebase name, then 'Manager'
  //           // ignore: dead_code
  //           'name': savedName ?? displayName, 
  //         },
  //       );
  //     },
  //     borderRadius: BorderRadius.circular(16),
  //     child: Container(
  //       padding: const EdgeInsets.all(20),
  //       decoration: BoxDecoration(
  //         gradient: LinearGradient(
  //           colors: [Colors.blue[900]!, Colors.blue[700]!],
  //           begin: Alignment.topLeft,
  //           end: Alignment.bottomRight,
  //         ),
  //         borderRadius: BorderRadius.circular(16),
  //         boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
  //       ),
  //       child: Row(
  //         children: [
  //           // Icon Container
  //         Container(
  //           padding: const EdgeInsets.all(8),
  //           decoration: BoxDecoration(
  //             color: Colors.white.withOpacity(0.2),
  //             shape: BoxShape.circle,
  //           ),
  //           child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 26), // Shield icon for Manager
  //         ),
  //           const SizedBox(width: 16),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: const [
  //                 Text('Manager Portal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
  //                 Text('Review staff leave requests', style: TextStyle(color: Colors.white70, fontSize: 13)),
  //               ],
  //             ),
  //           ),
  //           const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildManagerPortalCard() {
    // Optional: Hide if not manager
    if (userRole.toLowerCase() != 'manager') {
      return const SizedBox.shrink(); // Returns nothing (hides the card)
    }

    return InkWell(
      onTap: () async {
        final currentUser = FirebaseAuth.instance.currentUser;
        Get.to(
          () => const ManagerScreen(),
          arguments: {
            'name': displayName, 
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)], // Deep Navy Blue
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manager Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                
                // 👇 DYNAMIC STATUS TEXT
                if (pendingCount > 0)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.priority_high, size: 12, color: Colors.purple[700]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$pendingCount Requests Pending',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'No pending actions',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            
            // 👇 BIG BADGE ICON
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                ),
                
                // The Red Dot Counter
                if (pendingCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent, // Urgent Color
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        pendingCount > 9 ? '9+' : '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
                '$displayName!',
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
            ...leaveBalance.take(5).map((leave) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildLeaveBalanceCard(leave),
                )),
        ],
      ),
    );
  }

  // Widget _buildLeaveBalanceCard(Map<String, dynamic> leave) {
  //   final available = (leave['available'] ?? 0).toInt();
  //   final total = (leave['total'] ?? 0).toInt();
  //   final used = (leave['used'] ?? 0).toInt();
  //   final percentage = total > 0 ? (available / total) : 0.0;

  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       border: Border.all(color: Colors.grey[300]!),
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               leave['leave_type'] ?? 'Unknown',
  //               style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
  //             ),
  //             Text(
  //               '$total days total',
  //               style: TextStyle(fontSize: 13, color: Colors.grey[600]),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Row(
  //           children: [
  //             RichText(
  //               text: TextSpan(
  //                 children: [
  //                   TextSpan(
  //                     text: '$available',
  //                     style: const TextStyle(
  //                       color: Colors.green,
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                   TextSpan(
  //                     text: ' available',
  //                     style: TextStyle(color: Colors.grey[700], fontSize: 14),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(width: 16),
  //             RichText(
  //               text: TextSpan(
  //                 children: [
  //                   TextSpan(
  //                     text: '$used',
  //                     style: const TextStyle(
  //                       color: Colors.orange,
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                   TextSpan(
  //                     text: ' used',
  //                     style: TextStyle(color: Colors.grey[700], fontSize: 14),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         ClipRRect(
  //           borderRadius: BorderRadius.circular(10),
  //           child: LinearProgressIndicator(
  //             value: percentage,
  //             backgroundColor: Colors.grey[200],
  //             color: Colors.blue[700],
  //             minHeight: 8,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

Widget _buildLeaveBalanceCard(Map<String, dynamic> leave) {
    // 👇 HELPER FUNCTION: Safely converts String/Int/Double to a Number
    double safeParse(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      // If it's a String (e.g. "16.00"), parse it
      return double.tryParse(value.toString()) ?? 0.0;
    }

    // 1. Get values safely using the helper
    final total = safeParse(leave['total_days'] ?? leave['total']).toInt(); 
    final available = safeParse(leave['available']).toInt();
    
    // 2. Calculate Used
    final used = total - available;
    
    // 3. Calculate Percentage
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
                text: TextSpan(children: [
                  TextSpan(text: '$available', style: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' available', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                ]),
              ),
              const SizedBox(width: 16),
              RichText(
                text: TextSpan(children: [
                  TextSpan(text: '$used', style: const TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' used', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0), // Safety clamp ensures it never crashes UI
              backgroundColor: Colors.grey[200],
              color: Colors.blue[700],
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildQuickActions() {
  //   return SizedBox(
  //     width: double.infinity, 
  //     child: _buildActionButton(
  //       'New Request',
  //       Icons.add_circle_outline,
  //       Colors.blue[700]!,
  //       Colors.white,
  //       onTap: () async {
  //         final result = await Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => const NewLeavesRequestScreen(),
  //           ),
  //         );
          
  //         if (result == true && mounted) {
  //           _refreshAll();
  //         }
  //       },
  //     ),
  //   );
  // }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8), // Add breathing room
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.25), // Soft blue shadow
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NewLeavesRequestScreen(),
              ),
            );
            
            if (result == true && mounted) {
              _refreshAll();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!], // Employee Blue Brand
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // 1. The Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_calendar_rounded, // Better icon for "Leave"
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // 2. The Text Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Leave Request',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Submit casual, medical, or other leave',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 3. The Forward Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
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
                                  builder: (context) => const NewLeavesRequestScreen(),
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
    // 1. Extract Data
    final status = request['status'] ?? 'Pending';
    final leaveType = request['leave_type'] ?? 'Leave';
    final days = request['days'] ?? 0;
    // ignore: unused_local_variable
    final reason = request['reason'] ?? '';
    
    // 2. Color Logic: Pending = Orange, Cancelled = Grey (Low Priority)
    Color statusColor;
    Color bgColor;
    
    if (status == 'Approved') {
      statusColor = Colors.green[700]!;
      bgColor = Colors.green[50]!;
    } else if (status == 'Rejected') {
      statusColor = Colors.red[700]!;
      bgColor = Colors.red[50]!;
    } else if (status == 'Cancelled') {
      statusColor = Colors.grey[500]!; // 🌑 Dark Grey text
      bgColor = Colors.grey[100]!;     // 🌑 Light Grey background (Low Priority)
    } else {
      // Default / Pending
      statusColor = Colors.orange[800]!; // 🟠 Bright Orange (High Visibility)
      bgColor = Colors.orange[50]!;
    }

    // 3. Date Formatting
    String dateRange = "Date info unavailable";
    if (request['start_date'] != null && request['end_date'] != null) {
      final start = DateTime.parse(request['start_date']);
      final end = DateTime.parse(request['end_date']);
      
      // If same day, show only one date
      if (start.year == end.year && start.month == end.month && start.day == end.day) {
        dateRange = _formatDate(start); 
      } else {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        String startStr = '${months[start.month - 1]} ${start.day}';
        String endStr = '${months[end.month - 1]} ${end.day}, ${end.year}';
        dateRange = "$startStr - $endStr";
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              // Navigate to Details
              final result = await Get.to(() => LeaveDetailScreen(request: request));
              // Refresh if cancelled
              if (result == true) _refreshAll(); 
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon Box
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bgColor, 
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getLeaveIcon(leaveType), color: statusColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leaveType, 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 16,
                                // Grey out title if cancelled
                                color: status == 'Cancelled' ? Colors.grey : Colors.black87 
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${days.toInt()} Day${days > 1 ? 's' : ''}", 
                              style: TextStyle(color: Colors.grey[600], fontSize: 13)
                            ),
                          ],
                        ),
                      ),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 10
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 12),

                  // Bottom Row: Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(dateRange, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
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

  // Helper to pick an icon based on leave name
  IconData _getLeaveIcon(String? type) {
    if (type == null) return Icons.event;
    final t = type.toLowerCase();
    if (t.contains('sick') || t.contains('medical') || t.contains('hospital')) {
      return Icons.local_hospital;
    }
    if (t.contains('annual') || t.contains('vacation')) {
      return Icons.beach_access;
    }
    if (t.contains('maternity') || t.contains('paternity') || t.contains('marriage')) {
      return Icons.favorite;
    }
    if (t.contains('compassionate')) {
      return Icons.volunteer_activism;
    }
    return Icons.event_note; // Default icon
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
