//POST Dio
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData;
import 'package:leaveflow/app/services/sharedprefs.dart';

final ApiServices api = ApiServices();

class ApiServices {
  // var baseUrl = 'http://10.0.2.2:3000/api';
  var baseUrl = 'http://192.168.0.102/api';

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

  Future<Response?> postJson(String path, Map<String, dynamic> data) async {
    try {
      String url = baseUrl + path;
      var response = await Dio().post(
        url,
        data: data,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
          },
          // This prevents Dio from throwing errors on 400/500 so you can handle them
          validateStatus: (status) => status! < 600,
        ),
      );
      return response;
    } catch (e) {
      // print("Dio Error: $e");
      Get.snackbar("Error", "Dio Error: $e", backgroundColor: Colors.red);
      return null;
    }
  }

  // param different
  // Future<Response?> postJson(String path, Map<String, dynamic> data) async {
  //   String? token = await SharedPrefs.getLocalStorage('token') ?? '';
  //   String url = baseUrl + path;

  //   var headers = {
  //     'accept': 'application/json',
  //     'Content-Type': 'application/json', // Important for JSON payload
  //   };

  //   if (token.isNotEmpty) {
  //     headers['authorization'] = 'Bearer $token';
  //   }

  //   var response = await Dio().post(
  //     url,
  //     data: data, // Send the Map directly as JSON data
  //     options: Options(headers: headers),
  //   );

  //   return response;
  // }
}
