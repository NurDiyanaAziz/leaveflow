import 'package:flutter/material.dart';
import 'package:leaveflow/app/services/leave_api_service.dart';
import 'package:leaveflow/app/views/leave.detail.screen.dart';

class LeaveRequestScreen extends StatefulWidget {  // Changed class name
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();  // Changed state name
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {  // Changed state name
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;
  String selectedFilter = 'All';
  
  final List<String> statusFilters = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => isLoading = true);

    try {
      final allRequests = await LeaveApiService.getAllRequests(
        status: selectedFilter == 'All' ? null : selectedFilter,
      );
      
      setState(() {
        requests = allRequests;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading requests: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
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
          'Leave Requests',  
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
            onPressed: _loadRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadRequests,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : requests.isEmpty
                      ? _buildEmptyState()
                      : _buildRequestsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statusFilters.map((filter) {
            final isSelected = selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    selectedFilter = filter;
                  });
                  _loadRequests();
                },
                backgroundColor: Colors.grey[100],
                selectedColor: Colors.blue[100],
                checkmarkColor: Colors.blue[700],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.blue[700] : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'No leave requests found';
    if (selectedFilter != 'All') {
      message = 'No $selectedFilter requests found';
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height - 250,
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
                message,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              if (selectedFilter != 'All')
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedFilter = 'All';
                    });
                    _loadRequests();
                  },
                  child: const Text('Show all requests'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    // Group requests by month
    Map<String, List<Map<String, dynamic>>> groupedRequests = {};
    
    for (var request in requests) {
      if (request['created_at'] != null) {
        final date = DateTime.parse(request['created_at']);
        final monthYear = _getMonthYear(date);
        
        if (!groupedRequests.containsKey(monthYear)) {
          groupedRequests[monthYear] = [];
        }
        groupedRequests[monthYear]!.add(request);
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedRequests.length,
      itemBuilder: (context, index) {
        final monthYear = groupedRequests.keys.elementAt(index);
        final monthRequests = groupedRequests[monthYear]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
              child: Text(
                monthYear,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            ...monthRequests.map((request) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRequestCard(request),
                )),
          ],
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] as String;
    final isPending = status == 'Pending';
    final isApproved = status == 'Approved';
    // ignore: unused_local_variable
    final isRejected = status == 'Rejected';

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

    Color statusColor = isPending
        ? Colors.orange
        : isApproved
            ? Colors.green
            : Colors.red;

    return InkWell(
      onTap: () async {
        // 1. Navigate to Details and WAIT for result
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeaveDetailScreen(request: request),
          ),
        );

        // 2. If result is 'true', it means a request was cancelled.
        //    We must refresh THIS list immediately so the user sees "Cancelled".
        if (result == true) {
          _loadRequests(); // Call your existing function that fetches data
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getLeaveIcon(request['leave_type']),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['leave_type'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${request['days'].toInt()} day${request['days'] > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor.shade700,
                    ),
                  ),
                ),
              ],
            ),
            if (dateRange.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    dateRange,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
            if (request['reason'] != null && request['reason'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                request['reason'],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showRequestDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              request['leave_type'] ?? 'Leave Request',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              'Status',
              request['status'],
              icon: Icons.info_outline,
            ),
            _buildDetailRow(
              'Duration',
              '${request['days'].toInt()} day${request['days'] > 1 ? 's' : ''}',
              icon: Icons.access_time,
            ),
            if (request['start_date'] != null && request['end_date'] != null)
              _buildDetailRow(
                'Dates',
                '${_formatDate(DateTime.parse(request['start_date'].toString()).toLocal())} - ${_formatDate(DateTime.parse(request['end_date'].toString()).toLocal())}',
                icon: Icons.calendar_today,
              ),
            if (request['reason'] != null && request['reason'].toString().isNotEmpty)
              _buildDetailRow(
                'Reason',
                request['reason'],
                icon: Icons.notes,
              ),
            if (request['manager_remarks'] != null && 
                request['manager_remarks'].toString().isNotEmpty)
              _buildDetailRow(
                'Manager Response',
                request['manager_remarks'],
                icon: Icons.comment,
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLeaveIcon(String? leaveType) {
    if (leaveType == null) return Icons.event_note;
    final type = leaveType.toLowerCase();
    if (type.contains('annual')) return Icons.beach_access;
    if (type.contains('sick') || type.contains('medical')) return Icons.local_hospital;
    if (type.contains('unpaid')) return Icons.money_off;
    if (type.contains('emergency')) return Icons.warning_amber;
    return Icons.event_note;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getMonthYear(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.year}';
  }
}

extension on Color {
  Color? get shade700 => null;
}