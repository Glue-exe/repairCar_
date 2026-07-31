import 'package:flutter/material.dart';

import 'dart:convert'; // รับ-ส่งข้อมูลกับเซิร์ฟเวอร์ Decode, Encode
import 'package:crypto/crypto.dart'; // การเข้ารหัสข้อมูล  Hashing สับข้อมูลให้เป็นรหัสลับ
import 'package:http/http.dart' as http;
import 'package:my_app/screens/owner_home_screen.dart';
import 'package:my_app/screens/technician_home_screen.dart';
import 'package:my_app/screens/accountant_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_app/config/app_config.dart';
import 'package:my_app/utils/date_util.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey =
      GlobalKey<
        FormState
      >(); // เก็บสถานะของฟอร์ม <> บอก Type || GlobalKey ดึง form นั้นออกไปใช้ภายนอกได้

  final _usernameValueController =
      TextEditingController(); // ควบคุมและจัดการข้อมูล .text .clear() .text = "admin"
  final _passwordValueController = TextEditingController();

  Future<(bool, String, String)> _authenRequest() async {
    // <Records> (มีErrorไหม, ข้อมูลที่ได้, ข้อความแจ้งError)
    String username = _usernameValueController.text;
    DateTime now = DateTime.now();
    String formattedDateString = DateUtil.getFormattedDate(now);

    String combinedString = "$username&$formattedDateString";
    print('user+date: $combinedString');

    String authenRequestString =
        sha256 // เข้ารหัสทางคณิต ไม่สามารถแปลงกลับได้
            .convert(utf8.encode(combinedString)) // แปลงให้เป็นเลขไบต์
            .toString(); // แปลงเป็น String ยาว 64 ตัว

    print('sha256 convert: $authenRequestString');

    final response = await http.post(
      Uri.parse(
        "${AppConfig.apiBaseUri}/authen/authen_request",
      ), // .parse แกะ string || Uri แบบฟอร์ม ส่งต่อให้ post
      headers: <String, String>{
        // เขียนเป็นคู่แบบ หัวข้อ String, รายละเอียด String
        'Content-Type':
            'application/json; charset=UTF-8', // content-type กำหนดข้อมูลที่ส่งไปเป็นประเภทอะไร ส่งเป็น json utf-8 ภาษาทั่วโลก
      },
      body: jsonEncode(<String, String>{
        'authen_request': authenRequestString,
      }), // key value เป็น String หมด
    );

    final json = jsonDecode(
      response.body,
    ); // dart เรียกว่า Map, แปลงกับมาเป็น Map

    print('response.body by server: $json');

    return (
      // การดึงข้อมูลออกจาก JSON (Map) || as กำหนดชนิดข้อมูลที่ส่งกลับ
      json["isError"] as bool,
      json["data"] as String,
      json["errorMessage"] as String,
    );
  }

  Future<({bool isError, String data, String errorMessage, String roleName})>
  _accessRequest(String authenToken) async {
    String username = _usernameValueController.text;
    String password = _passwordValueController.text;
    String passwordEncode = sha256.convert(utf8.encode(password)).toString();
    String combinedString = "$username&$passwordEncode&$authenToken";
    String authenSignature = sha256
        .convert(utf8.encode(combinedString))
        .toString();

    print(combinedString);
    print(authenSignature);

    final response = await http.post(
      Uri.parse("${AppConfig.apiBaseUri}/authen/access_request"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'authen_signature': authenSignature,
        'authen_token': authenToken,
      }),
    );

    final json = jsonDecode(response.body);

    print(json);

    if (!json["isError"]) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("access_token", json["data"]["access_token"]);
      await prefs.setString("username", _usernameValueController.text);
      await prefs.setString("user_role", json["data"]["role_name"]);
      await prefs.setInt("user_role_id", json["data"]["role_id"]);
    }

    return (
      isError: json["isError"] as bool,
      data: json["isError"] ? "" : (json["data"]["access_token"] as String),
      errorMessage: json["errorMessage"] as String,
      roleName: json["isError"]
          ? ""
          : (json["data"]["role_name"] as String? ?? ""),
    );
  }

  void _doLogin(BuildContext context) async {
    var (isError, authenToken, errorMessage) = await _authenRequest();

    if (isError) {
      showDialog(
        // Popup
        context: context, // วาดทับหน้า Login
        builder: (context) {
          // วาดกล่องหน้าตาแบบไหน
          return AlertDialog(content: Text(errorMessage));
        },
      );
    } else {
      var result = await _accessRequest(authenToken);

      print(result);

      if (!result.isError) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int? roleId = prefs.getInt("user_role_id");
        String? userRole = prefs.getString("user_role");

        if (roleId == 1 || userRole == 'เจ้าของร้าน' || userRole == 'Owner') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OwnerHomeScreen()),
          );
        } else if (roleId == 2 ||
            userRole == 'ช่าง' ||
            userRole == 'Technician') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const TechnicianHomeScreen(),
            ),
          );
        } else if (roleId == 3 ||
            userRole == 'พนักงานบัญชี' ||
            userRole == 'Accountant') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountantHomeScreen(),
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                content: Text(
                  "ไม่พบบทบาทผู้ใช้ในระบบ หรือไม่มีสิทธิ์เข้าใช้งาน",
                ),
              );
            },
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(content: Text(result.errorMessage));
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg1.jpeg"),
            fit: BoxFit.fill,
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          height: 400,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(15),
            color: Colors.black.withValues(alpha: 0.1),
          ),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 50),
                  child: Text("Username"),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: TextFormField(
                    controller: _usernameValueController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "กรุณากรอก username";
                      }

                      return null;
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 50),
                  child: Text("Password"),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: TextFormField(
                    obscureText: true,
                    controller: _passwordValueController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "กรุณากรอก Password";
                      }

                      return null;
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 40),
                  child: ElevatedButton(
                    onPressed: () {
                      // ถ้าโค้ดบรรทัดเดียวใช้ => แต่ถ้ามีหลายบรรทัดใช้ {}
                      if (_formKey.currentState!.validate()) {
                        _doLogin(context);
                      }
                    },
                    child: Text("Login"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
