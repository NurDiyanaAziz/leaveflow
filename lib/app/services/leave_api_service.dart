import 'package:firebase_auth/firebase_auth.dart';
import 'package:leaveflow/app/services/api.service.dart';

class LeaveApiService {
  // Existing getLeaveBalance method stays the same...
  static Future<List<Map<String, dynamic>>> getLeaveBalance() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await api.getDio('/users/leave-balance?userId=${user.uid}');
      
      if (response?.statusCode == 200) {
        final data = response?.data;
        
        if (data != null && data['success'] == true) {
          List<Map<String, dynamic>> balances = [];
          
          var dataArray = data['data'];
          
          for (var item in dataArray) {
            double available = _parseDouble(item['available']);
            double used = _parseDouble(item['used']);
            int total = _parseInt(item['total']);
            
            balances.add({
              'leave_type': item['leave_type'],
              'leave_type_id': item['leave_type_id'],
              'available': available,
              'used': used,
              'total': total,
            });
          }
          
          print('✅ Successfully loaded ${balances.length} leave types');
          return balances;
        }
      }
      
      throw Exception('Failed to load leave balance');
    } catch (e) {
      print('❌ Error in getLeaveBalance: $e');
      rethrow;
    }
  }

  // Get recent leave requests (for employee dashboard)
  static Future<List<Map<String, dynamic>>> getRecentRequests({int limit = 3}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('🔵 Fetching recent requests for user: ${user.uid}');
      
      
      final response = await api.getDio('/users/leave-requests?userId=${user.uid}&limit=$limit');
      
      if (response?.statusCode == 200) {
        final data = response?.data;
        
        if (data != null && data['success'] == true) {
          List<Map<String, dynamic>> requests = [];
          
          var dataArray = data['data'] ?? [];
          
          for (var item in dataArray) {
            requests.add({
              'id': item['id'],
              'leave_type': item['leave_type'] ?? 'Unknown',
              'start_date': item['start_date'],
              'end_date': item['end_date'],
              'days': _parseDouble(item['days']),
              'status': item['status'] ?? 'Pending',
              'reason': item['reason'] ?? '',
              'created_at': item['created_at'],
            });
          }
          
          print('✅ Successfully loaded ${requests.length} recent requests');
          return requests;
        }
      }
      
      // Return empty list if endpoint doesn't exist yet
      print('⚠️ Leave requests endpoint not available yet');
      return [];
      
    } catch (e) {
      print('❌ Error in getRecentRequests: $e');
      // Return empty list instead of throwing to prevent app crash
      return [];
    }
  }

  //Get all leave requests history
  static Future<List<Map<String, dynamic>>> getAllRequests({String? status}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('🔵 Fetching all requests for user: ${user.uid}');
      
      String endpoint = '/users/leave-requests?userId=${user.uid}';
      if (status != null && status != 'All') {
        endpoint += '&status=$status';
      }
      
      final response = await api.getDio(endpoint);
      
      if (response?.statusCode == 200) {
        final data = response?.data;
        
        if (data != null && data['success'] == true) {
          List<Map<String, dynamic>> requests = [];
          
          var dataArray = data['data'] ?? [];
          
          for (var item in dataArray) {
            requests.add({
              'id': item['id'],
              'leave_type': item['leave_type'] ?? 'Unknown',
              'start_date': item['start_date'],
              'end_date': item['end_date'],
              'days': _parseDouble(item['days']),
              'status': item['status'] ?? 'Pending',
              'reason': item['reason'] ?? '',
              'created_at': item['created_at'],
              'manager_remarks': item['manager_remarks'],
            });
          }
          
          print('✅ Successfully loaded ${requests.length} requests');
          return requests;
        }
      }
      
      return [];
      
    } catch (e) {
      print('❌ Error in getAllRequests: $e');
      return [];
    }
  }

  static Future<bool> cancelRequest(int requestId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // 👇 FIXED: Changed 'dio.post' to 'api.postDio'
      // Also removed the named parameter 'data:' because your wrapper likely expects arguments like (url, body)
      final response = await api.postDio('/users/cancel-request', {
        'requestId': requestId,
        'userId': user.uid, 
      });

      return response?.statusCode == 200 && response?.data['success'] == true;
    } catch (e) {
      print('Cancel Error: $e');
      return false;
    }
  }
  
  // Helper functions
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}