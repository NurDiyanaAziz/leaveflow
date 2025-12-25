import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/manager_leave.controller.dart';

class ManagerLeaveDetails extends StatelessWidget {
  final Map<String, dynamic> request;
  final TextEditingController remarksController = TextEditingController();

  // Controller for consistent use in logic
  final ManagerLeaveController controller = Get.find<ManagerLeaveController>();

  ManagerLeaveDetails({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    // Handle status for coloring and logic
    final String status = (request['status'] ?? 'pending')
        .toString()
        .toLowerCase();
    final bool isPending = status == 'pending';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Leave Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("EMPLOYEE INFORMATION"),
            _infoTile(
              "Employee Name",
              (request['employee_name'] ?? "User").toString(),
            ),

            const SizedBox(height: 20),
            _sectionHeader("LEAVE INFORMATION"),
            _infoTile(
              "Type of Leave",
              (request['leave_type'] ?? "N/A").toString(),
            ),
            _infoTile(
              "Reason",
              (request['reason'] ?? "No reason provided").toString(),
            ),

            Row(
              children: [
                Expanded(
                  child: _infoTile("From", _formatDate(request['start_date'])),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _infoTile("To", _formatDate(request['end_date'])),
                ),
              ],
            ),

            _infoTile("Supporting Document", "No file attached"),

            const SizedBox(height: 20),
            // Show Action Buttons only if status is PENDING
            if (isPending) ...[
              const Text(
                "Manager Remarks",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Enter remarks...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmAction(context, "rejected"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Reject",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _confirmAction(context, "approved"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A56BE),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Approve",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else
              // Show the status badge if already Approved or Rejected
              _buildStatusBadge(status),
          ],
        ),
      ),
    );
  }

  // Handle the confirmation dialog and triggers the controller update
  void _confirmAction(BuildContext context, String action) async {
    Get.dialog(
      AlertDialog(
        title: Text("${action.capitalizeFirst} Request"),
        content: Text("Are you sure you want to $action this request?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Get.back(); // Close the Confirmation Dialog
              debugPrint(
                "--- UI: Attempting to update request_id: ${request['request_id']} ---",
              );
              bool success = await controller.updateRequestStatus(
                request['request_id'],
                action,
              );
              debugPrint("--- UI: Success Signal received: $success ---");

              // If true close the Details Page and go to Todo List
              if (success) {
                debugPrint("--- UI: Closing Details Page now ---");
                Get.back(result: true);
                Get.snackbar(
                  "Success",
                  "Request ${action}ed successfully",
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green.withValues(alpha:0.9),
                  colorText: Colors.white,
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  duration: const Duration(seconds: 2),
                  margin: const EdgeInsets.all(15),
                );
              } else {
                debugPrint("--- UI: Stay on page (Update failed) ---");
              }
            },
            child: Text(
              "Confirm",
              style: TextStyle(
                color: action == 'reject' ? Colors.red : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty) return "N/A";
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(date.toString()));
    } catch (e) {
      return date.toString();
    }
  }

  // UI Components

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blueGrey,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'approved'
        ? Colors.green
        : (status == 'rejected' ? Colors.red : Colors.orange);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Column(
        children: [
          const Text(
            "REQUEST STATUS",
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
