import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/controller/new.leave.controller.dart';

class NewLeavesRequestScreen extends StatelessWidget {
  const NewLeavesRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller
    final controller = Get.put(NewLeavesRequestController());
    const Color primaryBlue = Color(0xFF004E96);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'New Leave Request',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. LEAVE TYPE (Dynamic from DB) ---
              _buildLabel('Leave Type', isRequired: true),
              _buildDynamicDropdown(controller),
              const SizedBox(height: 20),

              // --- 2. DURATION (Professional Picker) ---
              _buildLabel('Duration', isRequired: true),
              GestureDetector(
                onTap: () => controller.openDatePicker(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: primaryBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(() => Text(
                          "${controller.formatDate(controller.selectedFromDate.value)}  ➔  ${controller.formatDate(controller.selectedToDate.value)}",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        )),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              
              // --- 3. DAYS COUNT BADGE ---
              const SizedBox(height: 12),
              Obx(() {
                 int days = controller.leaveDuration;
                 return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: days > 0 ? primaryBlue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: days > 0 ? primaryBlue : Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        days > 0 ? "Total: $days working days" : "Select dates (Weekends excluded)",
                        style: TextStyle(
                          color: days > 0 ? primaryBlue : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),

              // --- 4. REASON INPUT ---
              _buildLabel('Reason', isRequired: true),
              TextFormField(
                controller: controller.reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter reason for leave...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (v) => (v == null || v.length < 5) ? "Reason is too short" : null,
              ),
              const SizedBox(height: 20),

              // --- 5. FILE UPLOAD (Hybrid) ---
              _buildLabel('Supporting Document (Optional)', isRequired: false),
              Obx(() => controller.selectedFile.value == null
                ? GestureDetector(
                    onTap: () => controller.showUploadOptions(context),
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, color: primaryBlue),
                          const SizedBox(width: 10),
                          Text("Upload File or Photo", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            controller.supportingDocFileName.value,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: controller.removeFile,
                        )
                      ],
                    ),
                  )
              ),
              const SizedBox(height: 40),

              // --- 6. SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: controller.applyLeave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Submit Application',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildLabel(String text, {required bool isRequired}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(children: [
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        if (isRequired) const Text(' *', style: TextStyle(color: Colors.red)),
      ]),
    );
  }

  // The Dynamic Dropdown Widget
Widget _buildDynamicDropdown(NewLeavesRequestController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Obx(() {
        // 1. Loading State
        if (controller.isLoadingTypes.value) {
          return const SizedBox(
            height: 50,
            child: Center(child: LinearProgressIndicator(color: Color(0xFF004E96))),
          );
        }

        // 2. Empty State (Safety)
        if (controller.leaveTypesList.isEmpty) {
          return const SizedBox(
            height: 50,
            child: Center(child: Text("No leave types found")),
          );
        }
        
        // 3. The Dropdown
        return DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            // Ensure the value actually exists in the list, otherwise null
            value: controller.leaveTypesList.any((i) => i['id'] == controller.selectedLeaveTypeId.value) 
                ? controller.selectedLeaveTypeId.value 
                : null,
                
            hint: const Text("Select Leave Type"),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
            
            items: controller.leaveTypesList.map((item) {
              return DropdownMenuItem<int>(
                value: item['id'], 
                child: Text(
                  item['name'], 
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }).toList(),
            
            onChanged: (int? newValue) {
              controller.setLeaveType(newValue);
            },
          ),
        );
      }),
    );
  }
}