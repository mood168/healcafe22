// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class SettingsPopupSinglePipeInjection extends StatefulWidget {
  const SettingsPopupSinglePipeInjection({super.key});

  @override
  State<SettingsPopupSinglePipeInjection> createState() => _SettingsPopupSinglePipeInjectionState();
}

class _SettingsPopupSinglePipeInjectionState extends State<SettingsPopupSinglePipeInjection> {
  List<bool> _isSelectedList = [];
  List<dynamic> pipeUseList = [];
  // List<String> fieldNames = ['g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7', 'g8', 'g9', 'g10', 'g11', 'g12', 'g13', 'g14', 'g16'];
  String pipeUseId = '';
  String salesId = AllConstants().salesId;
  List<String> generateList() {
    List<String> result = [];
    for (int i = 5; i <= 300; i += 5) {
      result.add(i.toString());
    }
    return result;
  }

  List<String> gramList = [];
  int selectedValue = 0;
  String selectedGram = "15";
  bool showEnglish = AllConstants.showEnglish;
  String routerIP = AllConstants().routerIP;
  bool pressed = false;
  int gStatus = 0;
  List<double> correctFactors = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0];
  String processStatusMessage = '';
  bool showRemainAlert = false;

  @override
  void initState() {
    super.initState();

    gramList = generateList();

    Future.microtask(() async {
      await loadCorrectFactors();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          // 更新狀態
          showEnglish = prefs.getBool('showEnglish') ?? true;
          routerIP = prefs.getString('routerIP') ?? AllConstants().routerIP;
          pipeUseId = prefs.getString('pipeUseId') ?? '';
          salesId = prefs.getString('salesId') ?? AllConstants().salesId;
          processStatusMessage = AllConstants().singlePipeCleanStatus;
          showRemainAlert = prefs.getBool('showRemainAlert') ?? false;
          pressed = false;
          gStatus = 0;
        });
      }
      await getPipeUseList();
    });
  }

  Future<void> loadCorrectFactors() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List.generate(pipeUseList.length, (index) {
      String key;
      if (mounted) {
        setState(() {
          key = 'M${pipeUseId}_correctRatio_${index + 1}';
          if (index < pipeUseList.length - 1) {
            correctFactors.add(double.parse(prefs.getString(key) ?? 1.0.toString()));
          } else {
            if (pipeUseList.length == 13) {
              key = 'M${pipeUseId}_correctRatio_13';
              correctFactors.add(double.parse(prefs.getString(key) ?? 1.0.toString()));
              key = 'M${pipeUseId}_correctRatio_14';
              correctFactors.add(double.parse(prefs.getString(key) ?? 1.0.toString()));
              key = 'M${pipeUseId}_correctRatio_16';
              correctFactors.add(double.parse(prefs.getString(key) ?? 1.0.toString()));
            } else if (pipeUseList.length == 14) {
              key = 'M${pipeUseId}_correctRatio_14';
              correctFactors.add(double.parse(prefs.getString(key) ?? 1.0.toString()));
              key = 'M${pipeUseId}_correctRatio_16';
              correctFactors.add(double.parse(prefs.getString(key) ?? 1.0.toString()));
            } else if (pipeUseList.length == 15) {
              key = 'M${pipeUseId}_correctRatio_16';
              correctFactors.add(double.parse(prefs.getString(key) ?? 1.0.toString()));
            }
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

  Future<void> detectSinglePipeCleanGram(String selectedString) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> parts = selectedString.split('&');
    String orderNumber = prefs.getString('orderNumber') ?? '';
    Map<String, dynamic> values = {
      'salesId': salesId,
      // sourceId 1: 免費點擊交易 2: 付費點擊交易 3: 從購物車交易  4: QRcode交易免付費 5: QRcode交易折抵用 6: QRcode交易免付費且不限次數 7: QRcode交易折抵用且不限次數....9:單管注入
      'transactionOrderNo': orderNumber,
      'productName': showEnglish ? 'SinglePipeInjection' : '單管注入',
      'price': 0.0, // 0 :NoChange 1: CreditCard 2: OnlinePay 3.OnlineAtm 4: Cash
      'formulaString': selectedString,
      'imgPath': 'SinglePipeClean.png',
      'isDrinkMade': true,
      'sourceId': '9',
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
    for (String part in parts) {
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

    DatabaseHelper().insertTransactionRecords(values);
    await getAlertLevelGrams();
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

        final List<Map<String, dynamic>> snapshot = await DatabaseHelper().getAllRecordsStart(setDate);
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
            if (showRemainAlert) {
              showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                        backgroundColor: colorDark,
                        title: Text(showEnglish ? 'Error' : '注意', style: const TextStyle(color: colorWhite50, fontSize: 28)),
                        content: Text(showEnglish ? 'Please check $fieldName, remaining ML less than $valueFirstNoticeGram' : '請檢查 $fieldName, 剩餘毫升數小於 $valueFirstNoticeGram 毫升', style: const TextStyle(color: colorWhite50, fontSize: 24)),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(color: colorWhite50, fontSize: 24)),
                          ),
                        ],
                      ));
            }
          } else if (totalSum > (valueGram - valueLastNoticeGram)) {
            if (showRemainAlert) {
              showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                        backgroundColor: colorDark,
                        title: Text(showEnglish ? 'Error' : '注意', style: const TextStyle(color: colorWhite50, fontSize: 28)),
                        content: Text(showEnglish ? 'Please check $fieldName, remaining ML less than $valueFirstNoticeGram' : '請檢查 $fieldName, 剩餘毫升小於 $valueLastNoticeGram 毫升', style: const TextStyle(color: colorWhite50, fontSize: 24)),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(showEnglish ? 'Continue After ReFill' : '補料後繼續', style: const TextStyle(color: colorWhite50, fontSize: 24)),
                          ),
                          TextButton(
                            onPressed: () async {
                              await DatabaseHelper().getAllProducts().then((value) async {
                                debugPrint('doclength: ${value.length}');
                                for (var doc in value) {
                                  List<dynamic> alcoholList = doc['alcohol'].toString().split(',');
                                  if (alcoholList.any((alcohol) => alcohol.contains('$fieldName='))) {
                                    // 更新文檔的 active 字段
                                    await DatabaseHelper().updateProductActive({'docId': doc['docId'], 'active': false});
                                  }
                                }
                              });
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: Text(showEnglish ? 'Abort, Remove It From Drink Menu ' : '不補料，下架相關酒單', style: const TextStyle(color: colorWhite50, fontSize: 24)),
                          ),
                        ],
                      ));
            }
          }
        }
      }
    });
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
                itemExtent: 40,
                magnification: 1.2,
                scrollController: FixedExtentScrollController(initialItem: 2),
                children: gramList
                    .map((e) => Text(
                          showEnglish ? '$e Grams' : '$e克',
                          style: const TextStyle(
                            color: colorWhite50,
                            fontSize: 24,
                          ),
                        ))
                    .toList(),
                onSelectedItemChanged: (value) {
                  if (mounted) {
                    setState(() {
                      selectedValue = value;
                      selectedGram = gramList[value];
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
            height: 710.0,
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
                        showEnglish ? 'Single Pipe Injection' : '單管注入',
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
                              child: Text(showEnglish ? 'Inject　$selectedGram　grams' : '單管注入　$selectedGram　公克',
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
                                  showEnglish ? 'Gram Modify' : '變更設定',
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
                              height: 60,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(200, 60),
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
                                      processStatusMessage = showEnglish ? 'Injection Interrupt' : '注入動作取消';
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
                              height: 60,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(200, 60),
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
                                      urlString += '&g${int.parse(pipeUseList[i].replaceAll('{', '').replaceAll('}', '').split(':')[0].toString())}=$selectedGram';
                                    }
                                  }
                                  urlString = urlString.replaceAll('?&g', '?g');

                                  if (urlString.contains('?g')) {
                                    debugPrint(urlString);

                                    var url = Uri.parse('http://$routerIP/get$urlString');
                                    String selectedItem = urlString.split('?')[1];
                                    detectSinglePipeCleanGram(selectedItem);
                                    final responseClean = await http.get(url);
                                    if (responseClean.statusCode == 200 && pressed == false) {
                                      if (mounted) {
                                        setState(() {
                                          pressed = true;
                                        });
                                      }
                                      Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
                                        try {
                                          final response = await http.get(Uri.parse('http://$routerIP/status'));
                                          final statusJsonResponse = jsonDecode(response.body);
                                          final status = statusJsonResponse['status'];
                                          if (response.statusCode == 200) {
                                            debugPrint('status= $status');
                                            if (mounted) {
                                              setState(() {
                                                processStatusMessage = showEnglish ? 'Start injection...' : '開始注入....';
                                              });
                                            }

                                            if (status == 0) {
                                              timer.cancel();
                                              if (mounted) {
                                                setState(() {
                                                  pressed = false;
                                                  gStatus = 0;
                                                  processStatusMessage = showEnglish ? 'injection Completed! Prerss Quit button' : '注入完成! 請按取消離開';
                                                  _isSelectedList = List.generate(pipeUseList.length, (_) => false);
                                                });
                                              }
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Container(
                                                    height: 80.0, // 設置高度
                                                    alignment: Alignment.center,
                                                    // color: healDarkGrey,
                                                    child: Text(
                                                      showEnglish ? 'injection Completed' : '注入完成!',
                                                      style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                                    ),
                                                  ),
                                                  behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                                  ),
                                                  backgroundColor: healDarkGrey,
                                                ),
                                              );
                                              //Navigator.pop(context);
                                            } else if (status >= 1 && status <= 16) {
                                              if (mounted) {
                                                setState(() {
                                                  gStatus = status;
                                                  processStatusMessage = showEnglish ? 'Pipe$status injection' : '第$status管注入中...';
                                                });
                                              }
                                            } else if (status >= -16 && status <= -1) {
                                              timer.cancel(); // 停止定時器

                                              if (mounted) {
                                                setState(() {
                                                  pressed = false;
                                                  processStatusMessage = showEnglish ? 'Failed, No Coffee in the Tube $status' : '注入失敗$status管已無料, 補料後按重新注入';
                                                });
                                              }
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Container(
                                                    height: 80.0, // 設置高度
                                                    alignment: Alignment.center,
                                                    // color: healDarkGrey,
                                                    child: Text(
                                                      showEnglish ? 'Failed, No Coffee in the Tube $status' : '注入失敗$status管已無料, 補料後按重新注入',
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
                                        } catch (e) {
                                          timer.cancel();
                                          if (mounted) {
                                            setState(() {
                                              pressed = false;
                                            });
                                          }
                                          debugPrint(e.toString());
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Container(
                                                height: 80.0, // 設置高度
                                                alignment: Alignment.center,
                                                // color: healDarkGrey,
                                                child: Text(
                                                  showEnglish ? 'Error' : '錯誤',
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
                                      });
                                    } else {
                                      if (mounted) {
                                        setState(() {
                                          processStatusMessage = showEnglish ? 'Failed! Check Network Connection!' : '注入失敗! 請檢查網路連線!';
                                        });
                                      }
                                    }
                                  } else {
                                    if (mounted) {
                                      setState(() {
                                        pressed = false;
                                      });
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Container(
                                          height: 80.0, // 設置高度
                                          alignment: Alignment.center,
                                          // color: healDarkGrey,
                                          child: Text(
                                            showEnglish ? 'Please select one pipe at least' : '請至少選擇一個管路',
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
                                },
                                child: Text(
                                  showEnglish ? 'Process' : '開始執行',
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
