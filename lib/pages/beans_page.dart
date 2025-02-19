// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'constant.dart';
import 'database_helper.dart';
import 'hot_cold_page.dart';
import 'login_page.dart';
import 'main_page.dart';
import 'settings_page.dart';

class BeansPage extends StatefulWidget {
  const BeansPage({super.key, this.qrCodeId, this.source});

  final String? qrCodeId;
  final String? source;

  @override
  State<BeansPage> createState() => _BeansPageState();
}

class _BeansPageState extends State<BeansPage> {
  final StreamController<List<Map<String, dynamic>>> _streamController = StreamController();
  late PageController pageController;
  int _currentPage = 1;
  String documentsPath = AllConstants().documentsPath;
  String qrCodeId = '';
  String source = '1';
  int _selectedIndex = -1;
  String pipeUseId = '1';
  String userEmail = '';
  bool _showNewBlock = false;
  int stepPage = 1;
  bool showEnglish = true;
  List<double> correctFactors = [];
  List<dynamic> pipeUseList = [];
  // final List<dynamic> _gPipesList = [];
  int trueCount = 0;
  String pipeFieldName = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          pipeUseId = prefs.getString('pipeUseId') ?? '1';
        });
        // await getPipeUseList();
        // await loadCorrectFactors();
      }
    });
    pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.4, // 每個項目佔據屏幕的一半
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    List<Map<String, dynamic>> data = await DatabaseHelper().getAllProductsMenu();
    _streamController.add(data);
    if (mounted) {
      setState(() {
        // _products = DatabaseHelper().getAllProducts();
        qrCodeId = widget.qrCodeId ?? '';
        source = widget.source ?? '1';
      });
    }
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (mounted) {
      setState(() {
        _showNewBlock = true;
      });
    }
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      setState(() {
        _showNewBlock = false;
      });
    }
    _loadProducts();
  }

  // Future<void> getPipeUseList() async {
  //   // 從sqlite 中取出 pipeSettingString
  //   final db = await DatabaseHelper().database;
  //   final List<Map<String, dynamic>> maps = await db.query(
  //     'pipe_use_manage',
  //     where: 'active = ?',
  //     whereArgs: [1],
  //   );
  //   if (maps.isNotEmpty) {
  //     _gPipesList = [];
  //     if (mounted) {
  //       setState(() {
  //         pipeUseList = maps.first['pipeSettingString'].toString().split('@');
  //       });
  //     }
  //     List.generate(pipeUseList.length, (index) => {_gPipesList.add(pipeUseList[index].replaceAll('{', '').replaceAll('}', '').split(':')[1].trim())});
  //     if (mounted) {
  //       setState(() {
  //         _gPipesList = _gPipesList;
  //       });
  //     }
  //     print('pipeUseList: $pipeUseList , _gPipesList $_gPipesList');
  //   } else {
  //     _gPipesList = [];
  //     print('pipeUseList is empty');
  //   }
  // }

  // Future<void> loadCorrectFactors() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();

  //   List.generate(pipeUseList.length, (index) {
  //     String key;
  //     if (mounted) {
  //       setState(() {
  //         key = 'M${pipeUseId}_correctRatio_${index + 1}';
  //         if (index < pipeUseList.length - 1) {
  //           correctFactors.add(double.parse(prefs.getString(key) ?? 1.0.toString()));
  //         } else {
  //           if (pipeUseList.length == 13) {
  //             key = 'M${pipeUseId}_correctRatio_13';
  //             correctFactors.add(double.parse(prefs.getString(key) ?? 1.0.toString()));
  //             key = 'M${pipeUseId}_correctRatio_14';
  //             correctFactors.add(double.parse(prefs.getString(key) ?? 1.0.toString()));
  //             key = 'M${pipeUseId}_correctRatio_16';
  //             correctFactors.add(double.parse(prefs.getString(key) ?? 1.0.toString()));
  //           } else if (pipeUseList.length == 14) {
  //             key = 'M${pipeUseId}_correctRatio_14';
  //             correctFactors.add(double.parse(prefs.getString(key) ?? 1.0.toString()));
  //             key = 'M${pipeUseId}_correctRatio_16';
  //             correctFactors.add(double.parse(prefs.getString(key) ?? 1.0.toString()));
  //           } else if (pipeUseList.length == 15) {
  //             key = 'M${pipeUseId}_correctRatio_16';
  //             correctFactors.add(double.parse(prefs.getString(key) ?? 1.0.toString()));
  //           }
  //         }
  //       });
  //     }
  //     // return double.parse(prefs.getString(key) ?? 1.0.toString());
  //   });
  //   if (mounted) {
  //     setState(() {
  //       pipeUseList = pipeUseList;
  //       correctFactors = correctFactors;
  //     });
  //   }
  //   print('pipeUseList.length : ${pipeUseList.length}, correctFactors: ${correctFactors.toString()}');
  // }

  Future<bool> getAlertLevelGrams(fieldName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String keyGram = 'M$pipeUseId${fieldName}Gram';
    String keyResetDateTime = 'M$pipeUseId${fieldName}ResetDateTime';
    // String keyFirstNoticeGram = 'M$pipeUseId${fieldName}FirstNoticeGram';
    String keyLastNoticeGram = 'M$pipeUseId${fieldName}LastNoticeGram';
    String? valueResetDateTime = prefs.getString(keyResetDateTime);
    String setDate = valueResetDateTime ?? '2023-05-18 00-00';
    int valueGram = int.parse(prefs.getString(keyGram) ?? '3000');
    // int valueFirstNoticeGram = int.parse(prefs.getString(keyFirstNoticeGram) ?? '800');
    int valueLastNoticeGram = int.parse(prefs.getString(keyLastNoticeGram) ?? '300');

    List<Map<String, dynamic>> snapshot = await DatabaseHelper().getAllRecordsStart(setDate);

    num totalSum = 0;
    String correctWeightFieldName = fieldName.replaceAll('g', 'correctWeight');
    for (var doc in snapshot) {
      if (doc.containsKey(correctWeightFieldName)) {
        totalSum += doc[correctWeightFieldName];
      }
    }
    // print('totalSum: $totalSum');
    if (totalSum > (valueGram - valueLastNoticeGram)) {
      // if (totalSum > 2200) {
      return true;
    }
    //}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        backgroundColor: healRed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _showNewBlock
                  ? Row(
                      children: [
                        Expanded(
                          child: Container(
                            color: healRed,
                            height: 100,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const SettingsPage()));
                                    },
                                    icon: const Icon(Icons.settings, color: Colors.white, size: 80),
                                  ),
                                  IconButton(
                                      onPressed: () => {
                                            showDialog<bool>(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text('Logout Confirm', style: TextStyle(color: healRed, fontSize: 24)),
                                                  content: const Text('Are you sure?', style: TextStyle(color: healRed, fontSize: 22)),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child: const Text('Cancel', style: TextStyle(color: healRed, fontSize: 20)),
                                                      onPressed: () => Navigator.pop(context, false),
                                                    ),
                                                    TextButton(
                                                      child: const Text('Confirm', style: TextStyle(color: healRed, fontSize: 20)),
                                                      onPressed: () => {
                                                        SharedPreferences.getInstance().then((prefs) {
                                                          prefs.setString('uesrEmail', '');
                                                        }),
                                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          },
                                      icon: const Icon(Icons.account_circle, size: 80, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(),
              const SizedBox(height: 40),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _streamController.stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.height * 0.85,
                      child: const Center(
                        child: Text(
                          'No Products Found',
                          style: TextStyle(color: healRed, fontSize: 32),
                        ),
                      ),
                    );
                  } else {
                    final products = snapshot.data!;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          // width: MediaQuery.of(context).size.width * 0.85,
                          height: MediaQuery.of(context).size.height * 0.85,
                          child: PageView.builder(
                              controller: pageController,
                              itemCount: products.length,
                              onPageChanged: (int page) {
                                if (mounted) {
                                  setState(() {
                                    _currentPage = page;
                                  });
                                }
                              },
                              itemBuilder: (context, index) {
                                String productName = products[index]['productName'].toString();
                                String docId = products[index]['docId'].toString();
                                String formulaString = products[index]['alcohol'].toString().replaceAll('"', '').replaceAll('[', '').replaceAll(']', '');
                                String assetImg = products[index]['imgPath'].toString();
                                int price = products[index]['price'];
                                List<String> formulaGpipeList = formulaString.split('@');

                                List<String> gPipesList = [];
                                if (formulaGpipeList.length == 2) {
                                  gPipesList.add(formulaGpipeList[1].split('=')[0]);
                                } else if (formulaGpipeList.length == 3) {
                                  gPipesList.add(formulaGpipeList[1].split('=')[0]);
                                  gPipesList.add(formulaGpipeList[2].split('=')[0]);
                                } else if (formulaGpipeList.length == 4) {
                                  gPipesList.add(formulaGpipeList[1].split('=')[0]);
                                  gPipesList.add(formulaGpipeList[2].split('=')[0]);
                                  gPipesList.add(formulaGpipeList[3].split('=')[0]);
                                } else if (formulaGpipeList.length == 5) {
                                  gPipesList.add(formulaGpipeList[1].split('=')[0]);
                                  gPipesList.add(formulaGpipeList[2].split('=')[0]);
                                  gPipesList.add(formulaGpipeList[3].split('=')[0]);
                                  gPipesList.add(formulaGpipeList[4].split('=')[0]);
                                }
                                gPipesList = gPipesList.toSet().toList(); // 將gPipesList 中的項目有重複的字串 移除
                                return FutureBuilder(
                                    future: Future.wait(gPipesList.map((fieldName) => getAlertLevelGrams(fieldName))),
                                    builder: (context, AsyncSnapshot<List<bool>> snapshot) {
                                      if (!snapshot.hasData) {
                                        return const CircularProgressIndicator();
                                      }
                                      int trueCount = snapshot.data!.where((result) => result).length;
                                      if (trueCount == 1) {
                                        // 取得fieldName
                                        pipeFieldName = gPipesList[snapshot.data!.indexOf(true)];
                                        debugPrint('pipeFieldName: $pipeFieldName');
                                      }

                                      return GestureDetector(
                                        onTap: () {
                                          if (trueCount <= 1) {
                                            if (mounted) {
                                              setState(() {
                                                _selectedIndex = index; // 更新選中的圖片索引
                                              });
                                              Future.delayed(const Duration(milliseconds: 700), () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (BuildContext context) => HotColdPage(
                                                              productName: productName,
                                                              docId: docId,
                                                              formulaString: formulaString,
                                                              assetImg: assetImg,
                                                              price: price,
                                                              pipeFieldName: pipeFieldName,
                                                            )));
                                              });
                                            }
                                          }
                                        },
                                        child: Transform.scale(
                                          scale: 0.95,
                                          child: Container(
                                            // margin: const EdgeInsets.symmetric(horizontal: 5),
                                            decoration: BoxDecoration(
                                              color: bgColor,
                                              // borderRadius: const BorderRadius.all(Radius.circular(1)),
                                              border: Border.fromBorderSide(
                                                BorderSide(
                                                  strokeAlign: BorderSide.strokeAlignCenter,
                                                  color: _selectedIndex == index ? healRed : bgColor,
                                                  width: 22.0,
                                                ),
                                              ),
                                            ),
                                            child: trueCount >= 2
                                                ? Stack(children: [
                                                    Image.file(
                                                      File('$documentsPath/images/$assetImg'),
                                                      width: 700,
                                                      fit: BoxFit.fill,
                                                      color: Colors.grey.shade300,
                                                      colorBlendMode: BlendMode.color,
                                                    ),
                                                    Positioned(
                                                      left: 20,
                                                      top: 30,
                                                      child: GestureDetector(
                                                        onLongPress: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                              return Dialog(
                                                                backgroundColor: Colors.transparent,
                                                                child: Stack(
                                                                  children: [
                                                                    Container(
                                                                      width: 650,
                                                                      height: 500,
                                                                      alignment: Alignment.center,
                                                                      // color: healRed,
                                                                      child: Image.file(
                                                                        File('$documentsPath/images/Refill_Alert.png'),
                                                                        fit: BoxFit.fitHeight,
                                                                      ),
                                                                    ),
                                                                    Positioned(
                                                                      top: 130,
                                                                      left: 20,
                                                                      child: Container(
                                                                        alignment: Alignment.center,
                                                                        width: 600,
                                                                        height: 200.0, // 設置高度
                                                                        // color: healRed,
                                                                        child: RichText(
                                                                          textAlign: TextAlign.center,
                                                                          text: const TextSpan(children: [
                                                                            TextSpan(
                                                                              text: 'Continue After Refill or Removed Relative Material from Menu',
                                                                              style: TextStyle(
                                                                                fontFamily: 'Arsenica',
                                                                                fontSize: 36.0,
                                                                                color: healRed,
                                                                              ),
                                                                            ),
                                                                          ]),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Positioned(
                                                                      top: 345,
                                                                      left: 25,
                                                                      child: GestureDetector(
                                                                        onTap: () {
                                                                          Navigator.pop(context);
                                                                          Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const MainPage()));
                                                                        },
                                                                        child: Container(
                                                                          color: Colors.transparent,
                                                                          width: 260,
                                                                          height: 80.0,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Positioned(
                                                                      top: 345,
                                                                      left: 298,
                                                                      child: GestureDetector(
                                                                        onTap: () async {
                                                                          debugPrint('Press');
                                                                          await DatabaseHelper().getAllProducts().then((value) async {
                                                                            debugPrint('doclength: ${value.length}');
                                                                            for (var doc in value) {
                                                                              List<dynamic> alcoholList = doc['alcohol'].toString().split(',');
                                                                              bool shouldDeactivate = false;

                                                                              for (var pipe in gPipesList) {
                                                                                if (alcoholList.any((alcohol) => alcohol.contains('$pipe='))) {
                                                                                  shouldDeactivate = true;
                                                                                  break;
                                                                                }
                                                                              }

                                                                              if (shouldDeactivate) {
                                                                                // 更新文檔的 active 字段
                                                                                await DatabaseHelper().updateProductActive({'docId': doc['docId'], 'active': false});
                                                                              }
                                                                            }
                                                                          });
                                                                          Navigator.pop(context);
                                                                          Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const MainPage()));
                                                                        },
                                                                        child: Container(
                                                                          color: Colors.transparent,
                                                                          width: 323,
                                                                          height: 80.0,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                        child: Container(
                                                          alignment: Alignment.center,
                                                          // color: Colors.yellow,
                                                          // decoration: const BoxDecoration(boxShadow: [
                                                          //   BoxShadow(
                                                          //     color: colorDarkGrey,
                                                          //   ),
                                                          // ]),
                                                          width: 450,
                                                          height: 80,
                                                          child: RichText(
                                                            textAlign: TextAlign.center,
                                                            text: const TextSpan(children: [
                                                              TextSpan(
                                                                text: '⚠️',
                                                                style: TextStyle(
                                                                  fontFamily: 'Lufga',
                                                                  fontSize: 36.0,
                                                                  color: Colors.red,
                                                                ),
                                                              ),
                                                              TextSpan(text: '   '),
                                                              TextSpan(
                                                                text: 'Not Enough',
                                                                style: TextStyle(
                                                                  fontFamily: 'Arsenica',
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 36.0,
                                                                  color: Colors.red,
                                                                ),
                                                              ),
                                                            ]),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  ])
                                                : Image.file(
                                                    File('$documentsPath/images/$assetImg'),
                                                    width: 700,
                                                    fit: BoxFit.fill,
                                                  ),
                                          ),
                                        ),
                                      );
                                    });
                              }),
                        ),
                        SmoothPageIndicator(
                          controller: pageController, // PageController
                          count: products.length,
                          effect: const WormEffect(), // 你可以選擇不同的效果
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
