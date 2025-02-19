// ignore_for_file: use_build_context_synchronously, avoid_print
import 'package:flutter/material.dart';
import 'system_variables.dart';
import 'database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';

class ShowPipesVolume extends StatefulWidget {
  const ShowPipesVolume({
    super.key,
  });

  @override
  State<ShowPipesVolume> createState() => _ShowPipesVolumeState();
}

class _ShowPipesVolumeState extends State<ShowPipesVolume> {
  bool showPrice = AllConstants.showPrice;
  bool showEnglish = AllConstants.showEnglish;
  List<Map<String, String>> pipeContents = [];
  List<dynamic> pipeUseList = [];
  List<Map<String, num>> sums = [];
  String pipeUseId = '';
  List<Map<String, dynamic>> pipeName = [];
  List<TextEditingController> textControllers = [];
  List<TextEditingController> firstNoticeControllers = [];
  List<TextEditingController> lastNoticeControllers = [];
  Map<String, String?> gPipeResetDateTimes = {};

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          pipeUseId = prefs.getString('pipeUseId') ?? AllConstants().pipeUseId;
          showEnglish = prefs.getBool('showEnglish') ?? AllConstants.showEnglish;
          showPrice = prefs.getBool('showPrice') ?? AllConstants.showPrice;
        });
      }
      await getPipeUseList().then((values) {
        if (mounted) {
          setState(() {
            pipeUseList = values;
          });
        }
        debugPrint('pipeUseList22: $pipeUseList');
      });
      await getPipeName(pipeUseList).then((values) {
        if (mounted) {
          setState(() {
            pipeName = values;
          });
        }
        debugPrint('pipeName33: $pipeName');
      });
      getEachSum(pipeName);
      initializeTextControllers(pipeName);
    });

    getGPipeResetDateTimes().then((dateTimes) {
      if (mounted) {
        setState(() {
          gPipeResetDateTimes = dateTimes;
        });
      }
    });
  }

  void initializeTextControllers(List<Map<String, dynamic>> pipeName) async {
    List<String> fieldNames = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();

    for (Map<String, dynamic> pipeContent in pipeName) {
      fieldNames.add(pipeContent.keys.first);
    }
    if (fieldNames.isNotEmpty) {
      for (String fieldName in fieldNames) {
        TextEditingController controller = TextEditingController();
        TextEditingController firstNoticeController = TextEditingController();
        TextEditingController lastNoticeController = TextEditingController();
        if (fieldName == 'g16') {
          controller.text = prefs.getString('M$pipeUseId${fieldName}Gram') ?? '20000';
          firstNoticeController.text = prefs.getString('M$pipeUseId${fieldName}FirstNoticeGram') ?? '800';
          lastNoticeController.text = prefs.getString('M$pipeUseId${fieldName}LastNoticeGram') ?? '500';
        } else {
          controller.text = prefs.getString('M$pipeUseId${fieldName}Gram') ?? '5000';
          firstNoticeController.text = prefs.getString('M$pipeUseId${fieldName}FirstNoticeGram') ?? '800';
          lastNoticeController.text = prefs.getString('M$pipeUseId${fieldName}LastNoticeGram') ?? '500';
        }
        textControllers.add(controller);
        firstNoticeControllers.add(firstNoticeController);
        lastNoticeControllers.add(lastNoticeController);
        if (textControllers.length == fieldNames.length) {
          // 所有數據已經加載完成，進行排序操作
          textControllers.sort((a, b) {
            int indexA = fieldNames.indexOf(a.text);
            int indexB = fieldNames.indexOf(b.text);
            return indexA.compareTo(indexB);
          });
          firstNoticeControllers.sort((a, b) {
            int indexA = fieldNames.indexOf(a.text);
            int indexB = fieldNames.indexOf(b.text);
            return indexA.compareTo(indexB);
          });
          lastNoticeControllers.sort((a, b) {
            int indexA = fieldNames.indexOf(a.text);
            int indexB = fieldNames.indexOf(b.text);
            return indexA.compareTo(indexB);
          });
          // debugPrint(textControllers.toString());
        }
      }
    }
  }

  Future<List> getPipeUseList() async {
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
        });
      }
      // debugPrint('pipeUseList: $pipeUseList');
      return pipeUseList;
    } else {
      debugPrint('pipeUseList is empty');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getPipeName(pipeUseList) async {
    List<Map<String, dynamic>> pipeNames = [];
    try {
      // List<Map<String, dynamic>> querySnapshot = await DatabaseHelper().getAllPipeUses();
      for (var pipeItem in pipeUseList) {
        // 將 '{1: Lemon}' 字符串轉換為 Map<String, String>
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

  Future<void> getEachSum(List<Map<String, dynamic>> pipeName) async {
    List<String> fieldNames = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();

    for (Map<String, dynamic> pipeContent in pipeName) {
      fieldNames.add(pipeContent.keys.first);
    }
    debugPrint('fieldNames: $fieldNames');
    if (mounted) {
      if (fieldNames.isNotEmpty) {
        for (var fieldName in fieldNames) {
          String key = 'M$pipeUseId${fieldName}ResetDateTime';
          String? value = prefs.getString(key);
          String setDate = value ?? '2099-01-01 00-00';
          debugPrint('fieldName: $fieldName ,setDate: $setDate');

          await getTotalSum(fieldName, setDate).then((value) {
            if (mounted) {
              setState(() {
                sums.add({fieldName: value});
              });
            }
          });
        }
        if (sums.isNotEmpty) {
          if (mounted) {
            setState(() {
              sums.sort((a, b) {
                int indexA = fieldNames.indexOf(a.keys.first);
                int indexB = fieldNames.indexOf(b.keys.first);
                return indexA.compareTo(indexB);
              });
              debugPrint('sums: $sums');
            });
          }
        }
      }
    }
  }

  Future<num> getTotalSum(String fieldName, String setDate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    pipeUseId = prefs.getString('pipeUseId') ?? '';
    List<Map<String, dynamic>> snapshot = await DatabaseHelper().getAllRecords();
    num totalSum = 0;
    if (snapshot.isNotEmpty) {
      for (var doc in snapshot) {
        String correctWeightFieldName = fieldName.replaceAll('g', 'correctWeight');
        if (doc.containsKey(correctWeightFieldName)) {
          totalSum += doc[correctWeightFieldName];
        }
      }
    }
    return totalSum;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      color: colorDark,
      child: StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: colorDark,
            child: Center(
              child: Container(
                // height: MediaQuery.sizeOf(context).height,//800.0,
                width: 1200.0,
                decoration: const BoxDecoration(
                  color: colorDarkGrey,
                ),
                child: Column(
                  children: [
                    Expanded(
                      flex: 9,
                      child: SingleChildScrollView(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.85,
                          child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2,
                              ),
                              itemCount: sums.length,
                              itemBuilder: (context, index) {
                                Map<String, num> item = sums[index];
                                // String key = item.keys.first;
                                num value = item.values.first;
                                if (pipeName.isNotEmpty) {
                                  Map<String, dynamic> pipeItem = pipeName[index];
                                  // String pipeKey = pipeItem.keys.first.toString();
                                  String pipeValue = pipeItem.values.first.toString();

                                  String gKey = gPipeResetDateTimes.keys.elementAt(index);
                                  String? gValue = gPipeResetDateTimes[gKey] ?? '2023-12-31 00:00:00';

                                  return Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Container(
                                        // height 為 width 的 0.5 倍
                                        // height:
                                        //     MediaQuery.of(context).size.height * 0.2,
                                        decoration: const BoxDecoration(
                                          color: colorDark,
                                        ),
                                        child: Column(
                                          children: [
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                              pipeValue,
                                              style: const TextStyle(
                                                color: colorWhite50,
                                                fontSize: 28.0,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(20, 8, 10, 8),
                                              child: Row(
                                                children: [
                                                  AnimatedContainer(
                                                    duration: const Duration(milliseconds: 500), // 動畫持續時間
                                                    curve: Curves.easeInOut, // 動畫曲線
                                                    width: 110,
                                                    height: 150,
                                                    decoration: BoxDecoration(
                                                      color: colorWhite30,
                                                      borderRadius: const BorderRadius.only(
                                                        bottomLeft: Radius.circular(15),
                                                        bottomRight: Radius.circular(15),
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.5),
                                                          spreadRadius: 5,
                                                          blurRadius: 7,
                                                          offset: const Offset(0, 3),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Stack(
                                                      children: [
                                                        Visibility(
                                                          visible: value >= 2500,
                                                          child: Center(
                                                            child: Text(
                                                              (3000 - value).toStringAsFixed(0),
                                                              style: const TextStyle(
                                                                color: colorWhite80,
                                                                fontSize: 30,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          bottom: 8,
                                                          left: 10,
                                                          right: 10,
                                                          height: (int.parse(textControllers[index].text) - value) / int.parse(textControllers[index].text) * 150, // 根據水量比例設置高度
                                                          child: Container(
                                                            decoration: const BoxDecoration(
                                                              color: healLightGrey,
                                                              borderRadius: BorderRadius.only(
                                                                bottomLeft: Radius.circular(10),
                                                                bottomRight: Radius.circular(10),
                                                              ),
                                                            ),
                                                            child: Visibility(
                                                              visible: value < 2500,
                                                              child: Center(
                                                                child: Text(
                                                                  (int.parse(textControllers[index].text) - value).toStringAsFixed(0),
                                                                  style: const TextStyle(
                                                                    color: colorWhite80,
                                                                    fontSize: 30,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 30,
                                                  ),
                                                  Column(
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          Center(
                                                            child: Text(
                                                              showEnglish ? 'Initial Level:' : '滿位容量ml數: ',
                                                              style: const TextStyle(
                                                                color: colorWhite80,
                                                                fontSize: 22,
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 107,
                                                            height: 45,
                                                            child: TextFormField(
                                                              controller: textControllers[index],
                                                              keyboardType: TextInputType.number,
                                                              maxLength: 6,
                                                              textAlign: TextAlign.center,
                                                              style: const TextStyle(
                                                                color: colorWhite80,
                                                                // backgroundColor: colorWhite80,
                                                                fontFamily: 'Poppins',
                                                                fontSize: 24,
                                                                fontWeight: FontWeight.w300,
                                                              ),
                                                              decoration: const InputDecoration(
                                                                contentPadding: EdgeInsets.fromLTRB(2, 2, 2, 2),
                                                                labelStyle: TextStyle(
                                                                  fontFamily: 'Poppins',
                                                                  color: colorWhite80,
                                                                  fontSize: 24,
                                                                  fontWeight: FontWeight.w300,
                                                                ),
                                                                enabledBorder: OutlineInputBorder(
                                                                  borderSide: BorderSide(
                                                                    color: colorWhite80,
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                                border: OutlineInputBorder(
                                                                  borderSide: BorderSide(
                                                                    color: colorWhite80,
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                                counterText: '',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Center(
                                                            child: Text(
                                                              showEnglish ? 'FirstAlert(g):' : '首次警告水位: ',
                                                              style: const TextStyle(
                                                                color: colorWhite80,
                                                                fontSize: 22,
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 100,
                                                            height: 45,
                                                            child: TextFormField(
                                                              controller: firstNoticeControllers[index],
                                                              keyboardType: TextInputType.number,
                                                              maxLength: 6,
                                                              textAlign: TextAlign.center,
                                                              style: const TextStyle(
                                                                color: colorWhite80,
                                                                // backgroundColor: colorWhite80,
                                                                fontFamily: 'Poppins',
                                                                fontSize: 24,
                                                                fontWeight: FontWeight.w300,
                                                              ),
                                                              decoration: const InputDecoration(
                                                                contentPadding: EdgeInsets.fromLTRB(2, 2, 2, 2),
                                                                labelStyle: TextStyle(
                                                                  fontFamily: 'Poppins',
                                                                  color: colorWhite80,
                                                                  fontSize: 24,
                                                                  fontWeight: FontWeight.w300,
                                                                ),
                                                                enabledBorder: OutlineInputBorder(
                                                                  borderSide: BorderSide(
                                                                    color: colorWhite80,
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                                border: OutlineInputBorder(
                                                                  borderSide: BorderSide(
                                                                    color: colorWhite80,
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                                counterText: '',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Center(
                                                            child: Text(
                                                              showEnglish ? 'LastAlert(g):' : '最終警告水位: ',
                                                              style: const TextStyle(
                                                                color: colorWhite80,
                                                                fontSize: 22,
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 100,
                                                            height: 45,
                                                            child: TextFormField(
                                                              controller: lastNoticeControllers[index],
                                                              keyboardType: TextInputType.number,
                                                              maxLength: 6,
                                                              textAlign: TextAlign.center,
                                                              style: const TextStyle(
                                                                color: colorWhite80,
                                                                // backgroundColor: colorWhite80,
                                                                fontFamily: 'Poppins',
                                                                fontSize: 26,
                                                                fontWeight: FontWeight.w300,
                                                              ),
                                                              decoration: const InputDecoration(
                                                                contentPadding: EdgeInsets.fromLTRB(2, 2, 2, 2),
                                                                labelStyle: TextStyle(
                                                                  fontFamily: 'Poppins',
                                                                  color: colorWhite80,
                                                                  fontSize: 26,
                                                                  fontWeight: FontWeight.w300,
                                                                ),
                                                                enabledBorder: OutlineInputBorder(
                                                                  borderSide: BorderSide(
                                                                    color: colorWhite80,
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                                border: OutlineInputBorder(
                                                                  borderSide: BorderSide(
                                                                    color: colorWhite80,
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                                counterText: '',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    width: 30,
                                                  ),
                                                  Column(
                                                    children: [
                                                      Text(
                                                        showEnglish ? 'Last Update:' : '上次更新: ',
                                                        style: const TextStyle(
                                                          color: colorWhite80,
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Text(gValue.substring(0, 10), style: const TextStyle(color: colorWhite80, fontSize: 20)),
                                                      Text(gValue.substring(11, 19), style: const TextStyle(color: colorWhite80, fontSize: 20)),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      TextButton(
                                                        style: TextButton.styleFrom(
                                                          minimumSize: const Size(100, 50),
                                                          foregroundColor: healDarkGrey,
                                                          backgroundColor: colorDark,
                                                          side: const BorderSide(
                                                            color: healDarkGrey,
                                                            width: 2,
                                                          ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(5),
                                                          ),
                                                        ),
                                                        onPressed: () async {
                                                          await showDialog(
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                              return AlertDialog(
                                                                backgroundColor: colorDarkGrey,
                                                                title: Text(
                                                                  showEnglish ? 'Attention' : '請注意',
                                                                  style: const TextStyle(
                                                                    color: colorWhite80,
                                                                    fontSize: 24,
                                                                  ),
                                                                ),
                                                                content: Text(
                                                                  showEnglish ? 'To reset the field value?' : '是否確定重置欄位值?',
                                                                  style: const TextStyle(
                                                                    color: colorWhite80,
                                                                    fontSize: 24,
                                                                  ),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    child: Text(
                                                                      showEnglish ? 'Cancel' : '取消',
                                                                      style: const TextStyle(
                                                                        color: colorWhite80,
                                                                        fontSize: 24,
                                                                      ),
                                                                    ),
                                                                    onPressed: () {
                                                                      Navigator.of(context).pop(); // 關閉對話框
                                                                      // 在取消操作時執行其他邏輯
                                                                    },
                                                                  ),
                                                                  TextButton(
                                                                    child: Text(
                                                                      showEnglish ? 'Set' : '確定',
                                                                      style: const TextStyle(
                                                                        color: colorWhite80,
                                                                        fontSize: 24,
                                                                      ),
                                                                    ),
                                                                    onPressed: () async {
                                                                      SharedPreferences prefs = await SharedPreferences.getInstance();
                                                                      List<String> fieldNames = [];
                                                                      for (Map<String, dynamic> pipeContent in pipeName) {
                                                                        fieldNames.add(pipeContent.keys.first);
                                                                      }
                                                                      prefs.setString('M$pipeUseId${fieldNames[index]}Gram', textControllers[index].text);
                                                                      prefs.setString('M$pipeUseId${fieldNames[index]}FirstNoticeGram', firstNoticeControllers[index].text);
                                                                      prefs.setString('M$pipeUseId${fieldNames[index]}LastNoticeGram', lastNoticeControllers[index].text);
                                                                      prefs.setString('M$pipeUseId${fieldNames[index]}ResetDateTime', DateTime.now().toString());
                                                                      getEachSum(pipeName);
                                                                      debugPrint('M$pipeUseId${fieldNames[index]}ResetDateTime');

                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(
                                                                          content: Container(
                                                                            height: 80.0, // 設置高度
                                                                            alignment: Alignment.center,
                                                                            // color: healDarkGrey,
                                                                            child: Text(
                                                                              showEnglish ? 'Pipe Volume System are Modified, Restart it' : '更改完成, 請重新開啟 原料管理 系統',
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
                                                                      Navigator.of(context).pop();
                                                                      // getEachSum(); // 第一次關閉小對話框
                                                                      // Navigator.of(context).pop(); // 第2次關閉主對話框
                                                                      if (mounted) {
                                                                        setState(() {
                                                                          gValue = gPipeResetDateTimes[fieldNames[index]];
                                                                        });
                                                                      }
                                                                    },
                                                                  ),
                                                                ],
                                                                actionsAlignment: MainAxisAlignment.spaceAround,
                                                              );
                                                            },
                                                          );
                                                        },
                                                        child: Text(
                                                          showEnglish ? 'Set' : '確定',
                                                          style: const TextStyle(
                                                            fontSize: 24,
                                                            color: colorWhite80,
                                                            fontWeight: FontWeight.w400,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )),
                                  );
                                } else {
                                  // circularProgress();
                                  return const Center(
                                    child: SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: CircularProgressIndicator(
                                        color: colorWhite50,
                                      ),
                                    ),
                                  );
                                }
                              }),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 200,
                          height: 60,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(200, 60),
                              foregroundColor: healDarkGrey,
                              backgroundColor: colorDark,
                              side: const BorderSide(
                                color: healDarkGrey,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                            },
                            child: Text(
                              showEnglish ? 'Quit' : '離開',
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
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
