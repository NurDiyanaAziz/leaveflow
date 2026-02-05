import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:leaveflow/app/services/api.service.dart';

class LeaveApiService {
  // Existing getLeaveBalance method stays the same...
  // static Future<List<Map<String, dynamic>>> getLeaveBalance() async {
  //   try {
  //     final user = FirebaseAuth.instance.currentUser;
  //     if (user == null) {
  //       throw Exception('User not authenticated');
  //     }

  //     final response = await api.getDio('/users/leave-balance?userId=${user.uid}');
      
  //     if (response?.statusCode == 200) {
  //       final data = response?.data;
        
  //       if (data != null && data['success'] == true) {
  //         List<Map<String, dynamic>> balances = [];
          
  //         var dataArray = data['data'];
          
  //         for (var item in dataArray) {
  //           double available = _parseDouble(item['available']);
  //           double used = _parseDouble(item['used']);
  //           int total = _parseInt(item['total']);
            
  //           balances.add({
  //             'leave_type': item['leave_type'],
  //             'leave_type_id': item['leave_type_id'],
  //             'available': available,
  //             'used': used,
  //             'total': total,
  //           });
  //         }
          
  //         print('✅ Successfully loaded ${balances.length} leave types');
  //         return balances;
  //       }
  //     }
      
  //     throw Exception('Failed to load leave balance');
  //   } catch (e) {
  //     print('❌ Error in getLeaveBalance: $e');
  //     rethrow;
  //   }
  // }

  // Get Leave Balance for specific user
  static Future<List<Map<String, dynamic>>> getLeaveBalance() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      // Call the endpoint: /users/:uid/balance
      // Make sure this matches your backend route prefix!
      final response = await api.getDio('/users/${user.uid}/balance');

      if (response?.statusCode == 200) {
        final data = response?.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print("❌ Error fetching balance: $e");
      return [];
    }
  }

  static Future<int> getPendingCount() async {
    try {
      // Make sure the path matches your route setup (likely /requests/pending-count)
      final response = await api.getDio('/requests/pending-count');
      
      if (response?.statusCode == 200) {
        final data = response?.data;
        // The API returns { "count": 5 }
        if (data is Map && data.containsKey('count')) {
          return (data['count'] ?? 0) as int;
        }
      }
      return 0;
    } catch (e) {
      print("❌ Error fetching pending count: $e");
      return 0;
    }
  }

  // Get recent leave requests (for employee dashboard)
// Get recent leave requests (for employee dashboard)
  static Future<List<Map<String, dynamic>>> getRecentRequests({int limit = 3}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('🔵 Fetching recent requests for user: ${user.uid}');
      
      // Request slightly more items (limit * 2) from backend to ensure we have enough
      // left after we hide the "Cancelled" ones.
      final response = await api.getDio('/users/leave-requests?userId=${user.uid}&limit=${limit * 2}');
      
      if (response?.statusCode == 200) {
        final data = response?.data;
        
        if (data != null && data['success'] == true) {
          List<Map<String, dynamic>> requests = [];
          
          var dataArray = data['data'] ?? [];
          
          for (var item in dataArray) {
            // 🔴 FILTER HERE: Skip if status is 'Cancelled'
            if (item['status'] == 'Cancelled') {
              continue; 
            }

            requests.add({
              'id': item['id'],
              'leave_type': item['leave_type'] ?? 'Unknown',
              'start_date': item['start_date'],
              'end_date': item['end_date'],
              'days': _parseDouble(item['days']),
              'status': item['status'] ?? 'Pending',
              'reason': item['reason'] ?? '',
              'created_at': item['created_at'],
              'manager_remarks': item['manager_remarks'], // Added this useful field
              'attachment_url': item['attachment_url'],   // Added this for details screen
            });

            // Stop once we have filled our limit (e.g., 3 items)
            if (requests.length >= limit) break;
          }
          
          print('✅ Successfully loaded ${requests.length} active recent requests');
          return requests;
        }
      }
      
      print('⚠️ Leave requests endpoint returned invalid data');
      return [];
      
    } catch (e) {
      print('❌ Error in getRecentRequests: $e');
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

static Future<List<Map<String, dynamic>>> getPublicHolidays() async {
    try {
      // Make sure this path matches your backend (likely /requests/public-holidays)
      final response = await api.getDio('/requests/public-holidays'); 
      
      if (response?.statusCode == 200) {
        dynamic data = response?.data;

        // 🛡️ SAFETY CHECK 1: If data is a String (e.g., "Success"), decode it
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (e) {
            print("⚠️ API returned a non-JSON string: $data");
            return [];
          }
        }

        // 🛡️ SAFETY CHECK 2: If data is a List [ {...}, {...} ]
        if (data is List) {
          return data.map((e) {
             // Handle case where an item inside the list is not a Map
             if (e is Map) return Map<String, dynamic>.from(e);
             return <String, dynamic>{}; 
          }).toList();
        } 
        
        // 🛡️ SAFETY CHECK 3: If data is a Map { "data": [...] }
        else if (data is Map && data.containsKey('data')) {
           var list = data['data'];
           if (list is List) {
             return list.map((e) {
               if (e is Map) return Map<String, dynamic>.from(e);
               return <String, dynamic>{};
             }).toList();
           }
        }
      }
      return [];
    } catch (e) {
      print("❌ Error fetching holidays: $e");
      return [];
    }
  }

static Future<List<Map<String, dynamic>>> getCalendarHolidays() async {
    try {
      // Call the NEW endpoint
      final response = await api.getDio('/requests/calendar-holidays'); 
      
      if (response?.statusCode == 200) {
         var data = response?.data;
         if (data is List) {
           return data.map((e) => Map<String, dynamic>.from(e)).toList();
         }
      }
      return [];
    } catch (e) {
      print("❌ Error fetching calendar holidays: $e");
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