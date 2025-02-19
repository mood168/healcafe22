// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:status_alert/status_alert.dart';
import 'constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class SettingsPopupClose extends StatefulWidget {
  const SettingsPopupClose({super.key});

  @override
  State<SettingsPopupClose> createState() => _SettingsPopupCloseState();
}

class _SettingsPopupCloseState extends State<SettingsPopupClose> {
  String routerIP = AllConstants().routerIP;
  List<bool> _isSelectedList = [];
  List<dynamic> pipeUseList = [];
  String pipeUseId = AllConstants().pipeUseId;
  String salesId = AllConstants().salesId;
  List<String> generateList() {
    List<String> result = [];
    for (int i = 5; i <= 300; i += 5) {
      result.add(i.toString());
    }
    return result;
  }

  List<String> timeList = [];
  int selectedValue = 0;
  String selectedTime = "20";
  bool showEnglish = AllConstants.showEnglish;
  bool pressed = false;
  int gStatus = 0;
  String processStatusMessage = '';
  String processStatusMessageEng = '';

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
          routerIP = prefs.getString('routerIP') ?? AllConstants().routerIP;
          salesId = prefs.getString('salesId') ?? AllConstants().salesId;
          routerIP = prefs.getString('routerIP') ?? AllConstants().routerIP;
          processStatusMessage = AllConstants().closeDoorCleanStatus;
          pressed = false;
          gStatus = 0;
        });
      }
      await getPipeUseList();
    });
    timeList = generateList();
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
      if (mounted) {
        setState(() {
          pipeUseList = maps.first['pipeSettingString'].toString().split('@');
          _isSelectedList = List.generate(pipeUseList.length, (_) => false);
        });
      }
      debugPrint('pipeUseList: $pipeUseList , _isSelectedList $_isSelectedList');
    } else {
      debugPrint('pipeUseList is empty');
    }
  }

  void _showPicker(BuildContext ctx) {
    showCupertinoModalPopup(
      context: ctx,
      builder: (_) => Container(
        color: colorWhite80,
        alignment: Alignment.center,
        width: 200,
        height: 280,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: CupertinoPicker(
                backgroundColor: colorDarkGrey,
                itemExtent: 50,
                scrollController: FixedExtentScrollController(initialItem: 2),
                children: timeList
                    .map((e) => Text(
                          showEnglish ? '$e Seconds' : '$e秒',
                          style: const TextStyle(
                            color: colorWhite80,
                            fontSize: 24,
                          ),
                        ))
                    .toList(),
                onSelectedItemChanged: (value) {
                  if (mounted) {
                    setState(() {
                      selectedValue = value;
                      selectedTime = timeList[value];
                    });
                  }
                },
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width: 100,
              height: 50,
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(200, 60),
                  foregroundColor: colorWhite80,
                  backgroundColor: colorDark,
                  side: const BorderSide(
                    color: colorWhite50,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  showEnglish ? 'Set' : '設定',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: colorWhite80,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      color: Colors.transparent.withOpacity(0.5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: Container(
            height: 700.0,
            width: 800.0,
            decoration: BoxDecoration(
              color: colorDark,
              // borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: colorWhite30,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        showEnglish ? 'Close Clean' : '關班清潔',
                        style: const TextStyle(
                          color: colorWhite80,
                          fontSize: 40,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(100, 10, 100, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            flex: 4,
                            child: SizedBox(
                              width: double.maxFinite,
                              height: 350,
                              child: GridView.count(
                                crossAxisCount: 4,
                                mainAxisSpacing: 15.0,
                                crossAxisSpacing: 15.0,
                                childAspectRatio: 1.45,
                                children: List.generate(
                                  pipeUseList.length,
                                  (index) => GestureDetector(
                                    onTap: () {
                                      if (mounted) {
                                        setState(() {
                                          _isSelectedList[index] = !_isSelectedList[index];
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 35,
                                      decoration: BoxDecoration(
                                        color: _isSelectedList[index] ? healDarkGrey : colorGrey,
                                        border: Border.all(),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              pipeUseList[index].replaceAll('{', '').replaceAll('}', '').split(':')[0],
                                              style: const TextStyle(
                                                color: colorWhite80,
                                                fontSize: 30,
                                                fontFamily: 'Roboto',
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            Text(
                                              pipeUseList[index].replaceAll('{', '').replaceAll('}', '').split(':')[1],
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: colorWhite80,
                                                fontSize: 18,
                                                fontFamily: 'Roboto',
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 160,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(200, 60),
                                      foregroundColor: healDarkGrey,
                                      backgroundColor: colorWhite50,
                                      side: const BorderSide(
                                        color: healDarkGrey,
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (mounted) {
                                        setState(() {
                                          _isSelectedList = List.generate(pipeUseList.length, (_) => true);
                                        });
                                      }
                                    },
                                    child: Center(
                                      child: Text(
                                        showEnglish ? 'Pick\nAll' : '全選',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: healDarkGrey,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 25),
                                SizedBox(
                                  width: 80,
                                  height: 160,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(200, 60),
                                      foregroundColor: healDarkGrey,
                                      backgroundColor: colorWhite50,
                                      side: const BorderSide(
                                        color: healDarkGrey,
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (mounted) {
                                        setState(() {
                                          _isSelectedList = List.generate(pipeUseList.length, (_) => false);
                                        });
                                      }
                                    },
                                    child: Center(
                                      child: Text(
                                        showEnglish ? 'Un-\nPick\nAll' : '取消全選',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: healDarkGrey,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(100, 10, 120, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            flex: 6,
                            child: SizedBox(
                              width: double.maxFinite,
                              height: 50,
                              child: Text(showEnglish ? 'Clean　$selectedTime　sec' : '每管清洗　$selectedTime　秒',
                                  style: const TextStyle(
                                    color: colorWhite80,
                                    fontSize: 34,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w300,
                                  ),
                                  textAlign: TextAlign.center),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              width: double.maxFinite,
                              height: 60,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(200, 60),
                                  foregroundColor: healDarkGrey,
                                  backgroundColor: colorWhite50,
                                  side: const BorderSide(
                                    color: healDarkGrey,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onPressed: () => _showPicker(context),
                                child: Text(
                                  showEnglish ? 'Timer Modify' : '變更設定',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: healDarkGrey,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(50, 10, 50, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Container(
                              color: colorDarkGrey,
                              width: double.maxFinite,
                              height: 50,
                              child: Text(processStatusMessage,
                                  style: TextStyle(
                                    color: colorWhite80,
                                    fontSize: showEnglish ? 28 : 30,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w300,
                                  ),
                                  textAlign: TextAlign.center),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(50, 10, 50, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: SizedBox(
                              width: double.maxFinite,
                              height: 50,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(200, 50),
                                  foregroundColor: healDarkGrey,
                                  backgroundColor: colorWhite50,
                                  side: const BorderSide(
                                    color: healDarkGrey,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                onLongPress: () async {
                                  await http.get(Uri.parse('http://$routerIP/stop'));
                                  if (mounted) {
                                    setState(() {
                                      processStatusMessage = showEnglish ? 'Pipes Clean Interrupt' : '清洗動作取消';
                                    });
                                  }
                                },
                                child: Text(
                                  showEnglish ? 'Quit' : '取消',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: healDarkGrey,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: SizedBox(
                              width: double.maxFinite,
                              height: 50,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(200, 50),
                                  foregroundColor: healDarkGrey,
                                  backgroundColor: pressed ? colorWhite30 : colorWhite50,
                                  side: const BorderSide(
                                    color: healDarkGrey,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onPressed: () async {
                                  debugPrint(_isSelectedList.toString());

                                  String urlString = 'http://$routerIP/get?';

                                  for (int i = 0; i < _isSelectedList.length; i++) {
                                    if (_isSelectedList[i] == true) {
                                      urlString += '&c${int.parse(pipeUseList[i].replaceAll('{', '').replaceAll('}', '').split(':')[0].toString())}=$selectedTime';
                                    }
                                  }
                                  urlString = urlString.replaceAll('?&c', '?c');
                                  if (urlString.contains('?c') && pressed == false) {
                                    setState(() {
                                      pressed = true;
                                    });
                                    debugPrint(urlString);

                                    var url = Uri.parse(urlString);
                                    final responseClean = await http.get(url);
                                    if (responseClean.statusCode == 200) {
                                      Timer.periodic(const Duration(milliseconds: 1100), (timer) async {
                                        final response = await http.get(Uri.parse('http://$routerIP/status'));
                                        final statusJsonResponse = jsonDecode(response.body);
                                        final status = statusJsonResponse['status'];
                                        if (response.statusCode == 200) {
                                          if (mounted) {
                                            setState(() {
                                              processStatusMessage = showEnglish ? 'Start Cleaning...' : '開始清洗....';
                                            });

                                            if (status == 0) {
                                              timer.cancel();
                                              setState(() {
                                                pressed = false;
                                                gStatus = 0;
                                                processStatusMessage = showEnglish ? 'Clean Completed! Prerss Cancel button' : '清洗完成! 請按取消離開';
                                                _isSelectedList = List.generate(pipeUseList.length, (_) => false);
                                              });
                                              StatusAlert.show(
                                                context,
                                                duration: const Duration(seconds: 2),
                                                title: showEnglish ? 'Success' : '成功',
                                                subtitle: showEnglish ? 'Clean Completed' : '清洗完成',
                                                configuration: const IconConfiguration(icon: Icons.error_outline, color: Colors.green, size: 100),
                                                subtitleOptions: StatusAlertTextConfiguration(
                                                  textScaleFactor: double.parse('2.0'),
                                                ),
                                                maxWidth: 500,
                                                backgroundColor: colorDark,
                                              );
                                              //Navigator.pop(context);
                                            } else if (status >= 1 && status <= 16) {
                                              setState(() {
                                                gStatus = status;
                                                processStatusMessage = showEnglish ? 'Pipe$status Cleaning' : '第$status管清洗中...';
                                              });
                                            } else if (status >= -16 && status <= -1) {
                                              timer.cancel(); // 停止定時器
                                              setState(() {
                                                pressed = false;
                                                processStatusMessage = showEnglish ? 'Failed, No Juice in the Tube $status' : '清洗失敗$status管已無水, 請檢查';
                                              });
                                              StatusAlert.show(
                                                context,
                                                duration: const Duration(seconds: 3),
                                                title: showEnglish ? 'Error' : '錯誤',
                                                subtitle: showEnglish ? 'Failed, No Juice in the Tube $status' : '清洗失敗$status管已無水, 請檢查',
                                                configuration: const IconConfiguration(icon: Icons.error_outline, color: Colors.red, size: 100),
                                                subtitleOptions: StatusAlertTextConfiguration(
                                                  textScaleFactor: double.parse('2.0'),
                                                ),
                                                maxWidth: 500,
                                                backgroundColor: colorDark,
                                              );
                                            }
                                          }
                                        }
                                      });
                                    } else {
                                      if (mounted) {
                                        setState(() {
                                          pressed = false;
                                          processStatusMessage = showEnglish ? 'Failed! Check Network Connection!' : '清洗失敗! 請檢查網路連線!';
                                        });
                                      }
                                    }
                                  } else {
                                    setState(() {
                                      pressed = false;
                                    });
                                    StatusAlert.show(
                                      context,
                                      duration: const Duration(seconds: 3),
                                      title: showEnglish ? 'Error' : '錯誤',
                                      subtitle: showEnglish ? 'Please select at least one pipe' : '請至少選擇一個管路',
                                      configuration: const IconConfiguration(icon: Icons.error_outline, color: Colors.red, size: 100),
                                      subtitleOptions: StatusAlertTextConfiguration(
                                        textScaleFactor: double.parse('1.5'),
                                      ),
                                      maxWidth: 500,
                                      backgroundColor: colorDark,
                                    );
                                  }
                                },
                                child: Text(
                                  showEnglish ? 'Run' : '執行清潔',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: healDarkGrey,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Visibility(
                  visible: gStatus > 0,
                  child: Center(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorWhite30,
                          width: 1,
                        ),
                      ),
                      width: 200,
                      height: 200,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(width: 80, height: 80, child: CircularProgressIndicator(color: healDarkGrey)),
                          SizedBox(height: 30),
                          Text(
                            'Processing......',
                            style: TextStyle(fontSize: 22, color: colorWhite80),
                          ),
                        ],
                      ),
                    ),
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
