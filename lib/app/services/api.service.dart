import 'package:dio/dio.dart';
import 'package:leaveflow/app/services/sharedprefs.dart';

final ApiServices api = ApiServices();

class ApiServices {
  var baseUrl = 'http://10.0.2.2:3000/api'; //emulator
  //var baseUrl = 'http://x.x.x.x:3000/api'; //real device testing,1. cmd and ipconfig ,get ipv4 and replace in baseUrl

  Future<Response?> getDio(String path) async {
    try {
      String? token = await SharedPrefs.getLocalStorage('token') ?? '';
      String url = baseUrl + path;
      
      print('🌐 Making request to: $url');
      
      var headers = {
        'accept': 'application/json',
        'authorization': 'Bearer $token',
      };
      
      var dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);
      
      var response = await dio.get(
        url, 
        options: Options(headers: headers),
      );
      
      print('✅ Response received: ${response.statusCode}');
      return response;
      
    } on DioException catch (e) {
      print('❌ DioException occurred:');
      print('❌ Type: ${e.type}');
      print('❌ Message: ${e.message}');
      print('❌ Error: ${e.error}');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        print('❌ CONNECTION TIMEOUT - Backend not reachable');
      } else if (e.type == DioExceptionType.connectionError) {
        print('❌ CONNECTION ERROR - Check if backend is running');
        print('❌ Make sure backend is running on port 3000');
        print('❌ Try changing baseUrl to your computer\'s IP address');
      }
      
      rethrow;
      
    } catch (e) {
      print('❌ Unexpected error: $e');
      rethrow;
    }
  }

  Future<Response?> putDio(String path, Map<String, dynamic> data) async {
    String? token = await SharedPrefs.getLocalStorage('token') ?? '';
    String url = baseUrl + path;
    var headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
      'authorization': 'Bearer $token',
    };
    var response = await Dio().put(
      url,
      data: data,
      options: Options(headers: headers),
    );
    return response;
  }

  Future<Response?> postDio(String path, dynamic formData) async {
    String? token = await SharedPrefs.getLocalStorage('token') ?? '';
    String url = baseUrl + path;
    var headers = {'accept': 'application/json'};
    if (token.isNotEmpty) {
      headers['authorization'] = 'Bearer $token';
    }

    var response = await Dio().post(
      url,
      data: formData,
      options: Options(headers: headers),
    );
    return response;
  }

  Future<Response?> postJson(String path, Map<String, dynamic> data) async {
    String? token = await SharedPrefs.getLocalStorage('token') ?? '';
    String url = baseUrl + path;
    var headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token.isNotEmpty) {
      headers['authorization'] = 'Bearer $token';
    }
    var response = await Dio().post(
      url,
      data: data,
      options: Options(headers: headers),
    );
    return response;
  }

  Future<Response?> getJson(String endpoint) async {
    try {
      String? token = await SharedPrefs.getLocalStorage('token');
      
      // IMPORTANT: Make sure this matches the URL you use in postJson
      // Android Emulator: 'http://10.0.2.2:3000/api'
      // iOS / Web: 'http://localhost:3000/api'

      var response = await Dio().get(
        '$baseUrl$endpoint',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          // This prevents the app from crashing on 404/500 errors
          validateStatus: (status) => status! < 500,
        ),
      );
      return response;
    } catch (e) {
      print("API GET Error: $e");
      return null;
    }
  }

  // PUT Request (Updates data on the server)
  Future<Response?> putJson(String endpoint, Map<String, dynamic> data) async {
    try {
      // 1. Get Token
      String? token = await SharedPrefs.getLocalStorage('token');
      var dio = Dio();
      
      // 2. Set Headers
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-Type'] = 'application/json';

      // 3. Make the Request
      final response = await dio.put(
        baseUrl + endpoint, // e.g., http://192.168.x.x:3000/api/manager/request/22
        data: data,
      );
      
      return response;
    } on DioException catch (e) {
      // Handle standard Dio errors
      print("❌ API PUT Error: ${e.response?.statusCode} - ${e.message}");
      // Return the error response so the controller can read the message (e.g., "Missing UID")
      return e.response;
    } catch (e) {
      print("❌ Unexpected API Error: $e");
      return null;
    }
  }
}
