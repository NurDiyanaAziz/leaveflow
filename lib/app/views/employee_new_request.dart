import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/controller/emp_new_request.controller.dart';

class NewLeavesRequestScreen extends StatelessWidget {
  const NewLeavesRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final NewLeavesRequestController controller = Get.put(
      NewLeavesRequestController(),
    );

    // Define the primary blue color from the previous screen
    const Color primaryBlue = Color.fromARGB(255, 0, 78, 150);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // The image shows a custom header, but we'll use a standard AppBar for simplicity
        // The back arrow and title are visible.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: controller.cancelRequest,
          color: Colors.black,
        ),
        title: const Text(
          'New Leaves Request',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- 1. Type of Leaves Dropdown ---
              _buildLabel('Type of Leaves', isRequired: true),
              _buildLeaveTypeDropdown(controller, primaryBlue),
              const SizedBox(height: 25),

              // --- 2. Reason Text Field ---
              _buildLabel('Reason', isRequired: true),
              _buildReasonTextField(controller),
              const SizedBox(height: 25),

              // --- 3. From Date Picker ---
              _buildLabel('From', isRequired: true),
              _buildDatePickerField(
                context,
                controller,
                primaryBlue,
                isFromDate: true,
              ),
              const SizedBox(height: 25),

              // --- 4. To Date Picker (The image shows the calendar appearing here) ---
              _buildLabel('To', isRequired: true),
              _buildDatePickerField(
                context,
                controller,
                primaryBlue,
                isFromDate: false,
              ),

              // 5. Duration display
              Obx(() {
                int days = controller.leaveDuration;
                return Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: primaryBlue.withValues(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Leave Duration: $days ${days == 1 ? 'working day' : 'working days'}",
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 5),

              // --- 6. Supporting Doc File Picker ---
              _buildLabel('Supporting Doc', isRequired: false),
              _buildFilePickerField(controller, primaryBlue),
              const SizedBox(height: 40),

              // --- 6. Apply and Cancel Buttons ---
              _buildActionButtons(controller, primaryBlue),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (isRequired)
            const Text(
              '*',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaveTypeDropdown(
    NewLeavesRequestController controller,
    Color primaryBlue,
  ) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: controller.selectedLeaveType.value,
            icon: const Icon(Icons.keyboard_arrow_down),
            isExpanded: true,
            style: const TextStyle(color: Colors.black, fontSize: 16),
            onChanged: (String? newValue) {
              if (newValue != null) {
                controller.selectedLeaveType.value = newValue;
              }
            },
            items: controller.leaveTypes.map<DropdownMenuItem<String>>((
              String value,
            ) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildReasonTextField(NewLeavesRequestController controller) {
    return TextFormField(
      controller: controller.reasonController,
      decoration: InputDecoration(
        hintText: 'Enter reason for leave',
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 15,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Reason is required.';
        }
        return null;
      },
    );
  }

  Widget _buildDatePickerField(
    BuildContext context,
    NewLeavesRequestController controller,
    Color primaryBlue, {
    required bool isFromDate,
  }) {
    return GestureDetector(
      onTap: () => controller.selectDateRange(context),
      child: Obx(
        () => Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                controller.formatDate(
                  isFromDate
                      ? controller.selectedFromDate.value
                      : controller.selectedToDate.value,
                ),
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              Icon(Icons.calendar_today, color: primaryBlue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePickerField(
    NewLeavesRequestController controller,
    Color primaryBlue,
  ) {
    return Obx(
      () => GestureDetector(
        onTap: () => controller.showUploadOptions(Get.context!),
        child: Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: controller.selectedFile.value != null
                  ? primaryBlue
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  controller.supportingDocFileName.value,
                  style: TextStyle(
                    fontSize: 16,
                    color: controller.selectedFile.value != null
                        ? Colors.black
                        : Colors.black54,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Icon(
                controller.selectedFile.value != null
                    ? Icons.check_circle
                    : Icons.attach_file,
                color: controller.selectedFile.value != null
                    ? Colors.green
                    : primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    NewLeavesRequestController controller,
    Color primaryBlue,
  ) {
    return Row(
      children: [
        // Apply Button
        Expanded(
          child: ElevatedButton(
            onPressed: controller.applyLeave,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Apply',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 15),
        // Cancel Button
        Expanded(
          child: OutlinedButton(
            onPressed: controller.cancelRequest,
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: BorderSide(color: primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 18, color: primaryBlue),
            ),
          ),
        ),
      ],
    );
  }
}
