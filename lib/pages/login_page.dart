// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sqflite/sqflite.dart';
import 'constant.dart';
import 'database_helper.dart';
import 'main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final String documentsPath = AllConstants().documentsPath;
  bool showEnglish = true;
  String userEmail = '';

  // init state
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          showEnglish = prefs.getBool('showEnglish') ?? true;
          userEmail = prefs.getString('userEmail') ?? '';
        });
      }
    });
    _insertAdminCheck();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _insertAdminCheck() async {
    // final Database db = await _dbHelper.database;
    Map<String, dynamic>? result = await _dbHelper.getUser('admin@gmail.com');
    if (result == null) {
      Map<String, dynamic> row = {
        'userEmail': 'admin@gmail.com',
        'userPassWord': '789789',
        'userLevel': 1,
        'userId': 'S00001',
        'userName': 'admin',
        'userPhone': '0912345678',
        'createdDateTime': DateTime.now().toString(),
      };
      await _dbHelper.insertUser(row);
      debugPrint('Admin Inserted');
    } else {
      debugPrint('Admin Already Exist');
    }
  }

  void _login() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = emailController.text;
    String password = passwordController.text;

    Map<String, dynamic>? user = await _dbHelper.getUser(email);
    if (user != null && user['userPassWord'] == password) {
      prefs.setString('userEmail', email);
      prefs.setString('salesId', email);
      // 登入成功
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    } else {
      debugPrint('user: ${user.toString()}, email: $email, password: $password');
      // 登入失敗
      prefs.setString('userEmail', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            height: 80.0, // 設置高度
            alignment: Alignment.center,
            // color: healDarkGrey,
            child: Text(
              showEnglish ? 'Login failed, please check your email and password.' : '登入失敗! 請檢查電子郵件或密碼。',
              style: const TextStyle(fontSize: 24.0, color: colorWhite80),
            ),
          ),
          behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: healGreyBg,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('lib/assets/images/main_logo.png', width: 300, height: 100, fit: BoxFit.fitWidth),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        hintText: 'Input the Email',
                        hintStyle: TextStyle(color: healLightGrey, fontSize: 26),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: healDarkGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: healDarkGrey),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: healRed),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        hintText: 'Input the Password',
                        hintStyle: TextStyle(color: healLightGrey, fontSize: 26),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: healDarkGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: healDarkGrey),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: healRed),
                      obscureText: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 60,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(200, 60),
                        foregroundColor: healRed,
                        backgroundColor: const Color(0xFFECEAE4),
                        side: const BorderSide(
                          color: healRed,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: _login,
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
