// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:healcafe/pages/drink_is_ready.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';
import 'database_helper.dart';
import 'main_page.dart';

class MakeDrinkPage extends StatefulWidget {
  const MakeDrinkPage({super.key, this.productName, this.formulaString});
  final String? productName;
  final String? formulaString;

  @override
  State<MakeDrinkPage> createState() => _MakeDrinkPageState();
}

class _MakeDrinkPageState extends State<MakeDrinkPage> with SingleTickerProviderStateMixin {
  String documentsPath = AllConstants().documentsPath;
  String productName = '';
  String formulaString = '';
  Timer? _statusTimer;
  String routerIP = AllConstants().routerIP;
  String orderNumber = '';
  String drinkMakingStatus = '';
  String pipeUseId = AllConstants().pipeUseId;
  bool showEnglish = AllConstants.showEnglish;
  String salesId = AllConstants().salesId;
  String source = '1';
  String assetImg = '';
  int price = 0;
  int gPipeStatus = 0;
  List<double> correctFactors = [];
  List<dynamic> pipeUseList = [];
  List<dynamic> _gPipesList = [];
  int stepPartsLength = 0;
  bool _showError = true;
  bool needResume = false;
  int holdTime = 0;
  String responseData = '';
  String underPicture = 'Pouring.gif';
  String pouringFail = '';
  bool stopRouteToMainPage = false;
  bool isDataWritten = false;
  bool settingStop = false;
  bool sendStop = false;
  bool showRemainAlert = false;

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );

  late final Animation<double> _animation = Tween<double>(
    begin: 2.5,
    end: 5.0,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutQuad,
  ));

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
    Future.microtask(() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          showEnglish = prefs.getBool('showEnglish') ?? true;
          pipeUseId = prefs.getString('pipeUseId') ?? '1';
          salesId = prefs.getString('salesId') ?? AllConstants().salesId;
          drinkMakingStatus = AllConstants().drinkMakingStatus;
          routerIP = prefs.getString('routerIP') ?? AllConstants().routerIP;
          showRemainAlert = prefs.getBool('showRemainAlert') ?? false;
        });
        await getPipeUseList();
        await loadCorrectFactors();
      }
    });

    if (mounted) {
      setState(() {
        productName = widget.productName!;
        formulaString = widget.formulaString!;
        pouringFail = '';
      });
    }
    startMakeDrink();
  }

  @override
  void dispose() {
    _controller.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<String> fetchData(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Connection': 'keep-alive'},
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Request timeout, please check network connection');
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw HttpException('HTTP錯誤：${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('Network connection error: $e');
      throw 'Network connection failed, please check network settings and device IP address';
    } on TimeoutException catch (e) {
      debugPrint('Request timeout: $e');
      throw 'Request timeout, please check network connection';
    } catch (e) {
      debugPrint('Other error: $e');
      throw 'An error occurred: $e';
    }
  }

  Future<void> getPipeUseList() async {
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
        });
      }
      debugPrint('pipeUseList: $pipeUseList , _gPipesList $_gPipesList');
    } else {
      _gPipesList = [];
      debugPrint('pipeUseList is empty');
    }
  }

  Future<void> loadCorrectFactors() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List.generate(pipeUseList.length, (index) {
      String key;
      if (mounted) {
        setState(() {
          key = 'M${pipeUseId}_correctRatio_${index + 1}';
          if (index <= pipeUseList.length - 1) {
            correctFactors.add(double.parse(prefs.getString(key) ?? 1.0.toString()));
          }
        });
      }
      // return double.parse(prefs.getString(key) ?? 1.0.toString());
    });
    if (mounted) {
      setState(() {
        pipeUseList = pipeUseList;
        correctFactors = correctFactors;
      });
    }
    debugPrint('pipeUseList.length : ${pipeUseList.length}, correctFactors: ${correctFactors.toString()}');
  }

  Future<String> _makeOrderNumber() async {
    String orderNumber = '';
    String lastTransactionOrderNo = '';
    String formatNumber(int number) {
      return number.toString().padLeft(2, '0');
    }

    String createTime = DateTime.now().year.toString() + formatNumber(DateTime.now().month) + formatNumber(DateTime.now().day);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    lastTransactionOrderNo = prefs.getString(createTime) ?? '';

    if (lastTransactionOrderNo.isNotEmpty && lastTransactionOrderNo.length >= 4) {
      try {
        String lastFourNo = lastTransactionOrderNo.substring(lastTransactionOrderNo.length - 4);
        int newTransactionOrderNo = int.parse(lastFourNo) + 1;
        orderNumber = '$createTime${newTransactionOrderNo.toString().padLeft(4, '0')}';
      } catch (e) {
        debugPrint('解析訂單號碼錯誤：$e');
        orderNumber = '${createTime}0001';
      }
    } else {
      orderNumber = '${createTime}0001';

      try {
        List<Map<String, dynamic>> snapshot = await DatabaseHelper().getAllRecordsStart(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).toString());

        if (snapshot.isNotEmpty && snapshot[0]['transactionOrderNo'] != null && snapshot[0]['transactionOrderNo'].toString().length >= 4) {
          String dbLastTransactionOrderNo = snapshot[0]['transactionOrderNo'].toString();
          String lastFourNo = dbLastTransactionOrderNo.substring(dbLastTransactionOrderNo.length - 4);

          if (lastFourNo.length == 4 && RegExp(r'^\d+$').hasMatch(lastFourNo)) {
            int newTransactionOrderNo = int.parse(lastFourNo) + 1;
            orderNumber = '$createTime${newTransactionOrderNo.toString().padLeft(4, '0')}';
          }
        }
      } catch (e) {
        debugPrint('從資料庫獲取訂單號碼錯誤：$e');
      }
    }

    // 確保生成的訂單號碼格式正確
    if (!RegExp(r'^\d{12}$').hasMatch(orderNumber)) {
      debugPrint('訂單號碼格式不正確，重置為初始值');
      orderNumber = '${createTime}0001';
    }

    // 更新SharedPreferences
    try {
      await prefs.setString(createTime, orderNumber);
    } catch (e) {
      debugPrint('保存訂單號碼到 SharedPreferences 錯誤：$e');
    }

    debugPrint('生成的訂單號碼：$orderNumber');
    return orderNumber;
  }

  Future<int?> getStatus() async {
    final response = await http.get(Uri.parse('http://$routerIP/status'));
    if (response.statusCode == 200) {
      final statusJsonResponse = jsonDecode(response.body);
      var gPipeStatus = statusJsonResponse['status'];
      return gPipeStatus;
    }
    return null;
  }

  String formatNumber(int number) {
    return number.toString().padLeft(2, '0');
  }

  Future<void> startMakeDrink() async {
    debugPrint('formulaString: $formulaString');

    if (formulaString.isEmpty) {
      debugPrint('配方字串為空');
      _showFormulaEmptyError();
      return;
    }

    List<String> formulaParts = formulaString.split('@');
    if (formulaParts.length < 2) {
      debugPrint('配方格式錯誤：$formulaString');
      _showFormulaFormatError();
      return;
    }

    String createTime = DateTime.now().year.toString() + formatNumber(DateTime.now().month) + formatNumber(DateTime.now().day);

    try {
      if (orderNumber.isEmpty) {
        orderNumber = await _makeOrderNumber();
        debugPrint('製作前無orderNo 在此產生: $orderNumber');
      }

      List<String> stepParts = formulaParts[1].split('&');
      Map<String, dynamic> values = {
        'transactionOrderNo': orderNumber,
        'productName': productName,
        'price': 0,
        'formulaString': formulaString,
        'isDrinkMade': false,
        'salesId': salesId,
        // sourceId 1: 免費點擊交易 2: 付費點擊交易 3: 從購物車交易  4: QRcode交易免付費 5: QRcode交易折抵用 6: QRcode交易免付費且不限次數 7: QRcode交易折抵用且不限次數....9:單管注入
        'sourceId': source,
        'createdDateTime': DateTime.now().toString(),
        'remark': '',
        'qrCodeId': '',
      };

      for (int i = 1; i <= 16; i++) {
        if (i == 15) continue; // 跳過 g15
        values['correctWeight$i'] = 0;
        values['g$i'] = 0;
      }

      // 處理每個配方部分
      for (String part in stepParts) {
        List<String> keyValue = part.split('=');
        if (keyValue.length != 2) continue;

        String key = keyValue[0];
        int? value = int.tryParse(keyValue[1]);
        if (value == null) continue;

        // 取得管線編號(去掉'g'字首)
        int? pipeNumber = int.tryParse(key.substring(1));
        if (pipeNumber == null) continue;

        // 設定基本值
        values[key] = value;

        // 根據不同管線計算 correctWeight
        if (pipeNumber >= 1 && pipeNumber <= 12) {
          // 一般管線 1-12
          if (pipeNumber - 1 < correctFactors.length) {
            values['correctWeight$pipeNumber'] = (value * correctFactors[pipeNumber - 1]).round();
          }
        } else if (pipeNumber == 13 || pipeNumber == 14 || pipeNumber == 16) {
          // 特殊管線 13,14,16
          values['correctWeight$pipeNumber'] = (value * correctFactors[pipeNumber - 1]).round();
          // int factorIndex = _getFactorIndex(pipeNumber, pipeUseList.length);
          // if (factorIndex < correctFactors.length) {

          //   values['correctWeight$pipeNumber'] = (value * correctFactors[factorIndex]).round();
          // }
        }
      }
      // 搜尋 all_transaction_records 是否有相同的訂單編號 若有
      List<Map<String, dynamic>> querySnapshot = await DatabaseHelper().getAllRecordsByOrderNumber(orderNumber);

      if (querySnapshot.isNotEmpty) {
        debugPrint('搜尋 all_transaction_records 有相同的訂單編號');
      }

      if (mounted) {
        setState(() {
          stepPartsLength = stepParts.length;
        });
      }
      debugPrint('stepParts.length: ${stepParts.length} stepParts: ${stepParts.toString()} pipeUseList: ${pipeUseList.toString()}');
      if (stepPartsLength > 0) {
        var url = Uri.parse('http://$routerIP/get?${formulaString.split('@')[1]}');

        try {
          await http.get(url);
        } catch (e) {
          debugPrint('http.get error: $e');
        }
        debugPrint('urlSend: $url');

        int gPipeStatus = 0;
        int secCount = 1100;

        _statusTimer = Timer.periodic(Duration(milliseconds: secCount), (timer) async {
          if (gPipeStatus == 1000) {
            await http.get(Uri.parse('http://$routerIP/stop'));
            timer.cancel();
          } else if (gPipeStatus >= 0 && gPipeStatus < 1000 && sendStop == false) {
            responseData = await fetchData('http://$routerIP/status/');
            // .timeout(const Duration(milliseconds: 1200));
            final statusJsonResponse = jsonDecode(responseData);
            if (mounted) {
              setState(() {
                gPipeStatus = statusJsonResponse['status'];
              });
            }
          } else {
            timer.cancel();
            return;
          }

          debugPrint('目前進度 gPipeStatus: $gPipeStatus');
          if (gPipeStatus == 0 && sendStop == false) {
            timer.cancel();
            values['isDrinkMade'] = 1;
            // 製作完成
            try {
              if (!isDataWritten) {
                await DatabaseHelper().insertTransactionRecords(values);
                isDataWritten = true;
              }
            } catch (e) {
              debugPrint('寫入 all_transaction_records 錯誤 : $e');
            }

            if (mounted) {
              setState(() {
                // drinkMakingStatus = showEnglish ? 'Process Finished, Drink is Ready' : '製作完成! Cheers!';
                stepPartsLength = stepParts.length;
                underPicture = 'ThankPage.png';
              });
            }

            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('M$pipeUseId$createTime', orderNumber);

            debugPrint('http://$routerIP/get?${formulaString.split('@')[1]} 製作完成...');
            await getAlertLevelGrams();
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DrinkIsReady()));
          } else if (gPipeStatus == -100 && _showError && sendStop == false) {
            timer.cancel();
            values['price'] = 0;
            values['isDrinkMade'] = 0;
            if (!isDataWritten) {
              try {
                await DatabaseHelper().insertTransactionRecords(values);
                debugPrint('杯子移動失敗的時候寫入: gPipeStatus $gPipeStatus');
                isDataWritten = true;
              } catch (e) {
                debugPrint('寫入 all_transaction_records 錯誤 : $e');
              }
            }
            // 停止定時器
            if (mounted) {
              setState(() {
                // drinkMakingStatus = showEnglish ? 'cup moved! Failure! Please place a new cup for remake' : '杯子移動！失敗！請放新杯重新製作';
                needResume = true;
                _showError = false;
                pouringFail = 'CupRemoved';
              });
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    child: Stack(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height, // 設置高度
                          alignment: Alignment.center,
                          // color: healDarkGrey,
                          child: Image.file(
                            File('$documentsPath/images/Pouring_Fail_Cup_Removed.png'),
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                        Positioned(
                          top: 470,
                          left: 520,
                          child: GestureDetector(
                            onTap: () {
                              callStop();
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const MainPage()));
                            },
                            child: Container(
                              color: Colors.transparent,
                              width: 160,
                              height: 80.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
              await getAlertLevelGrams();
            }
          } else if (gPipeStatus >= -16 && gPipeStatus <= -1 && _showError && sendStop == false) {
            timer.cancel();
            values['price'] = 0;
            values['isDrinkMade'] = false;

            if (!isDataWritten) {
              try {
                await DatabaseHelper().insertTransactionRecords(values);
                debugPrint('$gPipeStatus管缺料的時候寫入: gPipeStatus $gPipeStatus');
                isDataWritten = true;
              } catch (e) {
                debugPrint('寫入 all_transaction_records 錯誤 : $e');
              }
            } // 停��定時器
            if (mounted) {
              setState(() {
                // drinkMakingStatus = showEnglish ? 'Failed, No Coffee in the Tube $status' : '製作失敗$status管已無料,補料後,按重新製作';
                needResume = true;
                _showError = false;
              });
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    child: Container(
                      width: 650,
                      height: 500,
                      decoration: BoxDecoration(
                        color: healUnderBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // cancel
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 60,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Pouring Fail',
                            style: TextStyle(
                              fontSize: 44.0,
                              color: healDarkGrey,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Arial',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '#${gPipeStatus.toString().replaceAll('-', '')} Tubes Material Empty',
                            style: const TextStyle(
                              fontSize: 32.0,
                              color: healDarkGrey,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Arial',
                            ),
                          ),
                          const SizedBox(height: 80),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  callStop();
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const MainPage()));
                                },
                                icon: Image.file(
                                  File('$documentsPath/images/cancel.png'),
                                  width: 150,
                                  height: 100,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
              await getAlertLevelGrams();
            }
          }
        });
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 650,
                height: 500,
                decoration: BoxDecoration(
                  color: healUnderBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // cancel
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Production failure',
                      style: TextStyle(
                        fontSize: 44.0,
                        color: healDarkGrey,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Arial',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      alignment: Alignment.center,
                      width: 400,
                      height: 280.0, // 設置高度
                      // color: healDarkGrey,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(children: [
                          TextSpan(
                            text: 'Formula String Empty, Press Remake',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Arial',
                              fontSize: 50.0,
                              color: healDarkGrey,
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 80),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            callStop();
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const MainPage()));
                          },
                          icon: Image.file(
                            File('$documentsPath/images/cancel.png'),
                            width: 150,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      debugPrint('error: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 650,
              height: 500,
              decoration: BoxDecoration(
                color: healUnderBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // cancel
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Router(Status) Error',
                    style: TextStyle(
                      fontSize: 44.0,
                      color: healDarkGrey,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Arial',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    alignment: Alignment.center,
                    width: 400,
                    height: 280.0, // 設置高度
                    // color: healDarkGrey,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'Error: $e',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Arial',
                            fontSize: 40.0,
                            color: healDarkGrey,
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 80),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          callStop();
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const MainPage()));
                        },
                        icon: Image.file(
                          File('$documentsPath/images/cancel.png'),
                          width: 150,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  callStop() async {
    try {
      await http.get(Uri.parse('http://$routerIP/stop'));
      if (mounted) {
        setState(() {
          sendStop = true;
        });
      }
    } catch (e) {
      debugPrint('error: $e');
      if (mounted) {
        setState(() {
          holdTime++;
        });
      }
      if (holdTime > 2) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 650,
                height: 500,
                decoration: BoxDecoration(
                  color: healUnderBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // cancel
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 44.0,
                        color: healDarkGrey,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Arial',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      alignment: Alignment.center,
                      width: 400,
                      height: 280.0, // 設置高度
                      // color: healDarkGrey,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(children: [
                          TextSpan(
                            text: 'Error $e',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Arial',
                              fontSize: 40.0,
                              color: healDarkGrey,
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 80),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            callStop();
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const MainPage()));
                          },
                          icon: Image.file(
                            File('$documentsPath/images/cancel.png'),
                            width: 150,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
        if (mounted) {
          setState(() {
            holdTime = 0;
          });
        }
      }
    }
  }

  Future<List<Map<String, String>>> getPipeName() async {
    List<Map<String, String>> pipeNames = [];
    try {
      for (var pipeItem in pipeUseList) {
        var keyValue = pipeItem.split(': ');
        if (keyValue.length == 2) {
          String key = keyValue[0].replaceAll('{', '');
          String value = keyValue[1].replaceAll('}', '');
          pipeNames.add({'g$key': value});
        }
      }
      // }
    } catch (e) {
      debugPrint('Error getting pipe names: $e');
    }
    return pipeNames;
  }

  Future<void> getAlertLevelGrams() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> fieldNames = [];
    getPipeName().then((value) async {
      for (Map<String, String> pipeContent in value) {
        fieldNames.add(pipeContent.keys.first);
      }
      for (var fieldName in fieldNames) {
        String keyGram = 'M$pipeUseId${fieldName}Gram';
        String keyResetDateTime = 'M$pipeUseId${fieldName}ResetDateTime';
        String keyFirstNoticeGram = 'M$pipeUseId${fieldName}FirstNoticeGram';
        String keyLastNoticeGram = 'M$pipeUseId${fieldName}LastNoticeGram';
        String? valueResetDateTime = prefs.getString(keyResetDateTime);
        String setDate = valueResetDateTime ?? '2023-05-18 00-00';
        int valueGram = int.parse(prefs.getString(keyGram) ?? '3000');
        int valueFirstNoticeGram = int.parse(prefs.getString(keyFirstNoticeGram) ?? '800');
        int valueLastNoticeGram = int.parse(prefs.getString(keyLastNoticeGram) ?? '300');

        List<Map<String, dynamic>> snapshot = await DatabaseHelper().getAllRecordsStart(setDate);

        num totalSum = 0;
        String correctWeightFieldName = fieldName.replaceAll('g', 'correctWeight');
        for (var doc in snapshot) {
          if (doc.containsKey(correctWeightFieldName)) {
            totalSum += doc[correctWeightFieldName];
          }
        }
        if (fieldName != 'g16') {
          //氣泡水來自氣泡機不用檢查剩餘克數
          debugPrint('${fieldName}setDate: $setDate');
          if (totalSum > (valueGram - valueFirstNoticeGram) && totalSum <= (valueGram - valueLastNoticeGram)) {
            if (mounted) {
              setState(() {
                stopRouteToMainPage = true;
              });
            }
            if (showRemainAlert) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    child: Container(
                      width: 650,
                      height: 500,
                      decoration: BoxDecoration(
                        color: healUnderBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // cancel
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 60,
                            color: Color.fromARGB(255, 250, 217, 2),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Warning Alert',
                            style: TextStyle(
                              fontSize: 44.0,
                              color: healDarkGrey,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Arial',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            alignment: Alignment.center,
                            width: 400,
                            height: 280.0, // 設置高度
                            // color: healDarkGrey,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(children: [
                                const TextSpan(
                                  text: 'Please check Pipe',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Arial',
                                    fontSize: 40.0,
                                    color: healDarkGrey,
                                  ),
                                ),
                                TextSpan(
                                  text: fieldName.toString().substring(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Arial',
                                    fontSize: 40.0,
                                    color: healDarkGrey,
                                  ),
                                ),
                                const TextSpan(
                                  text: ', remaining ML less than ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Arial',
                                    fontSize: 40.0,
                                    color: healDarkGrey,
                                  ),
                                ),
                                TextSpan(
                                  text: '$valueFirstNoticeGram',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Arial',
                                    fontSize: 40.0,
                                    color: healDarkGrey,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 80),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  callStop();
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const MainPage()));
                                },
                                icon: Image.file(
                                  File('$documentsPath/images/cancel.png'),
                                  width: 150,
                                  height: 100,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          } else if (totalSum > (valueGram - valueLastNoticeGram)) {
            if (mounted) {
              setState(() {
                stopRouteToMainPage = true;
              });
            }
            if (showRemainAlert) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    child: Container(
                      width: 650,
                      height: 500,
                      decoration: BoxDecoration(
                        color: healUnderBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // cancel
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 60,
                            color: Color.fromARGB(255, 250, 217, 2),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Warning Alert',
                            style: TextStyle(
                              fontSize: 44.0,
                              color: healDarkGrey,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Arial',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            alignment: Alignment.center,
                            width: 400,
                            height: 280.0, // 設置高度
                            // color: healDarkGrey,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(children: [
                                const TextSpan(
                                  text: 'Please check Pipe',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Arial',
                                    fontSize: 40.0,
                                    color: healDarkGrey,
                                  ),
                                ),
                                TextSpan(
                                  text: fieldName.toString().substring(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Arial',
                                    fontSize: 40.0,
                                    color: healDarkGrey,
                                  ),
                                ),
                                const TextSpan(
                                  text: ', remaining ML less than ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Arial',
                                    fontSize: 40.0,
                                    color: healDarkGrey,
                                  ),
                                ),
                                TextSpan(
                                  text: '$valueLastNoticeGram',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Arial',
                                    fontSize: 40.0,
                                    color: healDarkGrey,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 80),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  callStop();
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const MainPage()));
                                },
                                icon: Image.file(
                                  File('$documentsPath/images/cancel.png'),
                                  width: 150,
                                  height: 100,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          }
        }
      }
    });
  }

  void _showFormulaEmptyError() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 650,
            height: 500,
            decoration: BoxDecoration(
              color: healUnderBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Failed',
                  style: TextStyle(
                    fontSize: 44.0,
                    color: healDarkGrey,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Arial',
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  alignment: Alignment.center,
                  width: 400,
                  height: 280.0,
                  child: const Text(
                    'Formula data is empty, please select a drink again',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Arial',
                      fontSize: 40.0,
                      color: healDarkGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 80),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        callStop();
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const MainPage()));
                      },
                      icon: Image.file(
                        File('$documentsPath/images/cancel.png'),
                        width: 150,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFormulaFormatError() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 650,
            height: 500,
            decoration: BoxDecoration(
              color: healUnderBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Drink Make Failed',
                  style: TextStyle(
                    fontSize: 44.0,
                    color: healDarkGrey,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Arial',
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  alignment: Alignment.center,
                  width: 400,
                  height: 280.0,
                  child: const Text(
                    'Formula format error, please select a drink again',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Arial',
                      fontSize: 40.0,
                      color: healDarkGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 80),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        callStop();
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const MainPage()));
                      },
                      icon: Image.file(
                        File('$documentsPath/images/cancel.png'),
                        width: 150,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: healUnderBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0, top: 10.0),
            child: GestureDetector(
              onLongPress: () {
                callStop();
                Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const MainPage()));
              },
              child: const Text(
                'Long Pressed to Cancel',
                style: TextStyle(
                  color: healLightGrey,
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 800,
          height: 800,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: healDarkGrey.withOpacity(0.6 + (_animation.value - 2.5) / 10),
                        width: _animation.value * 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: healDarkGrey.withOpacity(0.2),
                          blurRadius: _animation.value * 1.5,
                          spreadRadius: _animation.value / 3,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Image.file(
                  File('$documentsPath/images/cup_preparing.png'),
                  height: 180,
                  fit: BoxFit.fitHeight,
                ),
              ),
              const SizedBox(height: 20),
              const Text('Your cup is preparing now ', style: TextStyle(color: healDarkGrey, fontSize: 28)),
            ],
          ),
        ),
      ),
    );
  }
}
