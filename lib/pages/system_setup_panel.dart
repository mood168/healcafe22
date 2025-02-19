// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';
import 'system_variables.dart';
import 'main_page.dart';

class SystemSetupPanel extends StatefulWidget {
  const SystemSetupPanel({
    super.key,
  });

  @override
  State<SystemSetupPanel> createState() => _SystemSetupPanelState();
}

class _SystemSetupPanelState extends State<SystemSetupPanel> {
  final TextEditingController _passWordController = TextEditingController();
  final TextEditingController _pipeUseIdController = TextEditingController();
  final TextEditingController _routerIPController = TextEditingController();
  final TextEditingController _groupIdController = TextEditingController();
  final TextEditingController _g1Controller = TextEditingController();
  final TextEditingController _g2Controller = TextEditingController();
  final TextEditingController _g3Controller = TextEditingController();
  final TextEditingController _g4Controller = TextEditingController();
  final TextEditingController _g5Controller = TextEditingController();
  final TextEditingController _g6Controller = TextEditingController();
  final TextEditingController _g7Controller = TextEditingController();
  final TextEditingController _g8Controller = TextEditingController();
  final TextEditingController _g9Controller = TextEditingController();
  final TextEditingController _g10Controller = TextEditingController();
  final TextEditingController _g11Controller = TextEditingController();
  final TextEditingController _g12Controller = TextEditingController();
  final TextEditingController _g13Controller = TextEditingController();
  final TextEditingController _g14Controller = TextEditingController();
  final TextEditingController _g16Controller = TextEditingController();
  bool isOnline = false;
  bool showPrice = AllConstants.showPrice;
  bool showEnglish = AllConstants.showEnglish;
  bool showRemainAlert = false;
  String userEmail = '';
  int userLevel = 9;
  // showEnglishStatus = true 有變換語言設定時，關閉對話框並導向首頁, 否則 false 只是關閉對話框
  bool showEnglishStatus = false;
  List<Map<String, String>> pipeContents = [];

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // 更新狀態或執行其他邏輯
      if (mounted) {
        setState(() {
          // 更新狀態
          showEnglish = prefs.getBool('showEnglish') ?? true;
          showPrice = prefs.getBool('showPrice') ?? false;
          userLevel = prefs.getInt('userLevel') ?? 9;
          showRemainAlert = prefs.getBool('showRemainAlert') ?? false;
        });
      }
    });
    getUserEmail().then((value) {
      if (mounted) {
        setState(() {
          userEmail = value!;
        });
      }
    });
    initController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  // Future<void> _launchApk() async {
  //   final appDir = await getExternalStorageDirectory();
  //   final filePath = '${appDir!.path}/mood_app_${AllConstants().softVersion}.apk';
  //   //開啟appDir檔案夾
  //   await OpenFile.open(filePath);
  // }

  void initController() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _passWordController.text = prefs.getString('systemPanelPwd') ?? AllConstants().systemPassWord;
    _pipeUseIdController.text = prefs.getString('pipeUseId') ?? AllConstants().pipeUseId;
    _routerIPController.text = prefs.getString('routerIP') ?? AllConstants().routerIP;
    _groupIdController.text = prefs.getString('groupId') ?? '';

    _g1Controller.text = prefs.getString('_g1Controller') ?? '';
    _g2Controller.text = prefs.getString('_g2Controller') ?? '';
    _g3Controller.text = prefs.getString('_g3Controller') ?? '';
    _g4Controller.text = prefs.getString('_g4Controller') ?? '';
    _g5Controller.text = prefs.getString('_g5Controller') ?? '';
    _g6Controller.text = prefs.getString('_g6Controller') ?? '';
    _g7Controller.text = prefs.getString('_g7Controller') ?? '';
    _g8Controller.text = prefs.getString('_g8Controller') ?? '';
    _g9Controller.text = prefs.getString('_g9Controller') ?? '';
    _g10Controller.text = prefs.getString('_g10Controller') ?? '';
    _g11Controller.text = prefs.getString('_g11Controller') ?? '';
    _g12Controller.text = prefs.getString('_g12Controller') ?? '';
    _g13Controller.text = prefs.getString('_g13Controller') ?? '';
    _g14Controller.text = prefs.getString('_g14Controller') ?? '';
    _g16Controller.text = prefs.getString('_g16Controller') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    // DateTime now = DateTime.now();
    // String convertedDateTime =
    //     "${now.year.toString()}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}";
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      color: healDarkGrey,
      child: Dialog(
        backgroundColor: healDarkGrey,
        child: Center(
          child: Container(
            height: 700.0,
            width: 780.0,
            decoration: const BoxDecoration(
              color: colorWhite80,
            ),
            child: SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Text(showEnglish ? 'System Settings' : '系統功能設定',
                        style: const TextStyle(
                          fontSize: 28,
                          color: healDarkGrey,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(
                      height: 20,
                    ),
                    Expanded(
                      flex: 18,
                      child: Row(
                        children: [
                          Expanded(
                              flex: 5,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                                child: Column(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            showEnglish ? 'System Password' : '系統面板密碼',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              color: healDarkGrey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 20,
                                          ),
                                          SizedBox(
                                            width: 120,
                                            height: 70,
                                            child: TextFormField(
                                              controller: _passWordController,
                                              keyboardType: TextInputType.number,
                                              maxLength: 6,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: healDarkGrey,
                                                // backgroundColor: colorWhite80,
                                                fontFamily: 'Poppins',
                                                fontSize: 24,
                                                fontWeight: FontWeight.w300,
                                              ),
                                              decoration: const InputDecoration(
                                                labelStyle: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: colorWhite80,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: healDarkGrey,
                                                    width: 1,
                                                  ),
                                                ),
                                                counterText: '',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 20,
                                          ),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              minimumSize: const Size(70, 60),
                                              foregroundColor: healDarkGrey,
                                              backgroundColor: healDarkGrey,
                                              side: const BorderSide(
                                                color: healDarkGrey,
                                                width: 2,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                            ),
                                            onPressed: () async {
                                              SharedPreferences prefs = await SharedPreferences.getInstance();
                                              prefs.setString('systemPanelPwd', _passWordController.text);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Container(
                                                    height: 80.0, // 設置高度
                                                    alignment: Alignment.center,
                                                    // color: healDarkGrey,
                                                    child: Text(
                                                      showEnglish ? 'System Password Modified' : '更改完成',
                                                      style: const TextStyle(fontSize: 18.0),
                                                    ),
                                                  ),
                                                  behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                                  ),
                                                  backgroundColor: healDarkGrey,
                                                ),
                                              );
                                            },
                                            child: Text(
                                              showEnglish ? 'Set' : '更改',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                color: colorWhite80,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            showEnglish ? 'Router IP Address' : '路由器IP',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              color: healDarkGrey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 20,
                                          ),
                                          SizedBox(
                                            width: 200,
                                            height: 70,
                                            child: TextFormField(
                                              controller: _routerIPController,
                                              keyboardType: TextInputType.url,
                                              maxLength: 15,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: healDarkGrey,
                                                // backgroundColor: colorWhite80,
                                                fontFamily: 'Poppins',
                                                fontSize: 24,
                                                fontWeight: FontWeight.w300,
                                              ),
                                              decoration: const InputDecoration(
                                                labelStyle: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: healDarkGrey,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: healDarkGrey,
                                                    width: 1,
                                                  ),
                                                ),
                                                counterText: '',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 20,
                                          ),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              minimumSize: const Size(70, 60),
                                              foregroundColor: healDarkGrey,
                                              backgroundColor: healDarkGrey,
                                              side: const BorderSide(
                                                color: healDarkGrey,
                                                width: 2,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                            ),
                                            onPressed: () async {
                                              SharedPreferences prefs = await SharedPreferences.getInstance();
                                              prefs.setString('routerIP', _routerIPController.text);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Container(
                                                    height: 80.0, // 設置高度
                                                    alignment: Alignment.center,
                                                    // color: healDarkGrey,
                                                    child: Text(
                                                      showEnglish ? 'Router IP Modified' : '更改完成',
                                                      style: const TextStyle(fontSize: 18.0),
                                                    ),
                                                  ),
                                                  behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                                  ),
                                                  backgroundColor: healDarkGrey,
                                                ),
                                              );
                                            },
                                            child: Text(
                                              showEnglish ? 'Set' : '更改',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                color: colorWhite80,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            showEnglish ? 'Switch Chinese/English' : '中文/英文開關',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              color: healDarkGrey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 50,
                                          ),
                                          Row(
                                            children: [
                                              // OTHER 選項
                                              Row(
                                                children: [
                                                  const Text('CHINESE', style: TextStyle(fontSize: 24, color: healDarkGrey)),
                                                  Transform.scale(
                                                    scale: 1.8,
                                                    child: Radio<bool>(
                                                      value: false, // OTHER 選項
                                                      groupValue: showEnglish, // 將 showEnglish 作為 groupValue
                                                      onChanged: (value) {
                                                        if (mounted) {
                                                          setState(() {
                                                            showEnglish = false; // 設置為 OTHER
                                                            showEnglishStatus = true; // 更新狀態
                                                          });
                                                        }
                                                      },
                                                      activeColor: healDarkGrey, // 選中顏色
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                width: 20,
                                              ),
                                              // ENGLISH 選項
                                              Row(
                                                children: [
                                                  const Text('ENGLISH', style: TextStyle(fontSize: 24, color: healDarkGrey)),
                                                  Transform.scale(
                                                    scale: 1.8,
                                                    child: Radio<bool>(
                                                      value: true, // ENGLISH 選項
                                                      groupValue: showEnglish, // 將 showEnglish 作為 groupValue
                                                      onChanged: (value) {
                                                        if (mounted) {
                                                          setState(() {
                                                            showEnglish = true; // 設置為 ENGLISH
                                                            showEnglishStatus = true; // 更新狀態
                                                          });
                                                        }
                                                      },
                                                      activeColor: healDarkGrey, // 選中顏色
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            showEnglish ? 'Remain Alert' : '缺料警示開關',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              color: healDarkGrey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 50,
                                          ),
                                          Row(
                                            children: [
                                              // OFF 選項
                                              Row(
                                                children: [
                                                  const Text('OFF', style: TextStyle(fontSize: 24, color: healDarkGrey)),
                                                  Transform.scale(
                                                    scale: 1.8,
                                                    child: Radio<bool>(
                                                      value: false, // OFF 選項
                                                      groupValue: showRemainAlert, // 將 showRemainAlert 作為 groupValue
                                                      onChanged: (value) {
                                                        if (mounted) {
                                                          setState(() {
                                                            showRemainAlert = false; // 設置為 OFF
                                                          });
                                                        }
                                                      },
                                                      activeColor: healDarkGrey, // 選中顏色
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                width: 20,
                                              ),
                                              // ON 選項
                                              Row(
                                                children: [
                                                  const Text('ON', style: TextStyle(fontSize: 24, color: healDarkGrey)),
                                                  Transform.scale(
                                                    scale: 1.8,
                                                    child: Radio<bool>(
                                                      value: true, // ON 選項
                                                      groupValue: showRemainAlert, // 將 showRemainAlert 作為 groupValue
                                                      onChanged: (value) {
                                                        if (mounted) {
                                                          setState(() {
                                                            showRemainAlert = true; // 設置為 ON態
                                                          });
                                                        }
                                                      },
                                                      activeColor: healDarkGrey, // 選中顏色
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Expanded(
                                    //   flex: 3,
                                    //   child: Row(
                                    //     mainAxisAlignment: MainAxisAlignment.start,
                                    //     children: [
                                    //       Text(showEnglish ? 'Enable Shopping Cart' : '購物車功能啟用',
                                    //           style: const TextStyle(
                                    //             fontSize: 24,
                                    //             color: colorWhite80,
                                    //             fontWeight: FontWeight.w600,
                                    //           )),
                                    //       const SizedBox(
                                    //         width: 50,
                                    //       ),
                                    //       Row(
                                    //         children: [
                                    //           isOnline ? const Text('Off', style: TextStyle(fontSize: 24, color: colorWhite80)) : const Text(''),
                                    //           const SizedBox(
                                    //             width: 10,
                                    //           ),
                                    //           isOnline
                                    //               ? Transform.scale(
                                    //                   scale: 1.2,
                                    //                   child: Switch(
                                    //                     activeColor: healDarkGrey,
                                    //                     activeTrackColor: colorLightBrown,
                                    //                     inactiveThumbColor: colorGrey,
                                    //                     inactiveTrackColor: colorWhite30,
                                    //                     value: showPrice,
                                    //                     onChanged: (value) async {
                                    //                       setState(() {
                                    //                         showPrice = value;
                                    //                       });
                                    //                     },
                                    //                   ),
                                    //                 )
                                    //               : Text(showEnglish ? 'Disable When Offline ' : '離線中無法使用', style: const TextStyle(fontSize: 24, color: colorWhite80)),
                                    //           const SizedBox(
                                    //             width: 10,
                                    //           ),
                                    //           isOnline ? const Text('On', style: TextStyle(fontSize: 24, color: colorWhite80)) : const Text(''),
                                    //         ],
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                          height: 50,
                          width: 200,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(200, 40),
                              foregroundColor: healDarkGrey,
                              backgroundColor: healDarkGrey,
                              side: const BorderSide(
                                color: healDarkGrey,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            onPressed: () async {
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              // prefs.setBool('showPrice', showPrice);
                              prefs.setBool('showEnglish', showEnglish);
                              prefs.setBool('showRemainAlert', showRemainAlert);

                              // showEnglishStatus = true 有變換語言設定時，關閉對話框並導向首頁, 否則 false 只是關閉對話框
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MainPage(),
                                ),
                              );
                            },
                            child: Text(
                              showEnglish ? 'Quit' : '離開',
                              style: const TextStyle(
                                fontSize: 24,
                                color: colorWhite80,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          )),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
