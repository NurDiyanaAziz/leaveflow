import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/services/api.service.dart';
import 'package:leaveflow/app/services/sharedprefs.dart';

class ProfileController extends GetxController {
  final ApiServices api = ApiServices();
  
  var isLoading = true.obs;
  var userProfile = {}.obs; // Stores the JSON data from MySQL

  // Editable Text Controllers
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  // 1. Fetch Data from API
  void fetchUserProfile() async {
    try {
      isLoading(true);
      String? uid = await SharedPrefs.getLocalStorage('uid');
      
      if (uid == null) {
        Get.snackbar("Error", "Session expired. Please login again.");
        return;
      }

      // Call the GET endpoint we just tested
      var response = await api.getJson('/users/profile/$uid');

      if (response != null && response.statusCode == 200) {
        var data = response.data['data'];
        userProfile.value = data;
        
        // Pre-fill the editable text fields so they aren't empty
        phoneController.text = data['phone'] ?? '';
        addressController.text = data['address'] ?? '';
      }
    } catch (e) {
      print("Profile Error: $e");
      Get.snackbar("Error", "Failed to load profile");
    } finally {
      isLoading(false);
    }
  }

  // 2. Update Data (Save Changes)
  void updateProfile() async {
    try {
      String? uid = await SharedPrefs.getLocalStorage('uid');
      
      // Call the POST endpoint we just tested
      var response = await api.postJson('/users/profile/update', {
        'uid': uid,
        'phone': phoneController.text,
        'address': addressController.text,
      });

      if (response != null && response.statusCode == 200) {
        Get.snackbar("Success", "Profile updated successfully!");
        // Refresh the data to show latest changes
        fetchUserProfile(); 
      } else {
        Get.snackbar("Error", "Failed to update profile.");
      }
    } catch (e) {
      Get.snackbar("Error", "Connection failed.");
    }
  }
}