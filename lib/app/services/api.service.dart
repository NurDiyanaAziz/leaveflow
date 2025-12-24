import 'package:dio/dio.dart';
import 'package:leaveflow/app/services/sharedprefs.dart';

final ApiServices api = ApiServices();

class ApiServices {
  var baseUrl = 'http://10.0.2.2:3000/api';

  // For fetching lists (TODO and HISTORY)
  Future<Response?> getDio(String path) async {
    String? token = await SharedPrefs.getLocalStorage('token') ?? '';
    String url = baseUrl + path;
    var headers = {
      'accept': 'application/json',
      'authorization': 'Bearer $token',
    };

    var response = await Dio().get(url, options: Options(headers: headers));

    return response;
  }

  // For approving or rejecting requests
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

  //create Post Dio
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

  // param different
  Future<Response?> postJson(String path, Map<String, dynamic> data) async {
    String? token = await SharedPrefs.getLocalStorage('token') ?? '';
    String url = baseUrl + path;

    var headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json', // Important for JSON payload
    };

    if (token.isNotEmpty) {
      headers['authorization'] = 'Bearer $token';
    }

    var response = await Dio().post(
      url,
      data: data, // Send the Map directly as JSON data
      options: Options(headers: headers),
    );

    return response;
  }
}
