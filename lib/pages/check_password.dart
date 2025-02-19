// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';
import 'main_page.dart';

class CheckPassword extends StatefulWidget {
  const CheckPassword({super.key});

  @override
  State<CheckPassword> createState() => _CheckPasswordState();
}

class _CheckPasswordState extends State<CheckPassword> {
  final TextEditingController _passwordController = TextEditingController();
  String systemPanelPwd = AllConstants().systemPassWord;
  bool showEnglish = true;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // 進行異步操作
      if (mounted) {
        // 更新狀態或執行其他邏輯
        setState(() {
          // 更新狀態
          showEnglish = prefs.getBool('showEnglish') ?? true;
          systemPanelPwd = prefs.getString('systemPanelPwd') ?? AllConstants().systemPassWord;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      color: Colors.white.withOpacity(0.85),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: Container(
            height: 180.0,
            width: 220.0,
            decoration: const BoxDecoration(
              color: healLightGrey,
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: TextFormField(
                      obscureText: true,
                      controller: _passwordController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      style: const TextStyle(
                        color: colorWhite80,
                        // backgroundColor: Color.fromARGB(255, 255, 255, 255),
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorWhite80,
                            width: 2,
                          ),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorWhite80,
                            width: 2,
                          ),
                        ),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorWhite80,
                            width: 2,
                          ),
                        ),
                        labelText: showEnglish ? 'Enter Password' : '輸入密碼',
                        labelStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          color: colorWhite80,
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: 120,
                    height: 50,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(150, 50),
                        backgroundColor: healDarkGrey,
                      ),
                      onPressed: () async {
                        if (_passwordController.text == systemPanelPwd) {
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Container(
                                height: 80.0, // 設置高度
                                alignment: Alignment.center,
                                // color: healDarkGrey,
                                child: Text(
                                  showEnglish ? 'Incorrect Password' : '密碼錯誤',
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

                          // Navigator to HomePage()
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainPage(),
                            ),
                          );
                        }
                      },
                      child: Text(
                        showEnglish ? 'Submit' : '確定',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: colorWhite50,
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
