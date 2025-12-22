import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class NewLeavesRequestController extends GetxController {
  // --- Form Data Observables ---
  final RxString selectedLeaveType = 'Annual Leave'.obs;
  final TextEditingController reasonController = TextEditingController();
  final Rx<DateTime> selectedFromDate = DateTime.now().obs;
  final Rx<DateTime> selectedToDate = DateTime.now().obs;
  final Rx<File?> selectedFile = Rx<File?>(null);
  final RxString supportingDocFileName = 'No file selected'.obs;
  final ImagePicker _pickers = ImagePicker();

  // --- Dropdown Options ---
  final List<String> leaveTypes = [
    'Annual Leave',
    'Sick Leave',
    'Birthday Leave',
    'Maternity Leave',
  ];

  // --- Form Key ---
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  //calculation for duration exclude weekend
  int get leaveDuration {
    int days = 0;
    DateTime tempDate = selectedFromDate.value;

    //if To date is before From date, return 0
    if (selectedToDate.value.isBefore(selectedFromDate.value)) return 0;

    while (tempDate.isBefore(selectedToDate.value) ||
        tempDate.isAtSameMomentAs(selectedToDate.value)) {
      //6 = saturday, 7 = Sunday
      if (tempDate.weekday != DateTime.saturday &&
          tempDate.weekday != DateTime.sunday) {
        days++;
      }
      tempDate = tempDate.add(const Duration(days: 1));
    }
    return days;
  }

  // --- Date Picker Logic ---
  Future<void> selectDateRange(BuildContext context) async {
    final DateTime now = DateTime.now();

    //user can select 1 day before today
    final DateTime initialDate = now.subtract(const Duration(days: 1));
    final DateTime lastDate = now.add(const Duration(days: 365 * 1));

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: selectedFromDate.value,
        end: selectedToDate.value,
      ),
      firstDate: initialDate,
      lastDate: lastDate,
      helpText: 'Select Leave Period',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 0, 78, 150),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 0, 78, 150),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedFromDate.value = picked.start;
      selectedToDate.value = picked.end;
      // You might want to update the visible calendar display here if you were using a custom calendar
    }
  }

  // --- File Picker Logic ---
  Future<void> _pickFromCamera() async {
    final XFile? photo = await _pickers.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _validateAndSetFile(File(photo.path), photo.name);
    }
  }
  Future<void> _pickFromFiles() async{
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if(result != null && result.files.single.path != null){
      PlatformFile file = result.files.first;
      _validateAndSetFile(File(file.path!), file.name);
    }
  }
  void _validateAndSetFile(File file, String fileName){
    const int maxSizeInBytes = 50 * 1024 * 1024; //50mb
    final int fileSize = file.lengthSync();

    if(fileSize > maxSizeInBytes){
      Get.snackbar('File too large', 'Maximum file size is 50MB.',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      );
      return;
    }
    selectedFile.value = file;
    supportingDocFileName.value = fileName;
  }

  void showUploadOptions(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Get.back();
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Upload Files (PDF, PNG, JPG)'),
              onTap: () {
                Get.back();
                _pickFromFiles();
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Action Button Logic ---
  void applyLeave() {
    if (formKey.currentState!.validate()) {
      Get.snackbar(
        'Success',
        'Leave request applied from ${selectedFromDate.value.day}/${selectedFromDate.value.month} to ${selectedToDate.value.day}/${selectedToDate.value.month}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      // Implement API call to submit data here
    }
  }

  void cancelRequest() {
    Get.back(); // Navigate back to the previous screen (e.g., Leave Page)
  }

  // --- Utility for Date Formatting (to match the image) ---
  String formatDate(DateTime? date) {
    if (date == null) return '';
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    String day = date.day.toString();
    String month = monthNames[date.month - 1];
    String year = date.year.toString();
    return '$day${day.endsWith('1') && day != '11'
        ? 'st'
        : day.endsWith('2') && day != '12'
        ? 'nd'
        : day.endsWith('3') && day != '13'
        ? 'rd'
        : 'th'} $month $year';
  }

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }
}

