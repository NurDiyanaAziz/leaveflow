import 'package:dio/dio.dart';
import 'package:leaveflow/app/services/sharedprefs.dart';

final ApiServices api = ApiServices();

class ApiServices {
  var baseUrl = 'http://10.0.2.2:3000/api';

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

  Future<Response?> postDio(String path, FormData? formData) async {
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
}