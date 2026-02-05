import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:leaveflow/app/widgets/calendarpicker.widget.dart';

class NewLeavesRequestController extends GetxController {
  // --- VARIABLES ---
  
  // 1. Leave Types (Dynamic List of Maps)
  // Structure: [{"id": 1, "name": "Annual Leave"}, ...]
  var leaveTypesList = <Map<String, dynamic>>[].obs;
  var isLoadingTypes = true.obs;
  
  // 2. Selected Value
  // We store the ID (int) for logic, and Name (String) for display if needed
  var selectedLeaveTypeId = Rxn<int>(); 
  var selectedLeaveTypeName = "".obs; 

  // Form & Date Variables
  final TextEditingController reasonController = TextEditingController();
  final Rx<DateTime> selectedFromDate = DateTime.now().obs;
  final Rx<DateTime> selectedToDate = DateTime.now().obs;
  final Rx<File?> selectedFile = Rx<File?>(null);
  final RxString supportingDocFileName = 'No file selected'.obs;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Holidays Data
  var fetchedHolidays = <DateTime>[].obs; 
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    // 🚀 Fetch BOTH Data Sources on Load
    fetchLeaveTypes();
    fetchPublicHolidays();
  }

  // --- API 1: FETCH LEAVE TYPES ---
// --- API 1: FETCH LEAVE TYPES ---
  Future<void> fetchLeaveTypes() async {
    try {
      isLoadingTypes.value = true;
      
      // Keep your working URL (from your logs)
      final url = Uri.parse('http://10.0.2.2:3000/api/requests/leave-types'); 
      
      print("🚀 SENDING REQUEST TO: $url");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        
        // 1. Convert and Assign Data Correctly using .assignAll()
        List<Map<String, dynamic>> loadedTypes = data.map((item) => {
          "id": item["id"],
          "name": item["name"].toString()
        }).toList();

        leaveTypesList.assignAll(loadedTypes); // <--- THIS FIXES THE UI UPDATE

        // 2. Set Default Selection (First Item)
        if (leaveTypesList.isNotEmpty) {
          selectedLeaveTypeId.value = leaveTypesList[0]['id'];
          
          // Update the Name for the "Medical Leave" validation logic
          var item = leaveTypesList[0];
          selectedLeaveTypeName.value = item['name']; 
        }
      } else {
        print("❌ Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching types: $e");
      Get.snackbar("Error", "Failed to load leave types");
    } finally {
      isLoadingTypes.value = false;
    }
  }
  // --- API 2: FETCH HOLIDAYS (Existing) ---
  Future<void> fetchPublicHolidays() async {
    try {
      final url = Uri.parse('http://10.0.2.2:3000/api/requests/public-holidays'); 
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> dateStrings = json.decode(response.body);
        fetchedHolidays.value = dateStrings.map((d) => DateTime.parse(d)).toList();
      }
    } catch (e) {
      print("Error holidays: $e");
    }
  }

  // --- LOGIC: DURATION CALCULATION ---
  int get leaveDuration {
    if (selectedToDate.value.isBefore(selectedFromDate.value)) return 0;
    int days = 0;
    DateTime tempDate = selectedFromDate.value;
    DateTime endDate = selectedToDate.value;

    while (tempDate.isBefore(endDate) || tempDate.isAtSameMomentAs(endDate)) {
      bool isWeekend = tempDate.weekday == 6 || tempDate.weekday == 7;
      bool isHoliday = fetchedHolidays.any((h) => 
        h.year == tempDate.year && h.month == tempDate.month && h.day == tempDate.day
      );
      if (!isWeekend && !isHoliday) days++;
      tempDate = tempDate.add(const Duration(days: 1));
    }
    return days;
  }

  // --- LOGIC: DATE PICKER ---
  Future<void> openDatePicker(BuildContext context) async {
    // Check if "Medical" or "Sick" is selected
    bool isMedical = selectedLeaveTypeName.value.toLowerCase().contains('sick') || 
                     selectedLeaveTypeName.value.toLowerCase().contains('hospitalization') ||
                     selectedLeaveTypeName.value.toLowerCase().contains('medical');
    
    DateTime limitDate;
    
    if (isMedical) {
      // Rule: Sick leave can be applied for the past (e.g., up to 60 days ago)
      limitDate = DateTime.now().subtract(const Duration(days: 60));
    } else {
      // Rule: Annual/Other leave MUST be Today or Future
      limitDate = DateTime.now();
    }

    await Get.bottomSheet(
      CalendarPicker(
        isMedicalLeave: isMedical,
        initialStartDate: selectedFromDate.value,
        initialEndDate: selectedToDate.value,
        holidays: fetchedHolidays,
        minDate: limitDate,
        onSelectionChanged: (start, end) {
          selectedFromDate.value = start;
          selectedToDate.value = end;
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // --- HELPER: SET LEAVE TYPE ---
  void setLeaveType(int? id) {
    if (id != null) {
      selectedLeaveTypeId.value = id;
      // Find name for logic checks
      var item = leaveTypesList.firstWhere((element) => element['id'] == id);
      selectedLeaveTypeName.value = item['name'];
    }
  }

  // --- FILE PICKER (Unified) ---
  Future<void> pickFile(bool isCamera) async {
    if (isCamera) {
      final XFile? photo = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (photo != null) _setFile(File(photo.path), photo.name);
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']
      );
      if (result != null) _setFile(File(result.files.single.path!), result.files.single.name);
    }
  }

  void _setFile(File file, String name) {
    if (file.lengthSync() > 5 * 1024 * 1024) {
      Get.snackbar("Error", "File > 5MB", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    selectedFile.value = file;
    supportingDocFileName.value = name;
  }

  void showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20), height: 160,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _option(Icons.camera_alt, "Camera", () { Get.back(); pickFile(true); }),
            _option(Icons.folder, "File", () { Get.back(); pickFile(false); }),
          ],
        ),
      ),
    );
  }
  
  Widget _option(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircleAvatar(radius: 25, backgroundColor: Colors.blue[50], child: Icon(icon, color: Colors.blue)),
        const SizedBox(height: 5), Text(label)
      ]),
    );
  }

  void removeFile() { selectedFile.value = null; supportingDocFileName.value = "No file selected"; }

  // --- SUBMIT ---
  // --- 5. SUBMIT LOGIC (Multipart Request) ---
