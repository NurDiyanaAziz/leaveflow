//POST Dio
import 'package:dio/dio.dart';
import 'package:leaveflow/app/services/sharedprefs.dart';

final ApiServices api = ApiServices();

class ApiServices {
  var baseUrl = 'http://10.0.2.2:3000/api';

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
}
