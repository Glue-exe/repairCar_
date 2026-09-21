import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/config/app_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class AppAPI {
  static Future get(String uri) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    print("${AppConfig.apiBaseUri}$uri");

    final response = await http.get(
      Uri.parse("${AppConfig.apiBaseUri}$uri"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${prefs.getString("access_token")}',
      },
    );

    return response;
  }

  static Future post(String uri, dynamic body) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.post(
      Uri.parse("${AppConfig.apiBaseUri}$uri"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${prefs.getString("access_token")}',
      },
      body: jsonEncode(body),
    );
    return response;
  }

  static Future<http.Response> postMultipart(
    String uri, {
    Map<String, String>? fields,
    XFile? file,
    String fileField = 'file',
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse("${AppConfig.apiBaseUri}$uri"),
    );

    request.headers['Authorization'] =
        'Bearer ${prefs.getString("access_token")}';

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (file != null) {
      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          bytes,
          filename: file.name,
        ),
      );
    }

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  static Future<http.Response> putMultipart(
    String uri, {
    Map<String, String>? fields,
    XFile? file,
    String fileField = 'file',
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse("${AppConfig.apiBaseUri}$uri"),
    );

    request.headers['Authorization'] =
        'Bearer ${prefs.getString("access_token")}';

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (file != null) {
      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          bytes,
          filename: file.name,
        ),
      );
    }

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  static Future put(String uri, dynamic body) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.put(
      Uri.parse("${AppConfig.apiBaseUri}$uri"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${prefs.getString("access_token")}',
      },
      body: jsonEncode(body),
    );
    return response;
  }

  static Future delete(String uri, dynamic body) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.delete(
      Uri.parse("${AppConfig.apiBaseUri}$uri"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${prefs.getString("access_token")}',
      },
      body: jsonEncode(body),
    );
    return response;
  }
}