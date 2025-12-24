import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:leaveflow/app/services/api.service.dart';

class ManagerLeaveController extends GetxController {
  // Observables for the UI
  var pendingRequests = [].obs;
  var historyRequests = [].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLeaveRequests(); // Load data when manager dashboard opens
  }

  // Main refresh function used by Pull-to-Refresh and Tab switching
  Future<void> fetchLeaveRequests() async {
    isLoading.value = true;
    try {
      // Runs both requests simultaneously
      await Future.wait([_fetchPending(), _fetchHistory()]);
    } catch (e) {
      debugPrint("Error refreshing all data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Pending requests
  Future<void> _fetchPending() async {
    try {
      final response = await api.getDio('/manager/requests/pending');
      if (response != null && response.statusCode == 200) {
        pendingRequests.assignAll(response.data['requests'] ?? []);
      }
    } catch (e) {
      debugPrint("Error fetching pending: $e");
    }
  }

  // History requests
  Future<void> _fetchHistory() async {
    try {
      final response = await api.getDio('/manager/requests/history');
      if (response != null && response.statusCode == 200) {
        historyRequests.assignAll(response.data['requests'] ?? []);
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    }
  }

  // Update request status (Approve/Reject)
  Future<bool> updateRequestStatus(dynamic requestId, String action) async {
    try {
      debugPrint("--- CONTROLLER: Received request for ID: $requestId ---");

      // 1. Ensure ID is a valid number
      final int id = int.parse(requestId.toString());

      // 2. BACKEND SYNC: 'approve','reject' manager_route.js
      String apiAction = action.toLowerCase().contains('app')
          ? 'approve'
          : 'reject';
      debugPrint("--- CONTROLLER: Sending action '$apiAction' to Backend ---");

      final response = await api.putDio('/manager/request/$id', {
        'action': apiAction,
      });

      if (response != null && response.statusCode == 200) {
        debugPrint("--- CONTROLLER: API SUCCESS (200) ---");

        // Refresh the local data so the dashboard is ready
        await fetchLeaveRequests();
        return true;
      }

      debugPrint(
        "--- CONTROLLER: API Failed with status: ${response?.statusCode} ---",
      );
      return false;
    } catch (e) {
      debugPrint("--- CONTROLLER ERROR: $e ---");
      return false;
    }
  }
}