// Future<void> applyLeave() async {
//     // 1. Close Keyboard
//     FocusManager.instance.primaryFocus?.unfocus();

//     if (!formKey.currentState!.validate()) return;
    
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       Get.snackbar("Error", "You are not logged in!", backgroundColor: Colors.red, colorText: Colors.white);
//       return;
//     }

//     try {
//       // 2. Show Loading
//       Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

//       var uri = Uri.parse('http://10.0.2.2:3000/api/users/leave-request');
//       var request = http.MultipartRequest('POST', uri);

//       request.fields['user_id'] = user.uid; 
//       request.fields['leave_type_id'] = selectedLeaveTypeId.value.toString();
//       request.fields['start_date'] = DateFormat('yyyy-MM-dd').format(selectedFromDate.value);
//       request.fields['end_date'] = DateFormat('yyyy-MM-dd').format(selectedToDate.value);
//       request.fields['days_requested'] = leaveDuration.toString();
//       request.fields['reason'] = reasonController.text;

//       if (selectedFile.value != null) {
//         var multipartFile = await http.MultipartFile.fromPath('attachment', selectedFile.value!.path);
//         request.files.add(multipartFile);
//       }

//       var streamedResponse = await request.send();
//       var response = await http.Response.fromStream(streamedResponse);

//       // 3. CLOSE LOADING DIALOG
//       if (Get.isDialogOpen ?? false) Get.back();

//       if (response.statusCode == 201 || response.statusCode == 200) {
        
//         // 🚀 THE FIX: Close the Form Screen IMMEDIATELY
//         Get.back(); 

//         // 5. Show Success Snackbar (Now it appears on the Dashboard)
//         Get.snackbar(
//           "Success", 
//           "Leave request submitted!",
//           backgroundColor: Colors.green, 
//           colorText: Colors.white,
//           duration: const Duration(seconds: 3),
//         );
        
//       } else {
//         var errorData = json.decode(response.body);
//         Get.snackbar("Failed", errorData['message'] ?? "Error", backgroundColor: Colors.red, colorText: Colors.white);
//       }
//     } catch (e) {
//       if (Get.isDialogOpen ?? false) Get.back();
//       print("❌ ERROR: $e");
//       Get.snackbar("Error", "Connection failed", backgroundColor: Colors.red, colorText: Colors.white);
//     }
//   }

Future<void> applyLeave() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!formKey.currentState!.validate()) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar("Error", "You are not logged in!", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

      var uri = Uri.parse('http://10.0.2.2:3000/api/users/leave-request'); // Ensure this matches your route
      var request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = user.uid; 
      request.fields['leave_type_id'] = selectedLeaveTypeId.value.toString();
      request.fields['start_date'] = DateFormat('yyyy-MM-dd').format(selectedFromDate.value);
      request.fields['end_date'] = DateFormat('yyyy-MM-dd').format(selectedToDate.value);
      request.fields['days_requested'] = leaveDuration.toString();
      request.fields['reason'] = reasonController.text;

      if (selectedFile.value != null) {
        var multipartFile = await http.MultipartFile.fromPath('attachment', selectedFile.value!.path);
        request.files.add(multipartFile);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Close Loading Dialog
      if (Get.isDialogOpen ?? false) Get.back();

      if (response.statusCode == 201 || response.statusCode == 200) {
        
        // 🧹 1. CLEANUP: Clear the form fields immediately
        reasonController.clear();
        selectedFile.value = null;
        // Optional: Reset dates to today if you want
         selectedFromDate.value = DateTime.now();
         selectedToDate.value = DateTime.now();
        
        // 🚀 2. THE FIX: Pass 'true' back to the Dashboard
        Get.back(result: true); 

        Get.snackbar(
          "Success", 
          "Leave request submitted!",
          backgroundColor: Colors.green, 
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        
      } else {
        var errorData = json.decode(response.body);
        Get.snackbar("Failed", errorData['message'] ?? "Error", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print("❌ ERROR: $e");
      Get.snackbar("Error", "Connection failed", backgroundColor: Colors.red, colorText: Colors.white);
    }
}

  String formatDate(DateTime? d) => d == null ? '' : DateFormat('d MMM yyyy').format(d);
  
  @override
  void onClose() { reasonController.dispose(); super.onClose(); }
}