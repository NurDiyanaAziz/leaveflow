import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leaveflow/app/services/leave_api_service.dart';

class LeaveDetailScreen extends StatefulWidget {
  final Map<String, dynamic> request;

  const LeaveDetailScreen({super.key, required this.request});

  @override
  State<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen> {
  late String status;
  bool isCancelling = false;

  @override
  void initState() {
    super.initState();
    status = widget.request['status'] ?? 'Pending';
  }

  Future<void> _handleCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this leave request? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isCancelling = true);

    final success = await LeaveApiService.cancelRequest(widget.request['id']);

    if (mounted) {
      setState(() => isCancelling = false);
      if (success) {
        Navigator.pop(context, true); // Return true to refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel request')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors based on status
    Color statusColor = Colors.orange;
    Color statusBg = Colors.orange.shade50;
    IconData statusIcon = Icons.access_time_filled;

    if (status == 'Approved') {
      statusColor = Colors.green;
      statusBg = Colors.green.shade50;
      statusIcon = Icons.check_circle;
    } else if (status == 'Rejected') {
      statusColor = Colors.red;
      statusBg = Colors.red.shade50;
      statusIcon = Icons.cancel;
    } else if (status == 'Cancelled') {
      statusColor = Colors.grey;
      statusBg = Colors.grey.shade100;
      statusIcon = Icons.remove_circle_outline;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Request Details', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER STATUS BANNER
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24, top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(statusIcon, size: 48, color: statusColor),
                    const SizedBox(height: 12),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Submitted on ${_formatDateRaw(widget.request['created_at'])}',
                      style: TextStyle(color: statusColor.withOpacity(0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. MAIN DETAILS CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildListItem(
                      Icons.category_outlined,
                      'Leave Type',
                      widget.request['leave_type'] ?? 'Unknown',
                      Colors.blue,
                    ),
                    const Divider(height: 1, indent: 60),
                    
                    _buildListItem(
                      Icons.calendar_today_outlined,
                      'Duration',
                      '${_formatDateRaw(widget.request['start_date'])} - ${_formatDateRaw(widget.request['end_date'])}',
                      Colors.purple,
                      subtitle: '${widget.request['days']} Days',
                    ),
                    const Divider(height: 1, indent: 60),

                    _buildListItem(
                      Icons.notes_outlined,
                      'Reason',
                      widget.request['reason'] ?? 'No reason provided',
                      Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            // 3. MANAGER REMARKS (If exists)
            if (widget.request['manager_remarks'] != null && widget.request['manager_remarks'].toString().isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Manager's Remarks",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.request['manager_remarks'],
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),

            // 4. ACTION BUTTONS
            if (status == 'Pending')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: isCancelling
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _handleCancel,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancel Request'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red,
                            elevation: 0,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(IconData icon, String title, String value, Color iconColor, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRaw(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      DateTime date = DateTime.parse(dateStr.toString()).toLocal(); // Ensure Local Time
      return DateFormat('d MMM yyyy').format(date);
    } catch (e) {
      return dateStr.toString();
    }
  }
}