// ignore_for_file: use_build_context_synchronously, implementation_imports

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'database_helper.dart';
import 'constant.dart';
import 'dashboard.dart';
import 'package:flutter/src/painting/box_border.dart' as flutter_border;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'check_password.dart';
import 'data_import.dart';
import 'settings_popup_singlepipe_injection.dart';
import 'show_pipes_volume.dart';
import 'system_setup_panel.dart';
import 'settings_popup_close.dart';
import 'settings_popup_open.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
// ignore: depend_on_referenced_packages, unused_import
import 'package:path/path.dart' as p;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  // late Future<List<Map<String, dynamic>>> _allMembers;
  String documentsPath = '/storage/emulated/0/Documents/moodapp';
  bool shouldUpdate = false;
  bool showEnglish = AllConstants.showEnglish;
  String _progress = '下載中....';
  double containerWidthHeight = 180;
  List<dynamic> pipeUseList = [];
  List<dynamic> _gPipesList = [];
  List<TextEditingController> _correctControllers = [];
  Map<String, double> gPipeTotals = {};
  Map<String, double> correctTotals = {};
  String pipeUseId = '1';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          showEnglish = prefs.getBool('showEnglish') ?? true;
          pipeUseId = prefs.getString('pipeUseId') ?? '1';
        });
      }
      await getPipeUseList();
      await loadControllerValues();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return const CheckPassword();
        },
      );
    });
  }

  @override
  void dispose() {
    for (var controller in _correctControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String generate20CharGuid() {
    const uuid = Uuid();
    return uuid.v4().substring(0, 20);
  }

  Future<void> getPipeUseList() async {
    // List<String> pipeUseList = [];
    // 從sqlite 中取出 pipeSettingString
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pipe_use_manage',
      where: 'active = ?',
      whereArgs: [1],
    );
    if (maps.isNotEmpty) {
      _gPipesList = [];
      if (mounted) {
        setState(() {
          pipeUseList = maps.first['pipeSettingString'].toString().split('@');
        });
      }
      List.generate(pipeUseList.length, (index) => {_gPipesList.add(pipeUseList[index].replaceAll('{', '').replaceAll('}', '').split(':')[1].trim())});
      if (mounted) {
        setState(() {
          _gPipesList = _gPipesList;
          _correctControllers = List.generate(_gPipesList.length, (index) => TextEditingController());
        });
      }
      debugPrint('pipeUseList: $pipeUseList , _gPipesList $_gPipesList');
    } else {
      _gPipesList = [];
      debugPrint('pipeUseList is empty');
    }
  }

  Future<void> saveControllerValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _correctControllers.length; i++) {
      await prefs.setString('M${pipeUseId}_correctRatio_$i', _correctControllers[i].text);

      if (_correctControllers.length == 13 && i == 12) {
        await prefs.setString('M${pipeUseId}_correctRatio_13', 0.toString());
        await prefs.setString('M${pipeUseId}_correctRatio_14', 0.toString());
        await prefs.setString('M${pipeUseId}_correctRatio_16', _correctControllers[12].text);
      } else if (_correctControllers.length == 14 && i == 13) {
        await prefs.setString('M${pipeUseId}_correctRatio_13', _correctControllers[12].text);
        await prefs.setString('M${pipeUseId}_correctRatio_14', 0.toString());
        await prefs.setString('M${pipeUseId}_correctRatio_16', _correctControllers[13].text);
      } else if (_correctControllers.length == 15 && i == 14) {
        await prefs.setString('M${pipeUseId}_correctRatio_13', _correctControllers[12].text);
        await prefs.setString('M${pipeUseId}_correctRatio_14', _correctControllers[13].text);
        await prefs.setString('M${pipeUseId}_correctRatio_16', _correctControllers[14].text);
      }
    }
  }

  Future<void> loadControllerValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _correctControllers.length; i++) {
      _correctControllers[i].text = prefs.getString('M${pipeUseId}_correctRatio_$i') ?? '1.0';
      if (_correctControllers.length == 13 && i == 12) {
        prefs.getString('M${pipeUseId}_correctRatio_13');
        prefs.getString('M${pipeUseId}_correctRatio_14');
        prefs.getString('M${pipeUseId}_correctRatio_16');
      } else if (_correctControllers.length == 14 && i == 13) {
        prefs.getString('M${pipeUseId}_correctRatio_13');
        prefs.getString('M${pipeUseId}_correctRatio_14');
        prefs.getString('M${pipeUseId}_correctRatio_16');
      } else if (_correctControllers.length == 15 && i == 14) {
        prefs.getString('M${pipeUseId}_correctRatio_13');
        prefs.getString('M${pipeUseId}_correctRatio_14');
        prefs.getString('M${pipeUseId}_correctRatio_16');
      }
      // if (i == _correctControllers.length - 1) {
      //   _correctControllers[i].text = prefs.getString('M${pipeUseId}_correctRatio_16') ?? '1.0';
      // } else {
      //   _correctControllers[i].text = prefs.getString('M${pipeUseId}_correctRatio_$i') ?? '1.0';
      // }
    }
  }

  Future<String> getFieldTotals(String gPipeFieldName, String correctFieldName) async {
    // 獲取當前時間
    DateTime? now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    List<Map<String, dynamic>> querySnapshot = [];

    // 從sqlite 的資料表 'all_transaction_records' 中獲取資料 where createdDateTime >= startOfDay
    DatabaseHelper().getAllRecordsStart(startOfMonth.toString()).then((value) {
      if (value.isNotEmpty) {
        querySnapshot = value;
      }
    });

    // 初始化總計變數
    double gTotal = 0;
    double gDailyTotal = 0;
    double gWeeklyTotal = 0;
    double gMonthlyTotal = 0;
    double cTotal = 0;
    double cDailyTotal = 0;
    double cWeeklyTotal = 0;
    double cMonthlyTotal = 0;

    // 遍歷查詢結果
    for (var doc in querySnapshot) {
      double gPipeValue = doc[gPipeFieldName]?.toDouble() ?? 0;
      double cPipeValue = doc[correctFieldName]?.toDouble() ?? 0;

      // 計算總計
      gTotal += gPipeValue;
      cTotal += cPipeValue;

      // 獲取文檔的時間戳
      DateTime docDate = doc['createdDateTime'] as DateTime;
      // 計算日總計
      if (docDate.isAfter(startOfDay)) {
        gDailyTotal += gPipeValue;
        cDailyTotal += cPipeValue;
      }

      // 計算周總計
      if (docDate.isAfter(startOfWeek)) {
        gWeeklyTotal += gPipeValue;
        cWeeklyTotal += cPipeValue;
      }

      // 計算月總計
      if (docDate.isAfter(startOfMonth)) {
        gMonthlyTotal += gPipeValue;
        cMonthlyTotal += cPipeValue;
      }
    }

    // 返回結果
    return '時:$cTotal($gTotal)/日:$cDailyTotal($gDailyTotal)/周:$cWeeklyTotal($gWeeklyTotal)/月:$cMonthlyTotal($gMonthlyTotal)';
  }

  Future<void> installApk() async {
    try {
      // Open file picker to choose an APK file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
      );

      if (result != null) {
        // Get the path of the selected APK file
        String apkPath = result.files.first.path!;

        // Create an Android intent to install the APK file
        AndroidIntent(
          action: 'action_install_package',
          data: 'file://$apkPath',
          package: 'com.android.packageinstaller',
          componentName: 'com.android.packageinstaller.PackageInstallerActivity',
        );

        await launchUrl(Uri.parse(apkPath));
      }
    } catch (e) {
      debugPrint('Error installing APK: $e');
    }
  }

  Future<void> _downloadAndInstallApk() async {
    final url = 'http://34.81.6.253/${AllConstants().softVersion}.apk';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final appDir = await getExternalStorageDirectory();
      final savePath = '${appDir!.path}/${AllConstants().softVersion}.apk';
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes, flush: true);
      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _progress = 'Done';
          });
        }
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (BuildContext context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: showVersionInfo(),
          ),
        );
        //開啟檔案
        // await OpenFile.open(file.path);

        try {
          // 使用 url_launcher 插件打開檔案
          await launchUrl(Uri.parse(file.path));
        } catch (e) {
          debugPrint('打開檔案時發生錯誤: $e');
        }
        // await installApk();
      }
    }
  }

  void checkAndRequestPermissions() async {
    PermissionStatus status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: healDarkGrey,
        centerTitle: true,
        title: Text(showEnglish ? 'Management & Settings' : '資料管理與設定', style: const TextStyle(color: colorWhite80, fontSize: 28, fontWeight: FontWeight.bold)),
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 2.0),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back, color: colorWhite80, size: 40),
          ),
        ),
        toolbarHeight: 80,
      ),
      body: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
        return Container(
          color: healDarkGrey,
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  const SizedBox(
                    height: 15,
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        showEnglish ? 'Equipment Maintenance' : '設備維護',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  Row(
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return const DashBoard();
                              });
                        },
                        child: Container(
                          width: containerWidthHeight,
                          height: containerWidthHeight,
                          decoration: BoxDecoration(
                            color: colorWhite80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.speed_outlined),
                                iconSize: 70,
                                color: healDarkGrey,
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return const DashBoard();
                                      });
                                },
                              ),
                              Text(
                                showEnglish ? 'DashBoard' : '儀錶板',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: healDarkGrey,
                                  fontSize: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      InkWell(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return const SettingsPopupOpen();
                              });
                        },
                        child: Container(
                          width: containerWidthHeight,
                          height: containerWidthHeight,
                          decoration: BoxDecoration(
                            color: colorWhite80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.sunny),
                                iconSize: 70,
                                color: healDarkGrey,
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return const SettingsPopupOpen();
                                      });
                                },
                              ),
                              Text(
                                showEnglish ? 'Opening\nCleaning' : '開班清潔',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: healDarkGrey,
                                  fontSize: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      InkWell(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return const SettingsPopupClose();
                              });
                        },
                        child: Container(
                          width: containerWidthHeight,
                          height: containerWidthHeight,
                          decoration: BoxDecoration(
                            color: colorWhite80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.nightlight_outlined),
                                iconSize: 70,
                                color: healDarkGrey,
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return const SettingsPopupClose();
                                      });
                                },
                              ),
                              Text(
                                showEnglish ? 'Closing\nCleaning' : '關班清潔',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: healDarkGrey,
                                  fontSize: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      InkWell(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return const SettingsPopupSinglePipeInjection();
                              });
                        },
                        child: Container(
                          width: containerWidthHeight,
                          height: containerWidthHeight,
                          decoration: BoxDecoration(
                            color: colorWhite80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.colorize_rounded),
                                iconSize: 70,
                                color: healDarkGrey,
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return const SettingsPopupSinglePipeInjection();
                                      });
                                },
                              ),
                              Text(
                                showEnglish ? 'SingleTube\nInjection' : '單管注入',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: healDarkGrey,
                                  fontSize: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      InkWell(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return const ShowPipesVolume();
                              });
                        },
                        child: Container(
                          width: containerWidthHeight,
                          height: containerWidthHeight,
                          decoration: BoxDecoration(
                            color: colorWhite80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.format_color_fill_outlined),
                                iconSize: 70,
                                color: healDarkGrey,
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return const ShowPipesVolume();
                                      });
                                },
                              ),
                              Text(
                                showEnglish ? 'Ingredient\nAlert' : '原料警示',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: healDarkGrey,
                                  fontSize: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        showEnglish ? 'Settings' : '設定測試',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w400,
                          color: colorWhite80,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  Row(
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return const SystemSetupPanel();
                            },
                          );
                        },
                        child: Container(
                          width: containerWidthHeight,
                          height: containerWidthHeight,
                          decoration: BoxDecoration(
                            color: colorWhite80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.settings),
                                iconSize: 70,
                                color: healDarkGrey,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return const SystemSetupPanel();
                                    },
                                  );
                                },
                              ),
                              Text(
                                showEnglish ? 'System\nSettings' : '系統設定',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: healDarkGrey,
                                  fontSize: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => Dialog(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: showConstantSettings(),
                            ),
                          );
                        },
                        child: Container(
                          width: containerWidthHeight,
                          height: containerWidthHeight,
                          decoration: BoxDecoration(
                            color: colorWhite80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.app_registration),
                                iconSize: 70,
                                color: healDarkGrey,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      child: showConstantSettings(),
                                    ),
                                  );
                                },
                              ),
                              Text(
                                showEnglish ? 'Constant\nSettings' : '校正參數',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: healDarkGrey,
                                  fontSize: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => Dialog(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: showVersionInfo(),
                            ),
                          );
                        },
                        child: Container(
                          width: containerWidthHeight,
                          height: containerWidthHeight,
                          decoration: BoxDecoration(
                            color: colorWhite80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.update),
                                iconSize: 70,
                                color: healDarkGrey,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      child: showVersionInfo(),
                                    ),
                                  );
                                },
                              ),
                              Text(
                                showEnglish ? 'App Update' : 'APP更新',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: healDarkGrey,
                                  fontSize: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const DataImport()));
                        },
                        child: Container(
                          width: containerWidthHeight,
                          height: containerWidthHeight,
                          decoration: BoxDecoration(
                            color: colorWhite80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.import_export),
                                iconSize: 70,
                                color: healDarkGrey,
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const DataImport()));
                                },
                              ),
                              Text(
                                showEnglish ? 'Data Import' : '資料管理',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: healDarkGrey,
                                  fontSize: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget showUserDataManagement() {
    return StatefulBuilder(
      builder: (BuildContext context, setState) {
        return Container(
          width: showEnglish ? 650 : 600,
          height: 800,
          decoration: BoxDecoration(
            color: colorDark,
            border: flutter_border.Border.all(
              color: healDarkGrey,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                showEnglish ? 'User Data Management' : '使用者資料管理',
                style: const TextStyle(color: colorWhite50, decoration: TextDecoration.underline, fontSize: 28),
              ),
              const Expanded(
                flex: 8,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      children: [
                        // showUserDataList(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget showConstantSettings() {
    debugPrint('_gPipesList.length: ${_gPipesList.length}');
    return StatefulBuilder(
      builder: (BuildContext context, setState) {
        return Container(
          width: showEnglish ? 750 : 600,
          height: 800,
          decoration: BoxDecoration(
            color: healDarkGrey,
            border: flutter_border.Border.all(
              color: healDarkGrey,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                showEnglish ? 'Constant Settings' : '校正參數設定(${_gPipesList.length})',
                style: const TextStyle(color: colorWhite50, decoration: TextDecoration.underline, fontSize: 28),
              ),
              Expanded(
                flex: 8,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      children: [
                        for (int i = 0; i < _gPipesList.length; i++) showRow(_gPipesList[i].toString(), i),
                        // const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 50,
                              width: 250,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorWhite80,
                                  foregroundColor: healDarkGrey,
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(color: healDarkGrey, width: 1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () async {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  showEnglish ? 'Quit' : '不修改,離開',
                                  style: const TextStyle(fontSize: 26, color: healDarkGrey),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 50,
                              width: 250,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorWhite80,
                                  foregroundColor: healDarkGrey,
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(color: healDarkGrey, width: 1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () async {
                                  await saveControllerValues();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Container(
                                          height: 80.0, // 設置高度
                                          alignment: Alignment.center,
                                          child: Text(
                                            showEnglish ? 'Settings has been saved' : '參數已儲存',
                                            style: const TextStyle(fontSize: 24),
                                          )),
                                      behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                      ),
                                      backgroundColor: healDarkGrey,
                                    ),
                                  );
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  showEnglish ? 'Press to Set' : '設定參數',
                                  style: const TextStyle(fontSize: 26, color: healDarkGrey),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget showRow(String gPipeName, int index) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: showEnglish ? 3 : 2,
              child: Text(
                showEnglish
                    ? (index + 1) == _correctControllers.length
                        ? 'Pipe16:'
                        : 'Pipe${(index + 1).toString()}:'
                    : (index + 1) == _correctControllers.length
                        ? '管16:'
                        : '管${(index + 1).toString()}:',
                style: const TextStyle(color: colorWhite50, fontSize: 24),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: showEnglish ? 5 : 6,
              child: Text(
                gPipeName,
                style: const TextStyle(
                  color: colorWhite50,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: Text(
                showEnglish ? 'Corrections:' : '校正參數:',
                style: const TextStyle(color: colorWhite50, fontSize: 24),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.only(bottom: 13.0),
                child: TextField(
                  controller: _correctControllers[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    color: colorWhite80,
                  ),
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: healDarkGrey,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    _correctControllers[index].text = value;
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget showVersionInfo() {
    return StatefulBuilder(
      builder: (BuildContext context, setState) {
        return Container(
          width: 700,
          height: 800,
          decoration: BoxDecoration(
            color: healDarkGrey,
            border: flutter_border.Border.all(
              color: healDarkGrey,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                showEnglish ? 'Software Version' : '軟體版本 :',
                style: const TextStyle(
                  color: colorWhite50,
                  decoration: TextDecoration.underline,
                  fontSize: 20,
                ),
              ),

              Text(
                AllConstants().softVersion,
                style: const TextStyle(
                  color: colorWhite50,
                  decoration: TextDecoration.underline,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              //導入外部檔案 version_info.txt
              Expanded(
                flex: 8,
                child: SingleChildScrollView(
                  child: FutureBuilder(
                    future: DefaultAssetBundle.of(context).loadString(showEnglish ? 'lib/assets/txt/version_info_english.txt' : 'lib/assets/txt/version_info.txt'),
                    builder: (BuildContext context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          snapshot.data.toString(),
                          style: const TextStyle(
                            color: colorWhite50,
                            fontSize: 20,
                          ),
                        );
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
                ),
              ),
              Visibility(
                visible: _progress == 'Downloading....',
                child: const SizedBox(height: 20),
              ),
              Visibility(
                visible: _progress == 'Downloading....',
                child: Expanded(
                  flex: 2,
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(color: colorWhite80),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          showEnglish ? 'Downloading....' : 'Apk 下載中....',
                          style: const TextStyle(color: colorWhite80, fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 70,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorWhite80,
                            foregroundColor: healDarkGrey,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: healDarkGrey, width: 1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            showEnglish ? 'Close' : '關閉',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: _progress != 'Downloading....',
                      child: SizedBox(
                        width: 200,
                        height: 70,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorWhite80,
                              foregroundColor: healDarkGrey,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(color: healDarkGrey, width: 1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              if (mounted) {
                                setState(() {
                                  _progress = 'Downloading....';
                                });
                              }
                              _downloadAndInstallApk();
                              Navigator.of(context).pop();
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => Dialog(
                                  // 顯示本版本修改內容與 檢查更新按鈕
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  child: showVersionInfo(),
                                ),
                              );
                            },
                            child: Text(
                              showEnglish ? 'Download APP' : '下載 APP',
                              style: const TextStyle(fontSize: 20, color: healDarkGrey),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      height: 70,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorWhite80,
                            foregroundColor: healDarkGrey,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: healDarkGrey, width: 1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            showEnglish ? 'Install APP' : '安裝 APP',
                            style: const TextStyle(fontSize: 20, color: healDarkGrey),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
