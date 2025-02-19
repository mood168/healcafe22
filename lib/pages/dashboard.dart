// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'constant.dart';
import 'database_helper.dart';

class TransactionRecord {
  TransactionRecord(this.imgPath, this.transactionOrderNo, this.createdDateTime, this.isDrinkMade, this.productName, this.price, this.sourceId, this.salesId, this.remark);

  final String imgPath;
  final String transactionOrderNo;
  final DateTime createdDateTime;
  final bool isDrinkMade;
  final String productName;
  final int price;
  final String sourceId;
  final String salesId;
  final String remark;

  factory TransactionRecord.fromSnapshot(doc) {
    return TransactionRecord(
      doc.get('imgPath'),
      doc.get('transactionOrderNo'),
      doc.get('createdDateTime'),
      doc.get('isDrinkMade'),
      doc.get('productName'),
      doc.get('price').toDouble(),
      doc.get('sourceId'),
      doc.get('salesId'),
      doc.get('remark'),
    );
  }
}

class ChartData {
  final String category;
  final double value;

  ChartData(this.category, this.value);
}

class ProductTotal {
  String name;
  int total;
  int quantity;

  ProductTotal({required this.name, required this.total, required this.quantity});
}

class PaymentTotal {
  String method;
  int total;

  PaymentTotal({required this.method, required this.total});
}

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  Future<List<Map<String, dynamic>>> records = Future.value([]);
  Future<List<Map<String, dynamic>>> recordsByDate = Future.value([]);
  Future<List<Map<String, dynamic>>> recordsByDateBySource = Future.value([]);
  // late Database _database;
  late List<Map<String, dynamic>> _data;
  // late List<Map<String, dynamic>> _dataSearchOrigin;
  TextEditingController queryController = TextEditingController();
  String pipeUseId = '1';
  bool sort = true;
  bool isKeyboardVisible = false;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  int selectedDay = DateTime.now().day;
  final int defaultUsage = 3000;
  bool hasFetchedYearData = false;
  bool hasFetchedMonthData = false;
  bool showEnglish = AllConstants.showEnglish;
  int yearTransactionCount = 0;
  int monthTransactionCount = 0;
  int dayTransactionCount = 0;
  int dayTransactionTotal = 0;
  int monthTransactionTotal = 0;
  int yearTransactionTotal = 0;
  String startDate = DateTime.now().toString().substring(0, 10);
  String endDate = DateTime.now().toString().substring(0, 10);
  final String startDay = DateTime.now().toString().substring(0, 10);
  String endDay = DateTime.now().toString().substring(0, 10);
  String startMonth = DateTime.now().toString().substring(0, 7);
  String endMonth = DateTime.now().toString().substring(0, 7);
  String startYear = DateTime.now().toString().substring(0, 4);
  String endYear = DateTime.now().toString().substring(0, 4);
  String selectType = '';
  String selectSource = '';
  DateTime selectedDate = DateTime.now();

  List<dynamic> pipeUseList = [];
  List<dynamic> _gPipesList = [];
  List<String> _correctConstants = ['1.0', '1.0', '1.0', '1.0', '1.0', '1.0', '1.0', '1.0', '1.0', '1.0', '1.0', '1.0', '1.0', '1.0', '1.0'];
  Map<String, double> gPipeTotals = {};
  Map<String, double> correctTotals = {};
  List<TextEditingController> correctControllers = [];
  String documentsPath = '/storage/emulated/0/Documents/moodapp';
  Future<List<Map<String, dynamic>>> transactionsFuture = Future.value([]);
  String type = '';
  String selectedPickDate = '';
  String datePickCount = '';
  String rangeCount = '';
  String _pickStartDate = '';
  String _pickEndDate = '';
  String startString = '';
  String endString = '';
  final DateRangePickerController _datePickerController = DateRangePickerController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          showEnglish = prefs.getBool('showEnglish') ?? false;
          pipeUseId = prefs.getString('pipeUseId') ?? '1';
        });
      }
      if (mounted) {
        setState(() {
          selectType = 'month';
          selectSource = '';
        });
      }
      await fetchTransactions(selectType, selectSource, '', '');
      await getPipeUseList();
      await loadCorrectRatioValues();
      getYMDTransactionData('year').then((yearResult) {
        if (mounted) {
          setState(() {
            yearTransactionCount = yearResult[0];
            yearTransactionTotal = yearResult[1];
          });
        }
      });
      getYMDTransactionData('month').then((monthResult) {
        if (mounted) {
          setState(() {
            monthTransactionCount = monthResult[0];
            monthTransactionTotal = monthResult[1];
          });
        }
      });

      getYMDTransactionData('day').then((dayResult) {
        if (mounted) {
          setState(() {
            dayTransactionCount = dayResult[0];
            dayTransactionTotal = dayResult[1];
          });
        }
      });
    });
    if (mounted) {
      setState(() {
        selectedMonth = DateTime.now().month;
        selectedYear = DateTime.now().year;
        startDate = DateTime.now().toString().substring(0, 10);
        endDate = DateTime.now().toString().substring(0, 10);
        endDay = DateTime.now().toString().substring(0, 10);
        startMonth = DateTime.now().toString().substring(0, 7);
        endMonth = DateTime.now().toString().substring(0, 7);
        startYear = DateTime.now().toString().substring(0, 4);
        endYear = DateTime.now().toString().substring(0, 4);
        KeyboardVisibilityController().onChange.listen((bool isVisible) {
          if (mounted) {
            setState(() {
              isKeyboardVisible = isVisible;
            });
          }
        });
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> loadDataByDate(startDate, endDate) async {
    debugPrint('loadDataByDate: $startDate, $endDate');
    if (mounted) {
      setState(() {
        recordsByDate = DatabaseHelper().getAllRecordsStartEnd(startDate, endDate);
      });
    }
    return recordsByDate;
  }

  Future<List<Map<String, dynamic>>> loadDataByDateBySource(startDate, endDate, source) async {
    if (mounted) {
      setState(() {
        recordsByDateBySource = DatabaseHelper().getAllRecordsStartEndBySource(startDate, endDate, source);
      });
    }
    return recordsByDateBySource;
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
      setState(() {
        pipeUseList = maps.first['pipeSettingString'].toString().split('@');
      });
      List.generate(pipeUseList.length, (index) => {_gPipesList.add(pipeUseList[index].replaceAll('{', '').replaceAll('}', '').split(':')[1].trim())});
      setState(() {
        _gPipesList = _gPipesList;
        correctControllers = List.generate(_gPipesList.length, (index) => TextEditingController());
      });
      debugPrint('pipeUseList: $pipeUseList , _gPipesList $_gPipesList');
    } else {
      _gPipesList = [];
      debugPrint('pipeUseList is empty');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Tab> myTabs = <Tab>[
      Tab(
        text: showEnglish ? 'Transaction Info' : '交易資訊紀錄',
        // height: 50,
      ),
      Tab(
        text: showEnglish ? 'Product Usage' : '商品銷售排行',
        // height: 50,
      ),
      Tab(
        text: showEnglish ? 'Material Usage' : '原料用量管理',
        // height: 50,
      ),
    ];
    return KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
      return DefaultTabController(
        length: myTabs.length,
        child: Scaffold(
          backgroundColor: colorDark,
          appBar: AppBar(
            backgroundColor: colorDark,
            centerTitle: true,
            title: TabBar(
              tabs: myTabs,
              dividerColor: colorDark,
              tabAlignment: TabAlignment.center,
              labelStyle: const TextStyle(fontSize: 24),
              isScrollable: true,
              indicatorColor: colorWhite30,
              labelColor: colorWhite80,
            ),
            leading: SizedBox(
              width: 60,
              height: 60,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_outlined, color: colorWhite80, size: 40),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: [
              _buildTabOne(),
              _buildTabTwo(),
              _buildTabThree(),
            ],
          ),
        ),
      );
    });
  }

  Future<List<Map<String, dynamic>>> fetchTransactions(String type, String source, String startPickDate, String endPickDate) async {
    DateTime initialDate = DateTime.parse('$startMonth-01 00:00:00');
    DateTime oneMonthLater = DateTime(initialDate.year, initialDate.month + 1, initialDate.day); // 增加1個月
    DateTime oneDayLess = oneMonthLater.subtract(const Duration(seconds: 1)); // 減去1天
    String startDateString = '';
    String endDateString = '';
    List<Map<String, dynamic>> query = [];

    if (type == 'day') {
      if (startPickDate == '' && endPickDate == '') {
        startDateString = '$startDay 00:00:00';
        endDateString = '$endDay 23:59:59';
      } else {
        startDateString = '$startPickDate 00:00:00';
        endDateString = '$endPickDate 23:59:59';
      }
    } else if (type == 'month') {
      if (startPickDate == '' && endPickDate == '') {
        startDateString = '$startMonth-01 00:00:00';
        endDateString = '$oneDayLess';
      } else {
        startDateString = '$startPickDate 00:00:00';
        endDateString = '$endPickDate 23:59:59';
      }
    } else if (type == 'year') {
      if (startPickDate == '' && endPickDate == '') {
        startDateString = '$startYear-01-01 00:00:00';
        endDateString = '$endYear-12-31 23:59:59';
      } else {
        startDateString = '$startPickDate 00:00:00';
        endDateString = '$endPickDate 23:59:59';
      }
    }

    setState(() {
      startString = startDateString;
      endString = endDateString;
    });
    if (type != '') {
      if (source != '') {
        query = await loadDataByDateBySource(startDateString, endDateString, source);

        return query;
      }
      query = await loadDataByDate(startDateString, endDateString);
      debugPrint('query: ${query.length}');
      return query;
    }
    query = await DatabaseHelper().getAllRecords();
    return query;
  }

  Future<String> getFieldTotals(String gPipeFieldName, String correctFieldName) async {
    // 獲取當前時間
    DateTime? now = DateTime.now();
    DateTime startOfHour = DateTime(now.year, now.month, now.day, now.hour);
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    List<Map<String, dynamic>> querySnapshot = [];

    // 從sqlite 的資料表 'all_transaction_records' 中獲取資料 where createdDateTime >= startOfDay
    querySnapshot = await DatabaseHelper().getAllRecordsStart(startOfMonth.toString().substring(0, 10));

    // 初始化總計變數
    double gTotal = 0;
    double gHourlyTotal = 0;
    double gDailyTotal = 0;
    double gWeeklyTotal = 0;
    double gMonthlyTotal = 0;
    double cTotal = 0;
    double cHourlyTotal = 0;
    double cDailyTotal = 0;
    double cWeeklyTotal = 0;
    double cMonthlyTotal = 0;
    // 遍歷查詢結果
    for (var doc in querySnapshot) {
      double gPipeValue = doc[gPipeFieldName]?.toDouble() ?? 0;
      double cPipeValue = doc[correctFieldName]?.toDouble() ?? 0;
      debugPrint('gPipeValue: $gPipeValue cPipeValue: $cPipeValue');
      // 計算總計
      gTotal = gTotal + gPipeValue;
      cTotal = cTotal + cPipeValue;
      DateTime docDate = DateTime.parse(doc['createdDateTime']);

      // 計算時總計
      if (docDate.isAfter(DateTime.parse(startOfHour.toString().substring(0, 19)))) {
        gHourlyTotal += gPipeValue;
        cHourlyTotal += cPipeValue;
      }
      // 計算日總計
      if (docDate.isAfter(DateTime.parse('${startOfDay.toString().substring(0, 10)} 00:00:00'))) {
        gDailyTotal += gPipeValue;
        cDailyTotal += cPipeValue;
      }
      // 計算周總計
      if (docDate.isAfter(DateTime.parse('${startOfWeek.toString().substring(0, 10)} 00:00:00'))) {
        gWeeklyTotal += gPipeValue;
        cWeeklyTotal += cPipeValue;
      }
      // 計算月總計
      if (docDate.isAfter(DateTime.parse('${startOfMonth.toString().substring(0, 10)} 00:00:00'))) {
        gMonthlyTotal += gPipeValue;
        cMonthlyTotal += cPipeValue;
      }
    }

    // 返回結果
    return showEnglish
        ? 'Hourly : ${cHourlyTotal.toInt()} ml.   ( ${gHourlyTotal.toInt()} g )\nDaily : ${cDailyTotal.toInt()} ml.   ( ${gDailyTotal.toInt()} g )\nWeekly : ${cWeeklyTotal.toInt()} ml.   ( ${gWeeklyTotal.toInt()} g )\nMonthly : ${cMonthlyTotal.toInt()} ml.   ( ${gMonthlyTotal.toInt()} g )'
        : '小時用量 : ${cHourlyTotal.toInt()} ml.   ( ${gHourlyTotal.toInt()} g )\n本日用量 : ${cDailyTotal.toInt()} ml.   ( ${gDailyTotal.toInt()} g )\n本週用量 : ${cWeeklyTotal.toInt()} ml.   ( ${gWeeklyTotal.toInt()} g )\n本月用量 : ${cMonthlyTotal.toInt()} ml.   ( ${gMonthlyTotal.toInt()} g )';
  }

  Widget showColumn(String gPipeName, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colorDarkGrey,
        border: Border.all(color: healDarkGrey),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                showEnglish ? 'Pipe${(index + 1).toString()}:' : '管${(index + 1).toString()}:',
                style: const TextStyle(color: colorWhite50, fontSize: 24),
              ),
              const SizedBox(width: 10),
              Text(
                gPipeName,
                style: const TextStyle(
                  color: colorWhite50,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 10,
            child: Container(
              height: double.infinity,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.indigoAccent.withOpacity(0.1),
              ),
              // alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            showEnglish ? 'Summary Total - ' : '校正參數 : ',
                            style: const TextStyle(color: colorWhite50, fontSize: 20),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            showEnglish ? 'Corrections:' : '校正參數 : ',
                            style: const TextStyle(color: colorWhite50, fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: Text(
                            _correctConstants[index].toString(),
                            style: const TextStyle(color: colorWhite50, fontSize: 26),
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      color: healDarkGrey,
                      thickness: 1,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FutureBuilder<String>(
                          future: getFieldTotals('g${(index + 1)}', 'correctWeight${(index + 1)}'),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(color: colorWhite50, fontSize: 22),
                              );
                            } else {
                              return Text(
                                snapshot.data ?? '',
                                style: const TextStyle(color: colorWhite50, fontSize: 22),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> loadCorrectRatioValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _gPipesList.length; i++) {
      _correctConstants[i] = prefs.getString('M${pipeUseId}_correctRatio_$i') ?? '1.0';
      if (_gPipesList.length == 13 && i == 12) {
        _correctConstants[12] = prefs.getString('M${pipeUseId}_correctRatio_13') ?? '1.0';
        _correctConstants[13] = prefs.getString('M${pipeUseId}_correctRatio_14') ?? '1.0';
        _correctConstants[14] = prefs.getString('M${pipeUseId}_correctRatio_16') ?? '1.0';
      } else if (_gPipesList.length == 14 && i == 13) {
        _correctConstants[13] = prefs.getString('M${pipeUseId}_correctRatio_14') ?? '1.0';
        _correctConstants[14] = prefs.getString('M${pipeUseId}_correctRatio_16') ?? '1.0';
      } else if (_gPipesList.length == 15 && i == 14) {
        _correctConstants[14] = prefs.getString('M${pipeUseId}_correctRatio_16') ?? '1.0';
      }
    }
    setState(() {
      _correctConstants = _correctConstants;
    });
  }

  Widget _buildTabOne() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      color: colorDark,
      child: Stack(children: [
        Dialog(
            backgroundColor: colorDark,
            surfaceTintColor: colorDark,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: 200,
                          height: 50,
                          color: colorDark,
                          child: Center(
                            child: TextField(
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search, color: colorWhite30),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                  borderSide: BorderSide(color: colorWhite30),
                                ),
                                hintText: showEnglish ? 'Input Order ID' : '輸入訂單編號',
                                hintStyle: const TextStyle(color: colorWhite30, fontSize: 24),
                              ),
                              style: const TextStyle(color: colorWhite80),
                              textAlign: TextAlign.start,
                              textAlignVertical: TextAlignVertical.bottom,
                              textInputAction: TextInputAction.done,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _data = DatabaseHelper().getAllRecordsLike(value) as List<Map<String, dynamic>>;
                                });
                                debugPrint('value: $value');
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Center(
                          child: Text(
                            startString != '' && endString != '' ? '${startString.substring(0, 10)} ~ ${endString.substring(0, 10)}' : '',
                            style: const TextStyle(color: colorWhite80, fontSize: 24),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  selectSource = '1';
                                });
                                fetchTransactions(selectType, selectSource, '', '');
                              },
                              icon: const Icon(Icons.ads_click_outlined, color: Colors.blueAccent, size: 30),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectSource = '1';
                                });
                                fetchTransactions(selectType, selectSource, '', '');
                              },
                              child: Text(
                                showEnglish ? 'Free / ' : '免費 / ',
                                style: const TextStyle(color: colorWhite80, fontSize: 20),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  selectSource = '2';
                                });
                                fetchTransactions(selectType, selectSource, '', '');
                              },
                              icon: const Icon(Icons.attach_money_outlined, color: Colors.green, size: 30),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectSource = '2';
                                });
                                fetchTransactions(selectType, selectSource, '', '');
                              },
                              child: Text(
                                showEnglish ? 'Paid / ' : '付費 / ',
                                style: const TextStyle(color: colorWhite80, fontSize: 20),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  selectSource = '3';
                                });
                                fetchTransactions(selectType, selectSource, '', '');
                              },
                              icon: const Icon(Icons.shopping_cart_rounded, color: Colors.redAccent, size: 30),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectSource = '3';
                                });
                                fetchTransactions(selectType, selectSource, '', '');
                              },
                              child: Text(
                                showEnglish ? 'Cart / ' : '購物車 / ',
                                style: const TextStyle(color: colorWhite80, fontSize: 20),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  selectSource = '4';
                                });
                                fetchTransactions(selectType, selectSource, '', '');
                              },
                              icon: const Icon(Icons.qr_code_outlined, color: Colors.tealAccent, size: 30),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectSource = '4';
                                });
                                fetchTransactions(selectType, selectSource, '', '');
                              },
                              child: Text(
                                showEnglish ? 'QRCode' : 'QRCode',
                                style: const TextStyle(color: colorWhite80, fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    flex: 10,
                    child: Container(
                      width: double.infinity,
                      height: 615,
                      decoration: BoxDecoration(
                        border: Border.all(color: colorWhite30),
                        borderRadius: BorderRadius.circular(5),
                        color: colorDark,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 13,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  FutureBuilder<List<Map<String, dynamic>>>(
                                    future: selectType == ''
                                        ? records
                                        : selectSource == ''
                                            ? recordsByDate
                                            : recordsByDateBySource,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      // debugPrint('snapshot.hasData: ${snapshot.hasData}');
                                      if (!snapshot.hasData) {
                                        return Center(
                                          child: Text(
                                            showEnglish
                                                ? selectType == 'day'
                                                    ? 'No Data. Today!'
                                                    : selectType == 'month'
                                                        ? 'No Data. This Month!'
                                                        : 'No Data.'
                                                : selectType == 'day'
                                                    ? '本日尚無資料.'
                                                    : selectType == 'month'
                                                        ? '本月尚無資料.'
                                                        : '目前尚無資料.',
                                            style: const TextStyle(color: colorWhite80, fontSize: 28),
                                          ),
                                        );
                                      }
                                      _data = (snapshot.data ?? []);
                                      // _dataSearchOrigin = _data;
                                      // debugPrint('datalength: $_data.length');

                                      return Theme(
                                        data: ThemeData.light().copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: colorDark,
                                            onPrimary: colorDark,
                                            surface: colorDark,
                                            onSurface: colorWhite30,
                                          ),
                                          cardColor: colorDark,
                                          dividerColor: colorWhite30,
                                          textTheme: const TextTheme(
                                            bodySmall: TextStyle(color: colorWhite50, fontSize: 22), //分頁文字大小
                                          ),
                                          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                                            backgroundColor: colorDark,
                                            selectedItemColor: colorWhite80,
                                            unselectedItemColor: colorWhite30,
                                          ),
                                          dropdownMenuTheme: const DropdownMenuThemeData(
                                            inputDecorationTheme: InputDecorationTheme(
                                              labelStyle: TextStyle(color: colorDark, fontSize: 22),
                                            ),
                                          ),
                                        ),
                                        child: PaginatedDataTable(
                                          columns: [
                                            DataColumn(
                                              label: Text(
                                                showEnglish ? 'OrderID' : '訂單編號',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: colorWhite80, fontSize: 20),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                showEnglish ? 'Name' : '品名',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: colorWhite80, fontSize: 20),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                showEnglish ? 'Order Date' : '訂單時間',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: colorWhite80, fontSize: 20),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                showEnglish ? 'Result' : '結果',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: colorWhite80, fontSize: 20),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                showEnglish ? 'Price' : '價格',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: colorWhite80, fontSize: 20),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                showEnglish ? 'Source' : '來源',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: colorWhite80, fontSize: 20),
                                              ),
                                            ),
                                          ],
                                          source: TransactionDataSource(_data, showEnglish: showEnglish),
                                          rowsPerPage: 10,
                                          columnSpacing: 20,
                                          horizontalMargin: 10,
                                          showCheckboxColumn: false,
                                          arrowHeadColor: colorWhite80,
                                          dataRowMinHeight: 30,
                                          dataRowMaxHeight: 50,
                                          sortColumnIndex: 0,
                                          showFirstLastButtons: true,
                                          initialFirstRowIndex: 0,
                                          showEmptyRows: false,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () {
                                      transactionsFuture = fetchTransactions('day', '', '', '');
                                      setState(() {
                                        selectType = 'day';
                                        selectSource = '';
                                      });
                                    },
                                    child: Container(
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: selectType == 'day' ? healDarkGrey : colorWhite30, width: selectType == 'day' ? 3 : 1),
                                        borderRadius: BorderRadius.circular(5),
                                        color: colorDark,
                                      ),
                                      child: Center(child: dayTransactionWidget()),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () {
                                      transactionsFuture = fetchTransactions('month', '', '', '');
                                      setState(() {
                                        selectType = 'month';
                                        selectSource = '';
                                      });
                                    },
                                    child: Container(
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: selectType == 'month' ? healDarkGrey : colorWhite30, width: selectType == 'month' ? 3 : 1),
                                        borderRadius: BorderRadius.circular(5),
                                        color: colorDark,
                                      ),
                                      child: Center(child: monthTransactionWidget()),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () {
                                      transactionsFuture = fetchTransactions('year', '', '', '');
                                      setState(() {
                                        selectType = 'year';
                                        selectSource = '';
                                      });
                                    },
                                    child: Container(
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: selectType == 'year' ? healDarkGrey : colorWhite30, width: selectType == 'year' ? 3 : 1),
                                        borderRadius: BorderRadius.circular(5),
                                        color: colorDark,
                                      ),
                                      child: Center(child: yearTransactionWidget()),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ]),
    );
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      if (args.value is PickerDateRange) {
        _pickStartDate = DateFormat('yyyy-MM-dd').format(args.value.startDate);
        _pickEndDate = DateFormat('yyyy-MM-dd').format(args.value.endDate ?? args.value.startDate);
      } else if (args.value is DateTime) {
        selectedPickDate = args.value.toString();
      } else if (args.value is List<DateTime>) {
        datePickCount = args.value.length.toString();
      } else {
        rangeCount = args.value.length.toString();
      }
    });
  }

  Widget _buildTabTwo() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      color: colorDark,
      child: Stack(children: [
        Dialog(
            backgroundColor: colorDark,
            surfaceTintColor: colorDark,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    flex: 10,
                    child: Container(
                      width: double.infinity,
                      height: 615,
                      decoration: BoxDecoration(
                        border: Border.all(color: colorWhite30),
                        borderRadius: BorderRadius.circular(5),
                        color: colorDark,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 13,
                            child: FutureBuilder(
                              future: selectType == ''
                                  ? records
                                  : selectSource == ''
                                      ? recordsByDate
                                      : recordsByDateBySource,
                              builder: (BuildContext context, AsyncSnapshot snapshot) {
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                }
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Text(showEnglish ? 'Loading' : '載入中...');
                                }
                                // 無資料時顯示
                                if (snapshot.data.isEmpty) {
                                  return Center(
                                    child: Text(
                                      showEnglish ? 'No data' : '目前無交易資料',
                                      style: const TextStyle(fontSize: 24, color: colorWhite50),
                                    ),
                                  );
                                }
                                debugPrint('snapshot.data: ${snapshot.data.length.toString()}');

                                List<ProductTotal> productTotals = [];
                                productTotals = snapshot.data.fold<List<ProductTotal>>(<ProductTotal>[], (List<ProductTotal> acc, Map<String, dynamic> document) {
                                  String name = document['productName'];
                                  double price = document['price'].toDouble();
                                  int quantity = 1;

                                  int index = acc.indexWhere((element) => element.name == name);
                                  if (index == -1) {
                                    if (name != '單管注入') {
                                      acc.add(ProductTotal(name: name, total: price.toInt(), quantity: quantity));
                                    }
                                  } else {
                                    if (document['isDrinkMade'] == 1) {
                                      acc[index].total += price.toInt();
                                    }
                                    acc[index].quantity = acc[index].quantity + 1;
                                  }
                                  return acc;
                                });
                                productTotals.sort((a, b) => b.quantity.compareTo(a.quantity));

                                return Column(
                                  children: [
                                    const SizedBox(
                                      height: 20.0,
                                    ),
                                    Text(
                                      showEnglish
                                          ? selectType == 'day'
                                              ? startString != '' && endString != ''
                                                  ? 'Daily Sales Rank(${startString.substring(0, 10)}~${endString.substring(0, 10)})'
                                                  : ''
                                              : selectType == 'month'
                                                  ? startString != '' && endString != ''
                                                      ? 'Monthly Sales Rank(${startString.substring(0, 10)}~${endString.substring(0, 10)})'
                                                      : ''
                                                  : startString != '' && endString != ''
                                                      ? 'Yearly Sales Rank(${startString.substring(0, 10)}~${endString.substring(0, 10)})'
                                                      : ''
                                          : selectType == 'day'
                                              ? startString != '' && endString != ''
                                                  ? '本日銷售排行榜(${startString.substring(0, 10)}~${endString.substring(0, 10)})'
                                                  : ''
                                              : selectType == 'month'
                                                  ? startString != '' && endString != ''
                                                      ? '本月銷售排行榜(${startString.substring(0, 10)}~${endString.substring(0, 10)})'
                                                      : ''
                                                  : startString != '' && endString != ''
                                                      ? '本年銷售排行榜(${startString.substring(0, 10)}~${endString.substring(0, 10)})'
                                                      : '',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: colorWhite50,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20.0,
                                    ),
                                    Expanded(
                                      flex: 12,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                                        child: ListView.builder(
                                          itemCount: productTotals.length + 1, // 增加1來包含header
                                          itemBuilder: (context, index) {
                                            if (index == 0) {
                                              // Header row
                                              return Container(
                                                height: 50,
                                                color: Colors.grey[800], // 設置灰色背景
                                                // padding: EdgeInsets.all(8.0), // 添加一些內邊距
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Expanded(flex: 1, child: Text(showEnglish ? 'No.' : '排行', style: const TextStyle(fontSize: 26, color: colorWhite50))),
                                                    Expanded(
                                                      flex: 1,
                                                      child: Center(child: Text(showEnglish ? 'Image' : '圖片', style: const TextStyle(fontSize: 26, color: colorWhite50))),
                                                    ),
                                                    Expanded(
                                                      flex: 5,
                                                      child: Text(showEnglish ? '       Name' : '        商品名稱', textAlign: TextAlign.left, style: const TextStyle(fontSize: 26, color: colorWhite50)),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(showEnglish ? 'Quantity' : '數量', textAlign: TextAlign.left, style: const TextStyle(fontSize: 26, color: colorWhite50)),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(showEnglish ? 'Price' : '    總價', style: const TextStyle(fontSize: 26, color: colorWhite50)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            } else {
                                              // Data row
                                              final product = productTotals[index - 1]; // 減去1來對應數據
                                              return Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Expanded(flex: 1, child: Text((index).toString(), style: const TextStyle(fontSize: 32, color: colorWhite50))),
                                                  Expanded(
                                                    flex: 5,
                                                    child: product.name == ''
                                                        ? const Text('N/A', style: TextStyle(fontSize: 26, color: colorWhite50))
                                                        : Text(product.name, textAlign: TextAlign.left, style: const TextStyle(fontSize: 26, color: colorWhite50)),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(showEnglish ? '  ${product.quantity}' : '${product.quantity} 杯', style: const TextStyle(fontSize: 26, color: colorWhite50)),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(showEnglish ? '\$${product.total}' : 'NT\$ ${product.total}', style: const TextStyle(fontSize: 26, color: colorWhite50)),
                                                  ),
                                                ],
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      fetchTransactions('day', '', '', '');
                                      setState(() {
                                        selectType = 'day';
                                        selectSource = '';
                                      });
                                    },
                                    child: Container(
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: selectType == 'day' ? healDarkGrey : colorWhite30, width: selectType == 'day' ? 3 : 1),
                                        borderRadius: BorderRadius.circular(5),
                                        color: colorDark,
                                      ),
                                      child: Center(child: dayTransactionWidget()),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      fetchTransactions('month', '', '', '');
                                      setState(() {
                                        selectType = 'month';
                                        selectSource = '';
                                      });
                                    },
                                    child: Container(
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: selectType == 'month' ? healDarkGrey : colorWhite30, width: selectType == 'month' ? 3 : 1),
                                        borderRadius: BorderRadius.circular(5),
                                        color: colorDark,
                                      ),
                                      child: Center(child: monthTransactionWidget()),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      fetchTransactions('year', '', '', '');
                                      setState(() {
                                        selectType = 'year';
                                        selectSource = '';
                                      });
                                    },
                                    child: Container(
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: selectType == 'year' ? healDarkGrey : colorWhite30, width: selectType == 'year' ? 3 : 1),
                                        borderRadius: BorderRadius.circular(5),
                                        color: colorDark,
                                      ),
                                      child: Center(child: yearTransactionWidget()),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ]),
    );
  }

  Widget _buildTabThree() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      color: colorDark,
      child: Dialog(
          backgroundColor: colorDark,
          surfaceTintColor: colorDark,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // for (int i = 0; i < _gPipesList.length; i++) showRow(_gPipesList[i].toString(), i),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      // mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: _gPipesList.length,
                    itemBuilder: (context, index) {
                      return showColumn(_gPipesList[index].toString(), index);
                    },
                  ),
                ],
              ),
            ),
          )),
    );
  }

  Future<List<int>> getYMDTransactionData(String type) async {
    var startDate = '$startYear-01-01 00:00:00';
    var endDate = '$endYear-12-31 23:59:59';
    List<Map<String, dynamic>> querySnapshot = [];
    if (type == 'month') {
      DateTime endMonthStart = DateTime.parse('$endMonth-01 23:59:59');
      DateTime endMonthLater = DateTime(endMonthStart.year, endMonthStart.month + 1, endMonthStart.day); // 增加1個月
      DateTime endMonthLess = endMonthLater.subtract(const Duration(seconds: 1)); // 減去1天
      startDate = '$startMonth-01 00:00:00';
      endDate = '$endMonthLess';
    }
    if (type == 'day') {
      startDate = '$startDay 00:00:00';
      endDate = '$endDay 23:59:59';
    }

    querySnapshot = await DatabaseHelper().getAllRecordsStartEnd(startDate.toString(), endDate.toString());

    // debugPrint('query: ${querySnapshot.toString()}');

    num priceTotal = 0;
    int transactionCount = 0;

    for (var doc in querySnapshot) {
      if (doc['productName'] == '單管注入' || doc['productName'] == 'SinglePipeClean') {
        transactionCount += 1;
      } else {
        if (doc['isDrinkMade'] == 1) {
          priceTotal += doc['price'] ?? 0;
        }
      }
    }

    int allTransactionCount = querySnapshot.length - transactionCount;
    int allTransactionTotal = priceTotal.toInt();

    return [allTransactionCount, allTransactionTotal];
  }

  Widget dayTransactionWidget() {
    return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 10,
            ),
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: 200,
                      width: 300,
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            flex: 9,
                            child: SfDateRangePicker(
                              controller: _datePickerController,
                              onSelectionChanged: _onSelectionChanged,
                              selectionMode: DateRangePickerSelectionMode.range,
                              navigationMode: DateRangePickerNavigationMode.scroll,
                              navigationDirection: DateRangePickerNavigationDirection.horizontal,
                              headerHeight: 100,
                              showNavigationArrow: true,
                              initialSelectedRange: PickerDateRange(
                                DateTime.now().subtract(const Duration(days: 4)),
                                DateTime.now().add(const Duration(days: 3)),
                              ),
                              backgroundColor: Colors.white,
                              // 設置選擇範圍的顏色
                              selectionColor: healDarkGrey,
                              // 設置起始日期的顏色
                              rangeTextStyle: const TextStyle(color: colorDark, fontSize: 24),
                              selectionTextStyle: const TextStyle(color: colorDark, fontSize: 32),
                              // 設置今天的顏色
                              todayHighlightColor: colorDark,
                              // 設置標題樣式
                              headerStyle: const DateRangePickerHeaderStyle(
                                textAlign: TextAlign.center,
                                textStyle: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: colorDark,
                                ),
                              ),
                              // 設置月份單元格樣式
                              monthCellStyle: const DateRangePickerMonthCellStyle(
                                textStyle: TextStyle(fontSize: 24, color: colorDark),
                                todayTextStyle: TextStyle(fontSize: 24, color: healDarkGrey),
                                disabledDatesTextStyle: TextStyle(color: colorDark),
                              ),
                              // 設置年份單元格樣式
                              yearCellStyle: const DateRangePickerYearCellStyle(
                                textStyle: TextStyle(fontSize: 24, color: colorDark),
                                todayTextStyle: TextStyle(fontSize: 24, color: healDarkGrey),
                                disabledDatesTextStyle: TextStyle(color: colorDark),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              height: 50,
                              color: Colors.white,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  SizedBox(
                                    width: 300,
                                    height: 50,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(200, 60),
                                        foregroundColor: healDarkGrey,
                                        backgroundColor: colorWhite80,
                                        side: const BorderSide(
                                          color: healDarkGrey,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                      child: Text(showEnglish ? 'Cancel' : '取消', style: const TextStyle(fontSize: 24, color: healDarkGrey)),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 300,
                                    height: 50,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(200, 60),
                                        foregroundColor: healDarkGrey,
                                        backgroundColor: colorWhite80,
                                        side: const BorderSide(
                                          color: healDarkGrey,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                      child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(fontSize: 24, color: healDarkGrey)),
                                      onPressed: () {
                                        fetchTransactions(selectType, selectSource, _pickStartDate, _pickEndDate);
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    showEnglish ? 'Day Records' : '日交易筆數',
                    style: const TextStyle(
                      fontSize: 20,
                      color: colorWhite80,
                    ),
                  ),
                  Text(
                    showEnglish ? ' / Amount' : ' / 金額',
                    style: const TextStyle(
                      fontSize: 20,
                      color: healDarkGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                color: colorDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$dayTransactionCount',
                    style: const TextStyle(
                      fontSize: 50,
                      color: colorWhite80,
                    ),
                  ),
                  Text(
                    ' / $dayTransactionTotal',
                    style: const TextStyle(
                      fontSize: 38,
                      color: healDarkGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget monthTransactionWidget() {
    return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 10,
            ),
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: 200,
                      width: 300,
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            flex: 9,
                            child: SfDateRangePicker(
                              controller: _datePickerController,
                              view: DateRangePickerView.year,
                              onSelectionChanged: _onSelectionChanged,
                              selectionMode: DateRangePickerSelectionMode.range,
                              navigationMode: DateRangePickerNavigationMode.scroll,
                              navigationDirection: DateRangePickerNavigationDirection.horizontal,
                              headerHeight: 100,
                              showNavigationArrow: true,
                              initialSelectedRange: PickerDateRange(
                                DateTime.now().subtract(const Duration(days: 4)),
                                DateTime.now().add(const Duration(days: 3)),
                              ),
                              backgroundColor: Colors.white,
                              // 設置選擇範圍的顏色
                              selectionColor: healDarkGrey,
                              // 設置起始日期的顏色
                              rangeTextStyle: const TextStyle(color: colorDark, fontSize: 24),
                              selectionTextStyle: const TextStyle(color: colorDark, fontSize: 32),
                              // 設置今天的顏色
                              todayHighlightColor: colorDark,
                              // 設置標題樣式
                              headerStyle: const DateRangePickerHeaderStyle(
                                textAlign: TextAlign.center,
                                textStyle: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: colorDark,
                                ),
                              ),
                              // 設置月份單元格樣式
                              monthCellStyle: const DateRangePickerMonthCellStyle(
                                textStyle: TextStyle(fontSize: 24, color: colorDark),
                                todayTextStyle: TextStyle(fontSize: 24, color: healDarkGrey),
                                disabledDatesTextStyle: TextStyle(color: colorDark),
                              ),
                              // 設置年份單元格樣式
                              yearCellStyle: const DateRangePickerYearCellStyle(
                                textStyle: TextStyle(fontSize: 24, color: colorDark),
                                todayTextStyle: TextStyle(fontSize: 24, color: healDarkGrey),
                                disabledDatesTextStyle: TextStyle(color: colorDark),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              height: 50,
                              color: Colors.white,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  SizedBox(
                                    width: 300,
                                    height: 50,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(200, 60),
                                        foregroundColor: healDarkGrey,
                                        backgroundColor: colorWhite80,
                                        side: const BorderSide(
                                          color: healDarkGrey,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                      child: Text(showEnglish ? 'Cancel' : '取消', style: const TextStyle(fontSize: 24, color: healDarkGrey)),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 300,
                                    height: 50,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(200, 60),
                                        foregroundColor: healDarkGrey,
                                        backgroundColor: colorWhite80,
                                        side: const BorderSide(
                                          color: healDarkGrey,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                      child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(fontSize: 24, color: healDarkGrey)),
                                      onPressed: () {
                                        fetchTransactions(selectType, selectSource, _pickStartDate, _pickEndDate);
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    showEnglish ? 'Month Records' : '月交易筆數',
                    style: const TextStyle(
                      fontSize: 20,
                      color: colorWhite80,
                    ),
                  ),
                  Text(
                    showEnglish ? ' / Amount' : ' / 金額',
                    style: const TextStyle(
                      fontSize: 20,
                      color: healDarkGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                color: colorDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$monthTransactionCount',
                    style: const TextStyle(
                      fontSize: 50,
                      color: colorWhite80,
                    ),
                  ),
                  Text(
                    ' / $monthTransactionTotal',
                    style: const TextStyle(
                      fontSize: 38,
                      color: healDarkGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget yearTransactionWidget() {
    return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 10,
            ),
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: 200,
                      width: 300,
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            flex: 9,
                            child: SfDateRangePicker(
                              controller: _datePickerController,
                              view: DateRangePickerView.decade,
                              onSelectionChanged: _onSelectionChanged,
                              selectionMode: DateRangePickerSelectionMode.range,
                              navigationMode: DateRangePickerNavigationMode.scroll,
                              navigationDirection: DateRangePickerNavigationDirection.horizontal,
                              headerHeight: 100,
                              showNavigationArrow: true,
                              initialSelectedRange: PickerDateRange(
                                DateTime.now().subtract(const Duration(days: 4)),
                                DateTime.now().add(const Duration(days: 3)),
                              ),
                              backgroundColor: Colors.white,
                              // 設置選擇範圍的顏色
                              selectionColor: healDarkGrey,
                              // 設置起始日期的顏色
                              rangeTextStyle: const TextStyle(color: colorDark, fontSize: 24),
                              selectionTextStyle: const TextStyle(color: colorDark, fontSize: 32),
                              // 設置今天的顏色
                              todayHighlightColor: colorDark,
                              // 設置標題樣式
                              headerStyle: const DateRangePickerHeaderStyle(
                                textAlign: TextAlign.center,
                                textStyle: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: colorDark,
                                ),
                              ),
                              // 設置月份單元格樣式
                              monthCellStyle: const DateRangePickerMonthCellStyle(
                                textStyle: TextStyle(fontSize: 24, color: colorDark),
                                todayTextStyle: TextStyle(fontSize: 24, color: healDarkGrey),
                                disabledDatesTextStyle: TextStyle(color: colorDark),
                              ),
                              // 設置年份單元格樣式
                              yearCellStyle: const DateRangePickerYearCellStyle(
                                textStyle: TextStyle(fontSize: 24, color: colorDark),
                                todayTextStyle: TextStyle(fontSize: 24, color: healDarkGrey),
                                disabledDatesTextStyle: TextStyle(color: colorDark),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              height: 50,
                              color: Colors.white,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  SizedBox(
                                    width: 300,
                                    height: 50,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(200, 60),
                                        foregroundColor: healDarkGrey,
                                        backgroundColor: colorWhite80,
                                        side: const BorderSide(
                                          color: healDarkGrey,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                      child: Text(showEnglish ? 'Cancel' : '取消', style: const TextStyle(fontSize: 24, color: healDarkGrey)),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 300,
                                    height: 50,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(200, 60),
                                        foregroundColor: healDarkGrey,
                                        backgroundColor: colorWhite80,
                                        side: const BorderSide(
                                          color: healDarkGrey,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                      child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(fontSize: 24, color: healDarkGrey)),
                                      onPressed: () {
                                        fetchTransactions(selectType, selectSource, _pickStartDate, _pickEndDate);
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    showEnglish ? 'Year Records' : '年交易筆數',
                    style: const TextStyle(
                      fontSize: 20,
                      color: colorWhite80,
                    ),
                  ),
                  Text(
                    showEnglish ? ' / Amount' : ' / 金額',
                    style: const TextStyle(
                      fontSize: 20,
                      color: healDarkGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                color: colorDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$yearTransactionCount',
                    style: const TextStyle(
                      fontSize: 50,
                      color: colorWhite80,
                    ),
                  ),
                  Text(
                    ' / $yearTransactionTotal',
                    style: const TextStyle(
                      fontSize: 38,
                      color: healDarkGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class TransactionPaginatedDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final bool showEnglish;

  const TransactionPaginatedDataTable({super.key, required this.transactions, required this.showEnglish});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: colorDark,
          onPrimary: colorDark,
          surface: colorDark,
          onSurface: colorWhite30,
        ),
        cardColor: colorDark,
        dividerColor: colorWhite30,
        textTheme: const TextTheme(
          bodySmall: TextStyle(color: colorWhite50, fontSize: 22), //分頁文字大小
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: colorDark,
          selectedItemColor: colorWhite80,
          unselectedItemColor: colorWhite30,
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: TextStyle(color: colorDark, fontSize: 22),
          ),
        ),
      ),
      child: PaginatedDataTable(
        // header: const Text('Transactions'),
        columns: [
          DataColumn(
            label: Text(
              showEnglish ? 'OrderID' : '訂單編號',
              textAlign: TextAlign.center,
              style: const TextStyle(color: colorWhite80, fontSize: 20),
            ),
          ),
          DataColumn(
            label: Text(
              showEnglish ? 'Name' : '品名',
              textAlign: TextAlign.center,
              style: const TextStyle(color: colorWhite80, fontSize: 20),
            ),
          ),
          DataColumn(
            label: Text(
              showEnglish ? 'Order Date' : '訂單時間',
              textAlign: TextAlign.center,
              style: const TextStyle(color: colorWhite80, fontSize: 20),
            ),
          ),
          DataColumn(
            label: Text(
              showEnglish ? 'Result' : '結果',
              textAlign: TextAlign.center,
              style: const TextStyle(color: colorWhite80, fontSize: 20),
            ),
          ),
          DataColumn(
            label: Text(
              showEnglish ? 'Price' : '價格',
              textAlign: TextAlign.center,
              style: const TextStyle(color: colorWhite80, fontSize: 20),
            ),
          ),
          DataColumn(
            label: Text(
              showEnglish ? 'Source' : '來源',
              textAlign: TextAlign.center,
              style: const TextStyle(color: colorWhite80, fontSize: 20),
            ),
          ),
        ],
        source: TransactionDataSource(transactions, showEnglish: showEnglish),
        rowsPerPage: 8,
        columnSpacing: 20,
        horizontalMargin: 10,
        showCheckboxColumn: false,
        arrowHeadColor: colorWhite80,
        dataRowMinHeight: 30,
        dataRowMaxHeight: 50,
        sortColumnIndex: 0,
        // sortAscending: sort,
        showFirstLastButtons: true,
        initialFirstRowIndex: 0,
        showEmptyRows: false,
      ),
    );
  }
}

class TransactionDataSource extends DataTableSource {
  final List<Map<String, dynamic>> transactions;
  final bool showEnglish;
  TransactionDataSource(this.transactions, {required this.showEnglish});

  @override
  DataRow getRow(int index) {
    if (transactions.isEmpty) {
      return DataRow.byIndex(index: index, cells: const [DataCell(Text('No Data'))]);
    }
    final transaction = transactions[index];
    return DataRow(cells: [
      DataCell(
        SizedBox(
            width: 150,
            child: Text(
              transaction['transactionOrderNo'].toString().isNotEmpty ? transaction['transactionOrderNo'].toString() : transaction['transactionOrderNo'].toString(),
              style: const TextStyle(color: colorWhite80, fontSize: 20),
            )),
      ),
      DataCell(
        SizedBox(width: 200, child: Text(transaction['productName'].toString(), style: const TextStyle(color: colorWhite80, fontSize: 20))),
      ),
      DataCell(
        SizedBox(width: 190, child: Text(transaction['createdDateTime'].toString().substring(0, 19), style: const TextStyle(color: colorWhite80, fontSize: 20))),
      ),
      DataCell(
        SizedBox(
            width: 80,
            child:
                transaction['isDrinkMade'] == 1 ? Text(showEnglish ? 'Success' : '已製作', style: const TextStyle(color: Colors.green, fontSize: 20)) : Text(showEnglish ? 'Failure' : '失敗', style: const TextStyle(color: Colors.redAccent, fontSize: 20))),
      ),
      DataCell(
        SizedBox(width: 70, child: transaction['price'] > 0 ? Text(transaction['price'].toString(), style: const TextStyle(color: colorWhite80, fontSize: 20)) : const Text('Free', style: TextStyle(color: colorWhite80, fontSize: 20))),
      ),
      DataCell(
        transaction['sourceId'].toString() == '1'
            ? const Icon(Icons.ads_click_outlined, color: Colors.blueAccent, size: 30)
            : transaction['sourceId'].toString() == '2'
                ? const Icon(Icons.attach_money_outlined, color: Colors.green, size: 30)
                : transaction['sourceId'].toString() == '3'
                    ? const Icon(Icons.shopping_cart_rounded, color: Colors.redAccent, size: 30)
                    : transaction['sourceId'].toString() == '4'
                        ? const Icon(Icons.qr_code_outlined, color: Colors.tealAccent, size: 30)
                        : transaction['sourceId'].toString() == '5'
                            ? const Icon(Icons.qr_code_outlined, color: Colors.tealAccent, size: 30)
                            : transaction['sourceId'].toString() == '6'
                                ? const Icon(Icons.qr_code_outlined, color: Colors.tealAccent, size: 30)
                                : transaction['sourceId'].toString() == '7'
                                    ? const Icon(Icons.qr_code_outlined, color: Colors.tealAccent, size: 30)
                                    : transaction['sourceId'].toString() == '9'
                                        ? const Icon(Icons.water_drop_outlined, color: Colors.tealAccent, size: 30)
                                        : const Icon(Icons.announcement_outlined, color: Colors.tealAccent, size: 30),
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => transactions.length;

  @override
  int get selectedRowCount => 0;
}

class MyStoreOrderListSource extends DataTableSource {
  MyStoreOrderListSource(this.data, this.showEnglish);
  final bool showEnglish;
  final List<TransactionRecord> data;

  @override
  DataRow getRow(int index) {
    if (index >= data.length) {
      return DataRow.byIndex(index: index, cells: const [DataCell(Text('No Data'))]);
    }
    return DataRow.byIndex(
      index: index,
      color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        return colorDark;
      }),
      cells: [
        DataCell(
          Center(child: Text(data[index].transactionOrderNo.toString(), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20))),
        ),
        DataCell(
          Text(data[index].createdDateTime.toString().substring(0, 19), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20)),
        ),
        DataCell(
          Center(
            child: Text(
              data[index].isDrinkMade == true
                  ? showEnglish
                      ? 'Success'
                      : '成功'
                  : showEnglish
                      ? 'Failure'
                      : '失敗',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: data[index].isDrinkMade == true ? Colors.blue : Colors.red, fontSize: 20),
            ),
          ),
        ),
        DataCell(
          Text(data[index].productName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20)),
        ),
        DataCell(
          Center(child: Text(data[index].price.toString(), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20))),
        ),
        DataCell(
          Text(data[index].salesId.toString().split('@')[0], overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20)),
        ),
      ],
    );
  }

  @override
  int get selectedRowCount {
    return 0;
  }

  @override
  bool get isRowCountApproximate {
    return false;
  }

  @override
  int get rowCount {
    return data.length;
  }
}
