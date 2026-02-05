import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:leaveflow/app/services/leave_api_service.dart';

class LeaveBalanceScreen extends StatefulWidget {
  const LeaveBalanceScreen({super.key});

  @override
  State<LeaveBalanceScreen> createState() => _LeaveBalanceScreenState();
}

class _LeaveBalanceScreenState extends State<LeaveBalanceScreen> {
  final user = FirebaseAuth.instance.currentUser;
  
  List<Map<String, dynamic>> leaveBalance = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLeaveBalance();
  }

  // 👇 HELPER: Safely converts String/Int/Double to Double
  // This prevents the "String has no instance method toInt" crash
  double safeParse(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<void> _loadLeaveBalance() async {
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
      
        print('Error loading leave balance: $e');
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadLeaveBalance,
            ),
          ),
        );
      }
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
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Leave Balance',
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
            onPressed: _loadLeaveBalance,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLeaveBalance,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? _buildErrorState()
                : leaveBalance.isEmpty
                    ? _buildEmptyState()
                    : _buildLeaveBalanceList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadLeaveBalance,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No leave balance data available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please contact your HR department',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildLeaveBalanceList() {
    // 1. Find the Annual Leave entry specifically for the Summary Card
    // We look for any type containing "annual" (case insensitive)
    var annualLeave = leaveBalance.firstWhere(
      (element) => (element['leave_type'] ?? '').toString().toLowerCase().contains('annual'),
      orElse: () => {}, // Return empty map if not found
    );

    // 2. Extract stats strictly for Annual Leave
    // If no Annual Leave is found, these default to 0
    double summaryTotal = safeParse(annualLeave['total_days'] ?? annualLeave['total']);
    double summaryAvailable = safeParse(annualLeave['available']);
    
    // Calculate used
    double summaryUsed = safeParse(annualLeave['used']);
    if (summaryUsed == 0 && summaryTotal > 0) {
      summaryUsed = summaryTotal - summaryAvailable;
    }
    
    // Fallback: If Annual Leave has 0 total (data error), maybe use the first available paid leave?
    // For now, 0 is safer than misleading data.

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟢 UPDATED: This now shows strictly ANNUAL LEAVE stats
            _buildSummaryCard(summaryAvailable, summaryUsed, summaryTotal),
            
            const SizedBox(height: 24),

            const Text(
              'All Leave Types', // Changed title slightly
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // 3. The list below still shows EVERYTHING (Medical, Emergency, etc.)
            ...leaveBalance.map((leave) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildDetailedLeaveCard(leave),
                )),

            const SizedBox(height: 16),
            _buildInfoNote(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
  Widget _buildSummaryCard(double available, double used, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Leave Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${available.toInt()} Days',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Available',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total',
                '${total.toInt()}',
                Icons.calendar_month,
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white30,
              ),
              _buildSummaryItem(
                'Used',
                '${used.toInt()}',
                Icons.check_circle_outline,
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white30,
              ),
              _buildSummaryItem(
                'Remaining',
                '${available.toInt()}',
                Icons.event_available,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedLeaveCard(Map<String, dynamic> leave) {
    final leaveType = leave['leave_type'] ?? 'Unknown';
    
    // 🛠️ USE safeParse()
    final total = safeParse(leave['total_days'] ?? leave['total']);
    final available = safeParse(leave['available']);
    
    // Calculate used safely
    final used = total - available;
    
    final percentage = total > 0 ? (available / total) : 0.0;

    // Determine color based on availability
    Color statusColor;
    if (available >= total * 0.7) {
      statusColor = Colors.green;
    } else if (available >= total * 0.3) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getLeaveIcon(leaveType),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    leaveType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(percentage * 100).toInt()}%',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  'Available',
                  '${available.toInt()}',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  'Used',
                  '${used.toInt()}',
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  'Total',
                  '${total.toInt()}',
                  Colors.blue[700]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              color: statusColor,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${available.toInt()} of ${total.toInt()} days remaining',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  IconData _getLeaveIcon(String leaveType) {
    final type = leaveType.toLowerCase();
    if (type.contains('annual')) return Icons.beach_access;
    if (type.contains('sick') || type.contains('medical')) return Icons.local_hospital;
    if (type.contains('unpaid')) return Icons.money_off;
    if (type.contains('emergency')) return Icons.warning_amber;
    return Icons.event_note;
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leave Balance Information',
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your leave balance is updated automatically when requests are approved. Contact HR if you notice any discrepancies.',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}