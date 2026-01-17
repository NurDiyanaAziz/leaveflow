import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:leaveflow/app/services/leave_api_service.dart';
import 'package:leaveflow/app/services/api.service.dart';

class NewLeaveRequestScreen extends StatefulWidget {
  const NewLeaveRequestScreen({super.key});

  @override
  State<NewLeaveRequestScreen> createState() => _NewLeaveRequestScreenState();
}

class _NewLeaveRequestScreenState extends State<NewLeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;
  
  // Form fields
  String? selectedLeaveType;
  int? selectedLeaveTypeId;
  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController reasonController = TextEditingController();
  
  // File attachment
  PlatformFile? selectedFile;
  
  // Leave types
  List<Map<String, dynamic>> leaveTypes = [];
  bool isLoadingTypes = true;
  bool isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    _loadLeaveTypes();
  }
  
  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }
  
  Future<void> _loadLeaveTypes() async {
    setState(() => isLoadingTypes = true);
    
    try {
      final balance = await LeaveApiService.getLeaveBalance();
      print("DEBUG: API RESPONSE: $balance");
      setState(() {
        leaveTypes = balance;
        isLoadingTypes = false;
      });
    } catch (e) {
      setState(() => isLoadingTypes = false);
      print('Error loading leave types: $e');
    }
  }
  
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Check file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 5MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        setState(() {
          selectedFile = file;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File selected: ${file.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _removeFile() {
    setState(() {
      selectedFile = null;
    });
  }
  
  int _calculateDays() {
    if (startDate == null || endDate == null) return 0;
    
    int days = 0;
    DateTime current = startDate!;
    
    while (current.isBefore(endDate!) || current.isAtSameMomentAs(endDate!)) {
      // Skip weekends (Saturday = 6, Sunday = 7)
      if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
        days++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    return days;
  }
  
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (selectedLeaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a leave type')),
      );
      return;
    }
    
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }
    
    setState(() => isSubmitting = true);
    
    try {
      final days = _calculateDays();
      
      // Create FormData for file upload
      FormData formData = FormData.fromMap({
        'user_id': user!.uid,
        'leave_type_id': selectedLeaveTypeId,
        'start_date': startDate!.toIso8601String().split('T')[0],
        'end_date': endDate!.toIso8601String().split('T')[0],
        'days_requested': days,  // CHANGED from 'days' to 'days_requested'
        'reason': reasonController.text,
        'status': 'Pending',
      });
      
      
      if (selectedFile != null) {
        if (selectedFile!.bytes != null) {
          // Web/Desktop - use bytes
          formData.files.add(
            MapEntry(
              'attachment',
              MultipartFile.fromBytes(
                selectedFile!.bytes!,
                filename: selectedFile!.name,
              ),
            ),
          );
        } else if (selectedFile!.path != null) {
          // Android/iOS - use path
          formData.files.add(
            MapEntry(
              'attachment',
              await MultipartFile.fromFile(
                selectedFile!.path!,
                filename: selectedFile!.name,
              ),
            ),
          );
        }
      }
      
      // Submit to API using postDio for FormData
      final response = await api.postDio('/users/leave-request', formData);
      
      if (response?.statusCode == 201 || response?.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leave request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to submit request');
      }
      
    } catch (e) {
      print('Error submitting request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final calculatedDays = _calculateDays();
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () async {
            // Show confirmation dialog
            final shouldPop = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Discard changes?'),
                  content: const Text('If you go back now, your leave request details will be lost.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false); // Return 'false' to dialog
                      },
                      child: const Text('Keep Editing'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, true); // Return 'true' to dialog
                      },
                      child: const Text(
                        'Discard', 
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                );
              },
            );

            // If user clicked "Discard" (true), go back to previous screen
            if (shouldPop == true) {
              if (mounted) Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'New Leave Request',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoadingTypes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leave Type Selection
                    _buildSectionTitle('Leave Type'),
                    const SizedBox(height: 8),
                    _buildLeaveTypeSelector(),
                    const SizedBox(height: 24),
                    
                    // Date Selection
                    _buildSectionTitle('Duration'),
                    const SizedBox(height: 8),
                    _buildDateSelector(),
                    const SizedBox(height: 16),
                    
                    // Days Calculation
                    if (calculatedDays > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            Text(
                              'Total: $calculatedDays working day${calculatedDays > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    
                    // Reason
                    _buildSectionTitle('Reason'),
                    const SizedBox(height: 8),
                    _buildReasonField(),
                    const SizedBox(height: 24),
                    
                    // File Attachment
                    _buildSectionTitle('Attachment (Optional)'),
                    const SizedBox(height: 8),
                    _buildFileAttachment(),
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Request',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
  
  Widget _buildLeaveTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: leaveTypes.map((type) {
          final isSelected = selectedLeaveType == type['leave_type'];
          final available = (type['available'] ?? 0).toInt();
          
          return InkWell(
            onTap: () {
              setState(() {
                selectedLeaveType = type['leave_type'];
                selectedLeaveTypeId = type['leave_type_id'];

                print("Selected ID: $selectedLeaveTypeId");
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[50] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.blue[700]! : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.blue[700] : Colors.grey[400],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type['leave_type'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.blue[900] : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$available days available',
                          style: TextStyle(
                            fontSize: 13,
                            color: available > 0 ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildDateField(
            label: 'Start Date',
            date: startDate,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() {
                  startDate = picked;
                  if (endDate != null && endDate!.isBefore(startDate!)) {
                    endDate = null;
                  }
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _buildDateField(
            label: 'End Date',
            date: endDate,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: endDate ?? startDate ?? DateTime.now(),
                firstDate: startDate ?? DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() {
                  endDate = picked;
                });
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null ? _formatDate(date) : 'Select date',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: date != null ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReasonField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: reasonController,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'Please provide a reason for your leave...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please provide a reason for your leave';
          }
          if (value.trim().length < 10) {
            return 'Reason must be at least 10 characters';
          }
          return null;
        },
      ),
    );
  }
  
  Widget _buildFileAttachment() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedFile == null) ...[
            InkWell(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!, style: BorderStyle.solid, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, color: Colors.blue[700], size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Document',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PDF, JPG, PNG (Max 5MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.insert_drive_file, color: Colors.green[700], size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedFile!.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[900],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _removeFile,
                    icon: Icon(Icons.close, color: Colors.red[700]),
                    tooltip: 'Remove file',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}