// ignore_for_file: use_build_context_synchronously, implementation_imports, depend_on_referenced_packages

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/src/painting/box_border.dart' as flutter_border;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:excel/excel.dart';
import 'package:sqflite/sqflite.dart';
import 'constant.dart';
import 'database_helper.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class MyInheritedWidget extends InheritedWidget {
  final int data;

  const MyInheritedWidget({super.key, required this.data, required super.child});

  @override
  bool updateShouldNotify(MyInheritedWidget oldWidget) {
    return oldWidget.data != data;
  }

  static MyInheritedWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MyInheritedWidget>();
  }
}

class DataImport extends StatefulWidget {
  const DataImport({super.key});

  @override
  State<DataImport> createState() => _DataImportState();
}

class _DataImportState extends State<DataImport> {
  late ScaffoldMessengerState _scaffoldMessenger;
  final DatabaseHelper dbHelper = DatabaseHelper();
  late Database _database;
  String documentsPath = AllConstants().documentsPath;
  bool showEnglish = AllConstants.showEnglish;
  bool productActive = false;
  bool productRecommended = false;
  bool pipeUseActive = false;
  int userLevel = 9;
  Future<List<Map<String, dynamic>>> userData = Future.value([]);
  Future<List<Map<String, dynamic>>> productData = Future.value([]);
  Future<List<Map<String, dynamic>>> pipeUseData = Future.value([]);
  Future<List<Map<String, dynamic>>> transcationsData = Future.value([]);
  Future<List<Map<String, dynamic>>> qrcodeData = Future.value([]);

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    Future.microtask(() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          showEnglish = prefs.getBool('showEnglish') ?? true;
          userLevel = prefs.getInt('userLevel') ?? 9;
        });
      }
    });
    _loadUserStreamData();
    _loadProductStreamData();
    _loadPipeUseStreamData();
    _loadTranscationsStreamData();
    _loadQrcodeStreamData();
    if (mounted) {
      setState(() {
        productActive = false;
        pipeUseActive = false;
        productRecommended = false;
      });
    }
  }

  Future<void> _initializeDatabase() async {
    // Initialize the database here
    dbHelper.database.then((database) {
      _database = database;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    if (_scaffoldMessenger.mounted) {
      _scaffoldMessenger.hideCurrentSnackBar();
    }
    super.dispose();
  }

  Future<void> _loadUserStreamData() async {
    if (!mounted) return;
    Future<List<Map<String, dynamic>>> data = dbHelper.getAllMembers();
    setState(() {
      userData = data;
    });
  }

  Future<void> _loadProductStreamData() async {
    if (!mounted) return;
    Future<List<Map<String, dynamic>>> data = dbHelper.getAllProducts();
    setState(() {
      productData = data;
    });
  }

  Future<void> _loadPipeUseStreamData() async {
    if (!mounted) return;
    Future<List<Map<String, dynamic>>> data = dbHelper.getAllPipeUses();
    setState(() {
      pipeUseData = data;
    });
  }

  Future<void> _loadTranscationsStreamData() async {
    if (!mounted) return;
    Future<List<Map<String, dynamic>>> data = dbHelper.getAllRecords();
    setState(() {
      transcationsData = data;
    });
  }

  Future<void> _loadQrcodeStreamData() async {
    if (!mounted) return;
    Future<List<Map<String, dynamic>>> data = dbHelper.getAllQrcodes();
    setState(() {
      qrcodeData = data;
    });
  }

  String generate20CharGuid() {
    const uuid = Uuid();
    return uuid.v4().substring(0, 20);
  }

  Future<void> _readUserDataToDatabase() async {
    String userId = '';
    // 從sqlite 的資料庫 healcafe22.db 取得目前使用者 ID orderBy userId DESC
    List<Map<String, dynamic>> users = await _database.query(
      'user_login',
      orderBy: 'userId DESC',
    );
    if (users.isNotEmpty) {
      userId = users[0]['userId'];
      userId = 'S${(int.parse(userId.substring(1)) + 1).toString().padLeft(5, '0')}';
    } else {
      userId = 'S00001';
    }
    try {
      String filePath = '$documentsPath/xlsx/user_login.xlsx';
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      final usersSheet = excel['user_login'];
      for (var row in usersSheet.rows.skip(1)) {
        await _database.insert(
          'user_login',
          {
            'userEmail': row[0]?.value.toString(),
            'userName': row[1]?.value.toString(),
            'userPassWord': row[2]?.value.toString(),
            'userLevel': int.tryParse(row[3]?.value.toString() ?? '0'),
            'userId': userId,
            'createdDateTime': DateTime.now().toString(),
            'userPhone': row[4]?.value.toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        debugPrint('${row[0]?.value.toString()} Users Data Imported Successfully');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading or reading Excel file: $e')));
      debugPrint('Error downloading or reading Excel file: $e');
    }
  }

  Future<void> _readQrcodeDataToDatabase() async {
    try {
      String filePath = '$documentsPath/xlsx/qrcode_manage.xlsx';
      final bytes = File(filePath).readAsBytesSync();
      final decoder = SpreadsheetDecoder.decodeBytes(bytes);
      final sheet = decoder.tables['qrcode_manage'];

      if (sheet == null) {
        debugPrint('Sheet "qrcode_manage" not found');
        return;
      }

      for (var rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
        var row = sheet.rows[rowIndex];
        if (row.isEmpty || row[0] == null) continue; // Skip empty rows

        String qrCodeId = row[0]?.toString() ?? '';
        int qrCodeType = int.tryParse(row[1]?.toString() ?? '') ?? 4;
        String eventId = row[2]?.toString() ?? '';
        String startDateTime = _formatDateTime(row[3]);
        String endDateTime = _formatDateTime(row[4]);

        await _database.insert(
          'qrcode_manage',
          {
            'qrCodeId': qrCodeId,
            'qrCodeType': qrCodeType,
            'eventId': eventId,
            'startDateTime': startDateTime,
            'endDateTime': endDateTime,
            'isUsed': 0,
            'exchangeDateTime': DateTime.now().toString(),
            'createdDateTime': DateTime.now().toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        debugPrint('$qrCodeId Qrcode Data Imported Successfully');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reading Excel file: $e')));
      debugPrint('Error reading Excel file: $e');
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) {
      return value.toString();
    } else if (value is String) {
      try {
        return DateTime.parse(value).toString();
      } catch (_) {
        return value;
      }
    } else {
      return value.toString();
    }
  }

  Future<void> _readProductsDataToDatabase() async {
    try {
      String filePath = '$documentsPath/xlsx/products.xlsx';

      // 檢查文件是否存在
      if (!await File(filePath).exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Excel file not found'),
            backgroundColor: Colors.red,
          ));
        }
        return;
      }

      final bytes = await File(filePath).readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Excel file is empty');
      }

      // 使用 try-catch 包裝 Excel 解析
      Excel? excel;
      try {
        excel = Excel.decodeBytes(bytes);
      } catch (e) {
        throw Exception('Failed to decode Excel file: $e');
      }

      // 檢查並獲取工作表
      if (!excel.tables.containsKey('products')) {
        throw Exception('Sheet "products" not found in Excel file');
      }

      final sheet = excel.tables['products'];
      if (sheet == null) {
        throw Exception('Sheet "products" is null');
      }

      // 讀取並處理數據
      for (var row in sheet.rows.skip(1)) {
        if (row.isEmpty || row.length < 7) {
          continue;
        }

        try {
          if (mounted) {
            await _database.insert(
              'products',
              {
                'docId': generate20CharGuid(),
                'productName': row[0]?.value?.toString() ?? '',
                'alcohol': row[1]?.value?.toString() ?? '',
                'price': int.tryParse(row[2]?.value?.toString() ?? '0') ?? 0,
                'imgPath': row[3]?.value?.toString() ?? '',
                'placeOrder': int.tryParse(row[4]?.value?.toString() ?? '0') ?? 0,
                'recommended': (row[5]?.value?.toString().toLowerCase() == 'true') ? 1 : 0,
                'active': (row[6]?.value?.toString().toLowerCase() == 'true') ? 1 : 0,
                'createdDateTime': DateTime.now().toString(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        } catch (e) {
          debugPrint('Error inserting row: $e');
          continue;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Products data imported successfully'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      debugPrint('Error processing Excel file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _readPipeUseDataToDatabase() async {
    try {
      String filePath = '$documentsPath/xlsx/pipe_use_manage.xlsx';
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      final pipeUseSheet = excel['pipe_use_manage'];
      for (var row in pipeUseSheet.rows.skip(1)) {
        await _database.insert(
          'pipe_use_manage',
          {
            'name': row[0]?.value.toString(),
            'pipeSettingString': row[1]?.value.toString(),
            'active': 0, // 使用 0 代替 false
            'createdDateTime': DateTime.now().toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        debugPrint('${row[0]?.value.toString()} Pipe Use Data Imported Successfully');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading or reading Excel file: $e')));
      }
      debugPrint('Error downloading or reading Excel file: $e');
    }
  }

  Future<void> _readTranscationDataToDatabase() async {
    try {
      String filePath = '$documentsPath/xlsx/all_transcation_records.xlsx';
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      final transcationSheet = excel['all_transcation_records'];
      for (var row in transcationSheet.rows.skip(1)) {
        await _database.insert(
          'all_transcation_records',
          {
            'transactionOrderNo': row[0]?.value.toString(),
            'productName': row[1]?.value.toString(),
            'price': int.tryParse(row[2]?.value.toString() ?? '0'),
            'formulaString': row[3]?.value.toString(),
            'imgPath': row[4]?.value.toString(),
            'isDrinkMade': row[5]?.value.toString() == 'true' ? 1 : 0,
            'salesId': row[6]?.value.toString(),
            'sourceId': row[7]?.value.toString(),
            'createdDateTime': row[8]?.value.toString(),
            'remark': row[9]?.value.toString(),
            'qrCodeId': row[10]?.value.toString(),
            'correctWeight1': int.tryParse(row[11]?.value.toString() ?? '0'),
            'correctWeight2': int.tryParse(row[12]?.value.toString() ?? '0'),
            'correctWeight3': int.tryParse(row[13]?.value.toString() ?? '0'),
            'correctWeight4': int.tryParse(row[14]?.value.toString() ?? '0'),
            'correctWeight5': int.tryParse(row[15]?.value.toString() ?? '0'),
            'correctWeight6': int.tryParse(row[16]?.value.toString() ?? '0'),
            'correctWeight7': int.tryParse(row[17]?.value.toString() ?? '0'),
            'correctWeight8': int.tryParse(row[18]?.value.toString() ?? '0'),
            'correctWeight9': int.tryParse(row[19]?.value.toString() ?? '0'),
            'correctWeight10': int.tryParse(row[20]?.value.toString() ?? '0'),
            'correctWeight11': int.tryParse(row[21]?.value.toString() ?? '0'),
            'correctWeight12': int.tryParse(row[22]?.value.toString() ?? '0'),
            'correctWeight13': int.tryParse(row[23]?.value.toString() ?? '0'),
            'correctWeight14': int.tryParse(row[24]?.value.toString() ?? '0'),
            'correctWeight16': int.tryParse(row[25]?.value.toString() ?? '0'),
            'g1': int.tryParse(row[26]?.value.toString() ?? '0'),
            'g2': int.tryParse(row[27]?.value.toString() ?? '0'),
            'g3': int.tryParse(row[28]?.value.toString() ?? '0'),
            'g4': int.tryParse(row[29]?.value.toString() ?? '0'),
            'g5': int.tryParse(row[30]?.value.toString() ?? '0'),
            'g6': int.tryParse(row[31]?.value.toString() ?? '0'),
            'g7': int.tryParse(row[32]?.value.toString() ?? '0'),
            'g8': int.tryParse(row[33]?.value.toString() ?? '0'),
            'g9': int.tryParse(row[34]?.value.toString() ?? '0'),
            'g10': int.tryParse(row[35]?.value.toString() ?? '0'),
            'g11': int.tryParse(row[36]?.value.toString() ?? '0'),
            'g12': int.tryParse(row[37]?.value.toString() ?? '0'),
            'g13': int.tryParse(row[38]?.value.toString() ?? '0'),
            'g14': int.tryParse(row[39]?.value.toString() ?? '0'),
            'g16': int.tryParse(row[40]?.value.toString() ?? '0'),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading or reading Excel file: $e')));
      debugPrint('Error downloading or reading Excel file: $e');
    }
  }

  CellValue? _convertToCellValue(value) {
    if (value == null) {
      return TextCellValue('');
    } else if (value is int) {
      return IntCellValue(value);
    } else if (value is double) {
      return DoubleCellValue(value);
      // } else if (value is DateTime) {
      //   return DateTimeCellValue(value);
    } else if (value is bool) {
      return BoolCellValue(value);
    } else {
      return TextCellValue(value.toString());
    }
  }

  Future<void> checkAndExportDatabase() async {
    var databasesPath = await getDatabasesPath();
    String path = p.join(databasesPath, 'healcafe22.db');

    try {
      // 打開數據庫
      Database db = await openDatabase(path);

      // 獲取所有表名
      List<Map> tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint('Tables in the database: ${tables.map((t) => t['name']).toList()}');

      String timestamp = DateTime.now().toIso8601String().substring(0, 19).replaceAll('-', '_').replaceAll(':', '_').replaceAll('T', '_');

      // 遍歷每個表
      for (var table in tables) {
        String tableName = table['name'] as String;
        if (tableName != 'android_metadata' && tableName != 'sqlite_sequence') {
          // 創建一個新的 Excel 文件
          var excel = Excel.createExcel();
          excel.rename('Sheet1', tableName);
          var sheet = excel[tableName];
          // 獲取表的所有數據
          List<Map> tableData = await db.query(tableName);

          // 如果表不為空
          if (tableData.isNotEmpty) {
            // 添加列標題
            var headers = tableData.first.keys.toList();
            for (var i = 0; i < headers.length; i++) {
              sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
            }

            // 添加數據
            for (var rowIndex = 0; rowIndex < tableData.length; rowIndex++) {
              var row = tableData[rowIndex];
              for (var colIndex = 0; colIndex < headers.length; colIndex++) {
                var cellValue = row[headers[colIndex]];
                sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 1)).value = _convertToCellValue(cellValue);
              }
            }

            String excelPath = p.join('$documentsPath/db/', '${tableName}_$timestamp.xlsx');
            // 保存 Excel 文件
            var fileBytes = excel.save();
            File(excelPath)
              ..createSync(recursive: true)
              ..writeAsBytesSync(fileBytes!);

            debugPrint('Excel file saved to: $excelPath');
          }
        }
      }

      // 關閉數據庫
      db.close().then((value) async {
        debugPrint('Database closed');
        // 導出數據庫文件
        await exportDatabaseFile(path);
      });

      // 重新啟動數據庫
      await DatabaseHelper().database;
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error exporting database to Excel: $e');
    }
  }

  Future<void> exportDatabaseFile(String sourcePath) async {
    // 確保外部存儲權限
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    // 獲取外部存儲目錄
    String timestamp = DateTime.now().toIso8601String().substring(0, 19).replaceAll('-', '_').replaceAll(':', '_').replaceAll('T', '_');

    String newPath = p.join('$documentsPath/db/', 'healcafe_$timestamp.db');

    try {
      File sourceFile = File(sourcePath);
      await sourceFile.copy(newPath);
      debugPrint('Database exported to: $newPath');
      debugPrint('Exported file size: ${await File(newPath).length()} bytes');
    } catch (e) {
      debugPrint('Error exporting database: $e');
    }
    // Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: healDarkGrey,
        centerTitle: true,
        title: Text(showEnglish ? 'Data Manage And Import' : '資料管理與導入', style: const TextStyle(color: colorWhite80, fontSize: 28, fontWeight: FontWeight.bold)),
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
      body: StatefulBuilder(
        builder: (BuildContext context, setState) {
          return Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            color: colorWhite80,
            child: Padding(
              padding: const EdgeInsets.all(80.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    showEnglish ? 'Please make sure all files are placed in Documents/healcafe22/xlsx/' : '請確定所有導入檔案都是正確的放置在 Documents 目錄中的 healcafe22/xlsx/ 文件夾中',
                    style: const TextStyle(color: healLightGrey, fontSize: 24),
                  ),
                  const SizedBox(height: 50),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: flutter_border.Border.all(color: healDarkGrey, width: 1),
                              ),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(200, 50),
                                  foregroundColor: colorDark,
                                  backgroundColor: colorWhite80,
                                  side: const BorderSide(
                                    color: healDarkGrey,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      child: showUsersDataManage(),
                                    ),
                                  );
                                },
                                child: Text(showEnglish ? 'User Data \nManage' : '登入者資料管理', style: const TextStyle(color: healDarkGrey, fontSize: 22)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                          Expanded(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: flutter_border.Border.all(color: healDarkGrey, width: 1),
                              ),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(200, 50),
                                  foregroundColor: colorDark,
                                  backgroundColor: colorWhite80,
                                  side: const BorderSide(
                                    color: healDarkGrey,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      child: showProductsDataManage(),
                                    ),
                                  );
                                },
                                child: Text(showEnglish ? 'Product Data \nManage' : '酒單資料管理', style: const TextStyle(color: healDarkGrey, fontSize: 22)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                          Expanded(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: flutter_border.Border.all(color: healDarkGrey, width: 1),
                                color: colorWhite80,
                              ),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(200, 50),
                                  foregroundColor: colorDark,
                                  backgroundColor: colorWhite80,
                                  side: const BorderSide(
                                    color: healDarkGrey,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      child: showPipeUseDataManage(),
                                    ),
                                  );
                                },
                                child: Text(showEnglish ? 'Pipe Setting \nManage' : '管線設定管理', style: const TextStyle(color: healDarkGrey, fontSize: 22)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                          Expanded(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: flutter_border.Border.all(color: healDarkGrey, width: 1),
                              ),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(200, 50),
                                  foregroundColor: colorDark,
                                  backgroundColor: colorWhite80,
                                  side: const BorderSide(
                                    color: healDarkGrey,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      child: showTranscationDataManage(),
                                    ),
                                  );
                                },
                                child: Text(showEnglish ? 'Transaction \nRecord Manage' : '交易紀錄管理', style: const TextStyle(color: healDarkGrey, fontSize: 22)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: flutter_border.Border.all(color: healDarkGrey, width: 1),
                              ),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(200, 50),
                                  foregroundColor: colorDark,
                                  backgroundColor: colorWhite80,
                                  side: const BorderSide(
                                    color: healDarkGrey,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      child: showQrcodeDataManage(),
                                    ),
                                  );
                                },
                                child: Text(showEnglish ? 'Qrcode \nData Manage' : 'Qrcode資料管理', style: const TextStyle(color: healDarkGrey, fontSize: 22)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                          Expanded(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: flutter_border.Border.all(color: healDarkGrey, width: 1),
                              ),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(200, 50),
                                  foregroundColor: colorDark,
                                  backgroundColor: colorWhite80,
                                  side: const BorderSide(
                                    color: healDarkGrey,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      child: Container(
                                        width: 400,
                                        height: 300,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5),
                                          border: flutter_border.Border.all(color: healDarkGrey, width: 1),
                                          color: healDarkGrey,
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(showEnglish ? 'Database Back Up' : '資料庫備份', style: const TextStyle(color: colorWhite80, fontSize: 30)),
                                              const SizedBox(height: 20),
                                              const Icon(Icons.cloud_download_outlined, size: 100, color: colorWhite80),
                                              const SizedBox(height: 20),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  minimumSize: const Size(200, 50),
                                                  foregroundColor: colorDark,
                                                  backgroundColor: colorWhite80,
                                                  side: const BorderSide(
                                                    color: healDarkGrey,
                                                    width: 2,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  checkAndExportDatabase();
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Container(
                                                        height: 80.0, // 設置高度
                                                        alignment: Alignment.center,
                                                        // color: healDarkGrey,
                                                        child: Text(
                                                          showEnglish ? 'DataBase File is Exported!' : '資料庫檔案已匯出!',
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
                                                },
                                                child: Text(showEnglish ? 'Export All Tables' : '匯出所有資料表', style: const TextStyle(color: healDarkGrey, fontSize: 22)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(showEnglish ? 'Export\nDatabase File' : '匯出資料庫檔案', style: const TextStyle(color: healDarkGrey, fontSize: 22)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                          Expanded(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: flutter_border.Border.all(color: healDarkGrey, width: 1),
                              ),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(200, 50),
                                  foregroundColor: colorDark,
                                  backgroundColor: colorWhite80,
                                  side: const BorderSide(
                                    color: healDarkGrey,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      child: Container(),
                                    ),
                                  );
                                },
                                child: Text(showEnglish ? '....' : '....', style: const TextStyle(color: healDarkGrey, fontSize: 22)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                          Expanded(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: flutter_border.Border.all(color: healDarkGrey, width: 1),
                              ),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(200, 50),
                                  foregroundColor: colorDark,
                                  backgroundColor: colorWhite80,
                                  side: const BorderSide(
                                    color: healDarkGrey,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      child: Container(),
                                    ),
                                  );
                                },
                                child: Text(showEnglish ? '....' : '....', style: const TextStyle(color: healDarkGrey, fontSize: 22)),
                              ),
                            ),
                          ),
                          // 使用者資料管理
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget showUsersDataManage() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(200, 50),
              foregroundColor: colorWhite80,
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
              // 先做confirm 檢查 AlertDialog
              await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    backgroundColor: healDarkGrey,
                    content: Text(showEnglish ? 'Are you sure to import the user Excel?' : '確定導入使用者 Excel?', style: const TextStyle(color: colorWhite80, fontSize: 28)),
                    actions: <Widget>[
                      TextButton(
                        child: Text(showEnglish ? 'Cancel' : '取消', style: const TextStyle(color: Colors.red, fontSize: 26)),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(color: colorWhite80, fontSize: 26)),
                        onPressed: () async {
                          // 檢查檔案是否存在
                          String filePath = '$documentsPath/xlsx/user_login.xlsx';
                          if (!File(filePath).existsSync()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'File does not exist, please place it in Documents/healcafe22/xlsx/' : '檔案不存在, 請先放置檔案再重試',
                                    style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                              ),
                            );
                            return;
                          }
                          _readUserDataToDatabase().then((value) {
                            _loadUserStreamData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'Users Data Imported Successfully' : '使用者資料導入成功',
                                    style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          }).catchError((e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    e.toString(),
                                    style: const TextStyle(fontSize: 18.0, color: colorWhite80),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          });
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Text(showEnglish ? 'Import File from Excel' : '使用EXCEL導入', style: const TextStyle(color: colorWhite80, fontSize: 22)),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          flex: 9,
          child: Container(
            width: double.infinity,
            height: 600,
            decoration: const BoxDecoration(
              color: healDarkGrey,
            ),
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: userData,
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text(showEnglish ? 'No Member found' : '尚未建立使用者資料', style: const TextStyle(color: colorWhite80, fontSize: 24)));
                    } else {
                      return DataTable(
                        columns: [
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Name' : '姓名',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Email' : '電郵',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Password' : '密碼',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Level' : '等級',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'User Id' : '使用者ID',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Created Date' : '建立日期',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: IconButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return addMember();
                                      });
                                },
                                icon: const Icon(Icons.add_circle_outline, color: colorWhite80, size: 40)),
                          ),
                        ],
                        rows: snapshot.data!.map((member) {
                          return DataRow(cells: [
                            DataCell(Text(
                              member['userName'],
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(
                              Text(
                                member['userEmail'],
                                style: const TextStyle(color: colorWhite80, fontSize: 18),
                              ),
                            ),
                            DataCell(Text(
                              member['userPassWord'],
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(Text(
                              member['userLevel'].toString(),
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(Text(
                              member['userId'].toString(),
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(Text(
                              member['createdDateTime'] == null ? '' : member['createdDateTime'].toString().substring(0, 19),
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: colorWhite80),
                                    onPressed: () {
                                      showDialog(context: context, builder: (BuildContext context) => editMember(member));
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: colorWhite80),
                                    onPressed: () {
                                      showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(10.0)), // 可選：設置圓角
                                            ),
                                            backgroundColor: healDarkGrey,
                                            title: Text(showEnglish ? 'Delete Member' : '刪除使用者', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                            content: Text(showEnglish ? 'Are you sure? ' : '確定刪除嗎?', style: const TextStyle(color: Colors.red, fontSize: 26)),
                                            actions: <Widget>[
                                              TextButton(
                                                child: Text(showEnglish ? 'Cancel' : '取消', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                                onPressed: () => Navigator.pop(context, false),
                                              ),
                                              TextButton(
                                                child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                                onPressed: () => {
                                                  DatabaseHelper().deleteMember(member['userId']).then((value) {
                                                    _loadUserStreamData();
                                                  }),
                                                  Navigator.pop(context, true),
                                                  Navigator.pop(context, true),
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ).then((value) {
                                        if (value != null && value) {
                                          _loadUserStreamData(); // 重新加載產品數據
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget addMember() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    int level = 9;
    return Dialog(
      child: Container(
        color: healDarkGrey,
        width: 450,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(showEnglish ? 'Add Member' : '新增使用者', style: const TextStyle(color: colorWhite80, fontSize: 28)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: showEnglish ? 'Input the Email' : '請輸入Email',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        hintText: showEnglish ? 'Input the password' : '請設定密碼',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: showEnglish ? 'Input Your Name' : '請輸入姓名',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        hintText: showEnglish ? 'Input the Phone' : '請輸入電話',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorWhite80,
                            width: 1,
                          ),
                        ),
                      ),
                      dropdownColor: colorWhite80,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: colorWhite80,
                      ),
                      iconSize: 28,
                      style: const TextStyle(
                        color: colorWhite80,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                      value: level,
                      items: const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text('admin', style: TextStyle(color: colorWhite80, fontSize: 22)),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('owner', style: TextStyle(color: colorWhite80, fontSize: 22)),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('manager', style: TextStyle(color: colorWhite80, fontSize: 22)),
                        ),
                        DropdownMenuItem(
                          value: 9,
                          child: Text('operator', style: TextStyle(color: colorWhite80, fontSize: 22)),
                        ),
                      ],
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {
                            level = value!;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 60,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(200, 60),
                        foregroundColor: colorWhite80,
                        backgroundColor: colorWhite80,
                        side: const BorderSide(
                          color: healDarkGrey,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () async {
                        if (emailController.text.isEmpty || passwordController.text.isEmpty || nameController.text.isEmpty) {
                          //取出 最近的 userId 如 U00001 然後 + 1 使其為 U00002
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Container(
                                height: 80.0, // 設置高度
                                alignment: Alignment.center,
                                // color: healDarkGrey,
                                child: Text(
                                  showEnglish ? 'Please input the empty field' : '所有空欄位都必須輸入',
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
                        } else {
                          String userId = await DatabaseHelper().getLatestUserId();
                          if (userId.isEmpty) {
                            userId = 'S00001';
                          } else {
                            userId = 'S${(int.parse(userId.substring(1)) + 1).toString().padLeft(5, '0')}';
                          }

                          final Map<String, dynamic> user = {
                            'userEmail': emailController.text,
                            'userName': nameController.text,
                            'userPassWord': passwordController.text,
                            'userLevel': level,
                            'userId': userId,
                            'createdDateTime': DateTime.now().toString(),
                            'userPhone': phoneController.text,
                          };
                          await DatabaseHelper().insertUser(user).then((value) {
                            _loadUserStreamData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'User Added Successfully' : '使用者新增成功',
                                    style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                                backgroundColor: colorWhite80,
                              ),
                            );
                          });
                          Navigator.pop(context, true);
                          Navigator.pop(context, true);
                        }
                      },
                      child: Text(
                        showEnglish ? 'Add User' : '新增使用者',
                        style: const TextStyle(fontSize: 26, color: healDarkGrey),
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

  Widget editMember(Map<String, dynamic> member) {
    int level = member['userLevel'] ?? 9;
    TextEditingController nameEditController = TextEditingController(text: member['userName']);
    TextEditingController passwordEditController = TextEditingController(text: member['userPassWord']);
    TextEditingController phoneEditController = TextEditingController(text: member['userPhone']);

    return Dialog(
      child: Container(
        color: healDarkGrey,
        width: 450,
        height: 550,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(showEnglish ? 'Edit User' : '編輯使用者', style: const TextStyle(color: colorWhite80, fontSize: 30), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  height: 80,
                  child: TextField(
                    controller: nameEditController,
                    decoration: InputDecoration(
                      labelText: showEnglish ? 'Input the Name' : '輸入名稱',
                      labelStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                    ),
                    style: const TextStyle(color: colorWhite80, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  height: 80,
                  child: TextField(
                    controller: passwordEditController,
                    decoration: InputDecoration(
                      labelText: showEnglish ? 'Input the Password' : '輸入密碼',
                      labelStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                    ),
                    style: const TextStyle(color: colorWhite80, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  height: 80,
                  child: TextField(
                    controller: phoneEditController,
                    decoration: InputDecoration(
                      labelText: showEnglish ? 'Input the Phone' : '輸入電話',
                      labelStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                    ),
                    style: const TextStyle(color: colorWhite80, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  // 使用 radio 組件 來呈現選項 1,2,3,9 的選擇
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: colorWhite80,
                          width: 1,
                        ),
                      ),
                    ),
                    dropdownColor: colorDarkGrey,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: colorWhite80,
                    ),
                    iconSize: 28,
                    style: const TextStyle(
                      color: colorWhite80,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                    value: level,
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text('admin', style: TextStyle(color: colorWhite80, fontSize: 22)),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('owner', style: TextStyle(color: colorWhite80, fontSize: 22)),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text('manager', style: TextStyle(color: colorWhite80, fontSize: 22)),
                      ),
                      DropdownMenuItem(
                        value: 9,
                        child: Text('operator', style: TextStyle(color: colorWhite80, fontSize: 22)),
                      ),
                    ],
                    onChanged: (int? value) {
                      if (mounted) {
                        setState(() {
                          level = value!;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  height: 60,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(200, 60),
                      foregroundColor: colorWhite80,
                      backgroundColor: colorDark,
                      side: const BorderSide(
                        color: healDarkGrey,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () {
                      try {
                        DatabaseHelper().updateMember({
                          'userId': member['userId'],
                          'userName': nameEditController.text,
                          'userPassword': passwordEditController.text,
                          'userPhone': phoneEditController.text,
                          'userLevel': level,
                        }).then((value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Container(
                                height: 80.0, // 設置高度
                                alignment: Alignment.center,
                                // color: healDarkGrey,
                                child: Text(
                                  showEnglish ? 'User Edited Successfully' : '成員編輯成功',
                                  style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                ),
                              ),
                              behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                              ),
                              backgroundColor: colorWhite80,
                            ),
                          );
                          _loadUserStreamData();
                          debugPrint('level: $level');
                          Navigator.pop(context);
                          Navigator.pop(context);
                        });
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                    child: Text(
                      showEnglish ? 'Edit And Save' : '編輯並儲存',
                      style: const TextStyle(fontSize: 24),
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

  Widget showProductsDataManage() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(200, 50),
              foregroundColor: colorWhite80,
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
              await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    backgroundColor: healDarkGrey,
                    content: Text(showEnglish ? 'Are you sure to import the product data Excel file?' : '確定導入商品資料 Excel?', style: const TextStyle(color: colorWhite80, fontSize: 28)),
                    actions: <Widget>[
                      TextButton(
                        child: Text(showEnglish ? 'Cancel' : '取消', style: const TextStyle(color: Colors.red, fontSize: 26)),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(color: colorWhite80, fontSize: 26)),
                        onPressed: () async {
                          // 檢查檔案是否存在
                          String filePath = '$documentsPath/xlsx/products.xlsx';
                          if (!File(filePath).existsSync()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'File does not exist, please place it in Documents/healcafe22/xlsx/' : '檔案不存在, 請先放置檔案再重試',
                                    style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                              ),
                            );
                            return;
                          }
                          _readProductsDataToDatabase().then((value) {
                            _loadProductStreamData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'Products Data Imported Successfully' : '商品資料導入成功',
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
                          }).catchError((e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    e.toString(),
                                    style: const TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          });
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Text(showEnglish ? 'Import File from Excel' : '使用EXCEL導入', style: const TextStyle(color: colorWhite80, fontSize: 22)),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          flex: 9,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 600,
            decoration: const BoxDecoration(
              color: healDarkGrey,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Center(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: productData,
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text(showEnglish ? 'No Products Found' : '尚未建立商品飲品資料', style: const TextStyle(color: colorWhite80, fontSize: 24)));
                    } else {
                      return DataTable(
                        columns: [
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Order' : '順序',
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Product Name' : '商品名稱',
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Formula' : '配方設定',
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Active' : '狀態',
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                IconButton(
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return addProduct();
                                          });
                                    },
                                    icon: const Icon(Icons.add_circle_outline, color: colorWhite80, size: 40)),
                                Visibility(
                                  visible: userLevel == 1,
                                  child: IconButton(
                                      onPressed: () {
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                  backgroundColor: healDarkGrey,
                                                  content: Text(
                                                    showEnglish ? 'Are you sure to delete all products?' : '確定將所有商品資料刪除?',
                                                    style: const TextStyle(color: colorWhite80, fontSize: 24),
                                                  ),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child: Text(showEnglish ? 'Cancel' : '取消', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                                      onPressed: () => Navigator.pop(context, false),
                                                    ),
                                                    TextButton(
                                                      child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                                      onPressed: () => {
                                                        DatabaseHelper().deleteProductAll().then((value) {
                                                          if (value) {
                                                            _loadProductStreamData();
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                backgroundColor: healDarkGrey,
                                                                content: Text(showEnglish ? 'Delete Success' : '刪除成功', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                                              ),
                                                            );
                                                          }
                                                        }),
                                                        Navigator.pop(context, true),
                                                        Navigator.pop(context, true),
                                                      },
                                                    ),
                                                  ]);
                                            });
                                      },
                                      icon: const Icon(Icons.delete_outline, color: colorWhite80, size: 40)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        rows: snapshot.data!.map((product) {
                          return DataRow(cells: [
                            DataCell(Text(
                              product['placeOrder'].toString(),
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(Text(
                              product['productName'],
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(SizedBox(
                              width: 550,
                              child: Text(
                                product['alcohol'].toString(),
                                style: const TextStyle(color: colorWhite80, fontSize: 18),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                            DataCell(
                              Text(
                                product['active'].toString(),
                                style: const TextStyle(color: colorWhite80, fontSize: 18),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: colorWhite80),
                                    onPressed: () {
                                      showDialog(context: context, builder: (BuildContext context) => editProducts(product));
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: colorWhite80),
                                    onPressed: () {
                                      showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(10.0)), // 可選：設置圓角
                                            ),
                                            backgroundColor: healDarkGrey,
                                            title: Text(showEnglish ? 'Delete Product' : '刪除商品', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                            content: Text(showEnglish ? 'Are you sure? ' : '確定刪除嗎?', style: const TextStyle(color: Colors.red, fontSize: 26)),
                                            actions: <Widget>[
                                              TextButton(
                                                child: Text(showEnglish ? 'Cancel' : '取消', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                                onPressed: () => Navigator.pop(context, false),
                                              ),
                                              TextButton(
                                                child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                                onPressed: () => {
                                                  DatabaseHelper().deleteProduct(product['docId']).then((value) {
                                                    if (value) {
                                                      _loadProductStreamData();
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          backgroundColor: healDarkGrey,
                                                          content: Text(showEnglish ? 'Delete Success' : '刪除成功', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                                        ),
                                                      );
                                                    }
                                                  }),
                                                  Navigator.pop(context, true),
                                                  Navigator.pop(context, true),
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ).then((value) {
                                        if (value != null && value) {
                                          _loadProductStreamData();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget addProduct() {
    final TextEditingController productNameController = TextEditingController();
    final TextEditingController alcohol1Controller = TextEditingController();
    final TextEditingController alcohol2Controller = TextEditingController();
    final TextEditingController alcohol3Controller = TextEditingController();
    final TextEditingController alcohol4Controller = TextEditingController();
    final TextEditingController imgPathController = TextEditingController();
    final TextEditingController placeOrderController = TextEditingController();
    return Dialog(
      child: Container(
        color: healDarkGrey,
        width: 650,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(showEnglish ? 'Add Product' : '新增商品', style: const TextStyle(color: colorWhite80, fontSize: 28)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 600,
                    height: 80,
                    child: TextField(
                      controller: placeOrderController,
                      decoration: InputDecoration(
                        label: Text(showEnglish ? 'Ex. 1' : '位置順序', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                        hintText: showEnglish ? 'Input the Order Displayed in the Menu List' : '請輸入位置順序',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 600,
                    height: 80,
                    child: TextField(
                      controller: productNameController,
                      decoration: InputDecoration(
                        label: Text(showEnglish ? 'Spaces Between Product Name, Use Underline Instead, Ex.: La_Sierra' : '請輸入品名，使用下劃線代替，如La_Sierra', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                        hintText: showEnglish ? 'Input the Product Name' : '請輸入品名',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 600,
                    height: 80,
                    child: TextField(
                      controller: alcohol1Controller,
                      decoration: InputDecoration(
                        label: Text(showEnglish ? 'Ex. HOT_12OZ@g1=360 ,("@" is Necessary for Separate, "g1" Means the Pipe Number 1)' : '如HOT_12OZ@g1=360', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                        hintText: showEnglish ? 'Input the Formula String for HOT 12OZ' : '請輸入配方1公式',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 600,
                    height: 80,
                    child: TextField(
                      controller: alcohol2Controller,
                      decoration: InputDecoration(
                        label: Text(showEnglish ? 'Ex. HOT_8OZ@g1=300 ,("@" is Necessary for Separate, "g1" Means the Pipe Number 1)' : '如HOT_8OZ@g1=300', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                        hintText: showEnglish ? 'Input the Formula String for HOT 8OZ' : '請輸入配方2公式',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 600,
                    height: 80,
                    child: TextField(
                      controller: alcohol3Controller,
                      decoration: InputDecoration(
                        label: Text(showEnglish ? 'Ex. ICED_12OZ@g2=360 ,("@" is Necessary for Separate, "g2" Means the Pipe Number 2)' : '如ICED_12OZ@g2=360', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                        hintText: showEnglish ? 'Input the Formula String for ICED 12OZ' : '請輸入配方3公式',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 600,
                    height: 80,
                    child: TextField(
                      controller: alcohol4Controller,
                      decoration: InputDecoration(
                        label: Text(showEnglish ? 'Ex. ICED_8OZ@g2=300 ,("@" is Necessary for Separate, "g2" Means the Pipe Number 2)' : '如ICED_8OZ@g2=300', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                        hintText: showEnglish ? 'Input the Formula String for ICED 8OZ' : '請輸入配方4公式',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 600,
                    height: 80,
                    child: TextField(
                      controller: imgPathController,
                      decoration: InputDecoration(
                        label: Text(showEnglish ? 'Picture Name Same as Product Name(with Extension .png), Ex.: La_Sierra.png' : '輸入商品圖片名稱，如La_Sierra.png,', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                        hintText: showEnglish ? 'Input the Picture Name with Extension(Ex.: La_Sierra.png)' : '請輸入圖片名稱及副檔名',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 600,
                    height: 60,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(200, 60),
                        foregroundColor: colorWhite80,
                        backgroundColor: colorWhite80,
                        side: const BorderSide(
                          color: healDarkGrey,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () async {
                        if (productNameController.text.isEmpty || imgPathController.text.isEmpty || alcohol1Controller.text.isEmpty || alcohol3Controller.text.isEmpty || alcohol4Controller.text.isEmpty) {
                          //取出 最近的 userId 如 U00001 然後 + 1 使其為 U00002
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Container(
                                height: 80.0, // 設置高度
                                alignment: Alignment.center,
                                // color: healDarkGrey,
                                child: Text(
                                  showEnglish ? 'product name, image and formula1 fields are required' : '商品名 圖檔名與配方1的欄位都必須輸入',
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
                          if ((alcohol1Controller.text.isNotEmpty && !alcohol1Controller.text.contains('@g')) ||
                              (alcohol2Controller.text.isNotEmpty && !alcohol2Controller.text.contains('@g')) ||
                              (alcohol3Controller.text.isNotEmpty && !alcohol3Controller.text.contains('@g')) ||
                              (alcohol4Controller.text.isNotEmpty && !alcohol4Controller.text.contains('@g'))) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? '@g is required in all formula fields' : '配方欄位都必須包含 @g ',
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
                            return;
                          }
                          return;
                        } else {
                          // docId 從generate20CharGuid() 產生
                          String docId = generate20CharGuid();
                          String alcoholText = '';
                          if (alcohol1Controller.text != '' && alcohol2Controller.text == '' && alcohol3Controller.text == '' && alcohol4Controller.text == '') {
                            alcoholText = '["${alcohol1Controller.text}"]';
                          }
                          if (alcohol1Controller.text != '' && alcohol2Controller.text != '' && alcohol3Controller.text == '' && alcohol4Controller.text == '') {
                            alcoholText = '["${alcohol1Controller.text}","${alcohol2Controller.text}"]';
                          }
                          if (alcohol1Controller.text != '' && alcohol2Controller.text != '' && alcohol3Controller.text != '' && alcohol4Controller.text == '') {
                            alcoholText = '["${alcohol1Controller.text}","${alcohol2Controller.text}","${alcohol3Controller.text}"]';
                          }
                          if (alcohol1Controller.text != '' && alcohol2Controller.text != '' && alcohol3Controller.text != '' && alcohol4Controller.text != '') {
                            alcoholText = '["${alcohol1Controller.text}","${alcohol2Controller.text}","${alcohol3Controller.text}","${alcohol4Controller.text}"]';
                          }
                          final Map<String, dynamic> product = {
                            'docId': docId,
                            'productName': productNameController.text,
                            'price': 0,
                            'imgPath': imgPathController.text,
                            'alcohol': alcoholText,
                            'placeOrder': placeOrderController.text,
                            'recommended': false,
                            'active': true,
                            'createdDateTime': DateTime.now().toString(),
                          };
                          await DatabaseHelper().insertProduct(product).then((value) {
                            _loadProductStreamData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'Product Added Successfully' : '商品新增成功',
                                    style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                                backgroundColor: colorWhite80,
                              ),
                            );
                          }).catchError((e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  child: Text(
                                    e.toString(),
                                    style: const TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          });
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        showEnglish ? 'Add Product' : '新增商品',
                        style: const TextStyle(fontSize: 26, color: healDarkGrey),
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

  Widget editProducts(Map<String, dynamic> product) {
    List<String> wineAlcohol = product['alcohol'].replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',');
    String alcohol1 = wineAlcohol.isNotEmpty ? wineAlcohol[0] : '';
    String alcohol2 = wineAlcohol.length >= 2 ? wineAlcohol[1] : '';
    String alcohol3 = wineAlcohol.length >= 3 ? wineAlcohol[2] : '';
    String alcohol4 = wineAlcohol.length >= 4 ? wineAlcohol[3] : '';
    int recommended = int.parse(product['recommended'].toString());
    int active = int.parse(product['active'].toString());

    TextEditingController productDocIdEditController = TextEditingController(text: product['docId']);
    TextEditingController productNameEditController = TextEditingController(text: product['productName']);
    TextEditingController imgPathEditController = TextEditingController(text: product['imgPath']);
    TextEditingController alcohol1EditController = TextEditingController(text: alcohol1);
    TextEditingController alcohol2EditController = TextEditingController(text: alcohol2);
    TextEditingController alcohol3EditController = TextEditingController(text: alcohol3);
    TextEditingController alcohol4EditController = TextEditingController(text: alcohol4);
    TextEditingController placeOrderEditController = TextEditingController(text: product['placeOrder'].toString());

    return Dialog(
      child: Container(
        color: healDarkGrey,
        width: 750,
        height: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(showEnglish ? 'Edit Product' : '編輯商品', style: const TextStyle(color: colorWhite80, fontSize: 30), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                SizedBox(
                  width: 650,
                  height: 60,
                  child: TextField(
                    controller: productDocIdEditController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: showEnglish ? 'Product ID ,(Cannot Modify)' : '商品ID ,(無法修改)',
                      labelStyle: const TextStyle(color: colorWhite50, fontSize: 16),
                    ),
                    style: const TextStyle(fontSize: 24, color: colorWhite80),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 650,
                  height: 60,
                  child: TextField(
                    controller: productNameEditController,
                    decoration: InputDecoration(
                      labelText: showEnglish ? 'Product Name(Spaces Between Product Name, Use Underline Instead, Ex.: La_Sierra)' : '商品名稱（商品名稱之間使用下劃線，如：La_Sierra）',
                      labelStyle: const TextStyle(color: colorWhite50, fontSize: 16),
                    ),
                    style: const TextStyle(fontSize: 24, color: colorWhite80),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 650,
                  height: 60,
                  child: TextField(
                    controller: imgPathEditController,
                    decoration: InputDecoration(
                      labelText: showEnglish ? 'Picture Image Name with Extension(Picture Name Same as Product Name, Ex.: La_Sierra)' : '商品圖片名稱',
                      labelStyle: const TextStyle(color: colorWhite50, fontSize: 16),
                    ),
                    style: const TextStyle(fontSize: 24, color: colorWhite80),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 650,
                  height: 60,
                  child: TextField(
                    controller: placeOrderEditController,
                    decoration: InputDecoration(
                      labelText: showEnglish ? 'the Order Displayed in the Menu List' : '商品排序',
                      labelStyle: const TextStyle(color: colorWhite50, fontSize: 16),
                    ),
                    style: const TextStyle(fontSize: 24, color: colorWhite80),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                    width: 650,
                    height: 60,
                    child: TextField(
                      controller: alcohol1EditController,
                      decoration: InputDecoration(
                        labelText: showEnglish ? 'Formula for HOT 12OZ' : '商品配方1',
                        labelStyle: const TextStyle(color: colorWhite50, fontSize: 16),
                      ),
                      style: const TextStyle(fontSize: 24, color: colorWhite80),
                    )),
                const SizedBox(height: 20),
                SizedBox(
                  width: 650,
                  height: 60,
                  child: TextField(
                    controller: alcohol2EditController,
                    decoration: InputDecoration(
                      labelText: showEnglish ? 'Formula for HOT 8OZ' : '商品配方2',
                      labelStyle: const TextStyle(color: colorWhite50, fontSize: 16),
                    ),
                    style: const TextStyle(fontSize: 24, color: colorWhite80),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 650,
                  height: 60,
                  child: TextField(
                    controller: alcohol3EditController,
                    decoration: InputDecoration(
                      labelText: showEnglish ? 'Formula for ICED 12OZ' : '商品配方3',
                      labelStyle: const TextStyle(color: colorWhite50, fontSize: 16),
                    ),
                    style: const TextStyle(fontSize: 24, color: colorWhite80),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 650,
                  height: 60,
                  child: TextField(
                    controller: alcohol4EditController,
                    decoration: InputDecoration(
                      labelText: showEnglish ? 'Formula for ICED 8OZ' : '商品配方4',
                      labelStyle: const TextStyle(color: colorWhite50, fontSize: 16),
                    ),
                    style: const TextStyle(fontSize: 24, color: colorWhite80),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 650,
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 3, child: Text(showEnglish ? 'Recommended:' : '推薦商品:', style: const TextStyle(color: colorWhite50, fontSize: 22))),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: colorWhite80,
                                width: 1,
                              ),
                            ),
                          ),
                          dropdownColor: colorDarkGrey,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: colorWhite80,
                          ),
                          iconSize: 28,
                          style: const TextStyle(
                            color: colorWhite80,
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                          ),
                          value: recommended,
                          items: [
                            DropdownMenuItem(
                              value: 1,
                              child: Text(showEnglish ? ' active' : '啟用', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                            ),
                            DropdownMenuItem(
                              value: 0,
                              child: Text(showEnglish ? 'disable' : '停用', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                            ),
                          ],
                          onChanged: (int? value) {
                            if (mounted) {
                              setState(() {
                                recommended = value!;
                              });
                            }
                          },
                        ),
                      ),
                      Expanded(flex: 2, child: Text(showEnglish ? '/ Active:' : '/  上線狀態:', style: const TextStyle(color: colorWhite50, fontSize: 22))),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: colorWhite80,
                                width: 1,
                              ),
                            ),
                          ),
                          dropdownColor: colorDarkGrey,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: colorWhite80,
                          ),
                          iconSize: 28,
                          style: const TextStyle(
                            color: colorWhite80,
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                          ),
                          value: active,
                          items: [
                            DropdownMenuItem(
                              value: 1,
                              child: Text(showEnglish ? ' active' : '啟用', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                            ),
                            DropdownMenuItem(
                              value: 0,
                              child: Text(showEnglish ? 'disable' : '停用', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                            ),
                          ],
                          onChanged: (int? value) {
                            if (mounted) {
                              setState(() {
                                active = value!;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 650,
                  height: 60,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(200, 60),
                      foregroundColor: colorWhite80,
                      backgroundColor: colorWhite80,
                      side: const BorderSide(
                        color: healDarkGrey,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () {
                      String alcoholText = '';
                      if (alcohol1EditController.text != '' && alcohol2EditController.text == '' && alcohol3EditController.text == '' && alcohol4EditController.text == '') {
                        alcoholText = '["${alcohol1EditController.text}"]';
                      }
                      if (alcohol1EditController.text != '' && alcohol2EditController.text != '' && alcohol3EditController.text == '' && alcohol4EditController.text == '') {
                        alcoholText = '["${alcohol1EditController.text}","${alcohol2EditController.text}"]';
                      }
                      if (alcohol1EditController.text != '' && alcohol2EditController.text != '' && alcohol3EditController.text != '' && alcohol4EditController.text == '') {
                        alcoholText = '["${alcohol1EditController.text}","${alcohol2EditController.text}","${alcohol3EditController.text}"]';
                      }
                      if (alcohol1EditController.text != '' && alcohol2EditController.text != '' && alcohol3EditController.text != '' && alcohol4EditController.text != '') {
                        alcoholText = '["${alcohol1EditController.text}","${alcohol2EditController.text}","${alcohol3EditController.text}","${alcohol4EditController.text}"]';
                      }
                      try {
                        DatabaseHelper().updateProduct({
                          'docId': product['docId'],
                          'productName': productNameEditController.text,
                          'alcohol': alcoholText,
                          'imgPath': imgPathEditController.text,
                          'placeOrder': placeOrderEditController.text,
                          'active': active, //productActive ? 1 : 0,
                          'recommended': recommended, // productRecommended ? 1 : 0,
                        }).then((value) {
                          _loadProductStreamData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Container(
                                height: 80.0, // 設置高度
                                alignment: Alignment.center,
                                color: healDarkGrey,
                                child: Text(
                                  showEnglish ? 'Product Edited Successfully' : '商品編輯成功',
                                  style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                ),
                              ),
                              behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                              ),
                              backgroundColor: colorWhite80,
                            ),
                          );
                          Navigator.pop(context);
                          Navigator.pop(context);
                        });
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                    child: Text(
                      showEnglish ? 'Edit And Save' : '編輯並儲存',
                      style: const TextStyle(fontSize: 24, color: healDarkGrey),
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

  Widget showPipeUseDataManage() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(200, 50),
              foregroundColor: colorWhite80,
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
              await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    backgroundColor: healDarkGrey,
                    content: Text(showEnglish ? 'Are you sure to import the pipe setting Excel?' : '確定導入管線設定 Excel?', style: const TextStyle(color: colorWhite80, fontSize: 28)),
                    actions: <Widget>[
                      TextButton(
                        child: Text(showEnglish ? 'Cancel' : '取消', style: const TextStyle(color: Colors.red, fontSize: 26)),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(color: colorWhite80, fontSize: 26)),
                        onPressed: () async {
                          String filePath = '$documentsPath/xlsx/pipe_use_manage.xlsx';
                          if (!File(filePath).existsSync()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'File does not exist, please place it in Documents/healcafe22/xlsx/' : '檔案不存在, 請先放置檔案再重試',
                                    style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                              ),
                            );
                            return;
                          }
                          _readPipeUseDataToDatabase().then((value) {
                            _loadPipeUseStreamData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'PipeUse Data Imported Successfully' : '管線設定導入成功',
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
                          }).catchError((e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    e.toString(),
                                    style: const TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          });
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Text(showEnglish ? 'Import File from Excel' : '使用EXCEL導入', style: const TextStyle(color: colorWhite80, fontSize: 22)),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          flex: 9,
          child: Container(
            width: double.infinity,
            height: 600,
            decoration: const BoxDecoration(
              color: healDarkGrey,
            ),
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: pipeUseData,
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text(showEnglish ? 'No PipeUse Data Found' : '尚未建立管路設定資料', style: const TextStyle(color: colorWhite80, fontSize: 24)));
                    } else {
                      return DataTable(
                        columns: [
                          DataColumn(
                            label: Text(
                              showEnglish ? 'ID' : '序號',
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Name' : '管設名稱',
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Pipe Setting String' : '管線設定字串',
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Active' : '狀態',
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Created Time' : '建立時間',
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            ),
                          ),
                          DataColumn(
                            label: IconButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return addPipeUse();
                                      });
                                },
                                icon: const Icon(Icons.add_circle_outline, color: colorWhite80, size: 40)),
                          ),
                        ],
                        rows: snapshot.data!.map((pipeUse) {
                          return DataRow(cells: [
                            DataCell(Text(
                              pipeUse['pipeUseId'].toString(),
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(SizedBox(
                              width: 80,
                              child: Text(
                                pipeUse['name'].toString(),
                                style: const TextStyle(color: colorWhite80, fontSize: 18),
                              ),
                            )),
                            DataCell(
                              SizedBox(
                                width: 400,
                                child: Text(
                                  pipeUse['pipeSettingString'],
                                  style: const TextStyle(color: colorWhite80, fontSize: 18),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                pipeUse['active'].toString(),
                                style: const TextStyle(color: colorWhite80, fontSize: 18),
                              ),
                            ),
                            DataCell(Text(
                              pipeUse['createdDateTime'].toString().isNotEmpty ? pipeUse['createdDateTime'].toString().substring(0, 19) : 'N/A',
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: colorWhite80),
                                    onPressed: () {
                                      showDialog(context: context, builder: (BuildContext context) => editPipeUse(pipeUse));
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: colorWhite80),
                                    onPressed: () {
                                      showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(10.0)), // 可選：設置圓角
                                            ),
                                            backgroundColor: healDarkGrey,
                                            title: Text(showEnglish ? 'Delete Pipe Setting' : '刪除管線設定', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                            content: Text(showEnglish ? 'Are you sure? ' : '確定刪除嗎?', style: const TextStyle(color: Colors.red, fontSize: 26)),
                                            actions: <Widget>[
                                              TextButton(
                                                child: Text(showEnglish ? 'Cancel' : '取消', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                                onPressed: () => Navigator.pop(context, false),
                                              ),
                                              TextButton(
                                                child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                                onPressed: () => {
                                                  DatabaseHelper().deletePipeUse(pipeUse['pipeUseId']).then((value) {
                                                    if (value) {
                                                      _loadPipeUseStreamData();
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          backgroundColor: colorDarkGrey,
                                                          content: Text(showEnglish ? 'Delete Success' : '刪除成功', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                                        ),
                                                      );
                                                    }
                                                  }),
                                                  Navigator.pop(context, true),
                                                  Navigator.pop(context, true),
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ).then((value) {
                                        if (value != null && value) {
                                          _loadPipeUseStreamData();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget addPipeUse() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController pipeUseStringController = TextEditingController();
    return Dialog(
      child: Container(
        color: healDarkGrey,
        width: double.infinity,
        height: 400,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(showEnglish ? 'Add pipe use' : '新增管線設定', style: const TextStyle(color: colorWhite80, fontSize: 28)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: showEnglish ? 'Input the PipeUse Name' : '請輸入管線設定名稱',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: TextField(
                      controller: pipeUseStringController,
                      decoration: InputDecoration(
                        labelText: showEnglish ? 'Spaces Between PipeUse name, Use Underline Instead, Ex.: La_Sierra' : '請輸入管線設定字串',
                        hintText: showEnglish ? 'Input the PipeUse String  Ex.:  {1: Mafaz}@{2: La_Sierra},...,@{6: Pereira},@{7: Tune}' : '請輸入管線設定字串 (例如: {1: 荔枝}@{2: 青梅}@{3: 芒果}...@{12: 伏特加}@{16: 氣泡水})',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 60,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(200, 60),
                        foregroundColor: colorWhite80,
                        backgroundColor: colorWhite80,
                        side: const BorderSide(
                          color: healDarkGrey,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () async {
                        if (nameController.text.isEmpty || pipeUseStringController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Container(
                                height: 80.0, // 設置高度
                                alignment: Alignment.center,
                                // color: healDarkGrey,
                                child: Text(
                                  showEnglish ? 'All fields are required' : '所有欄位都必須輸入',
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
                          return;
                        } else {
                          final Map<String, dynamic> pipeuse = {
                            'name': nameController.text,
                            'pipeSettingString': pipeUseStringController.text,
                            'active': false,
                            'createdDateTime': DateTime.now().toString(),
                          };
                          await DatabaseHelper().insertPipeUse(pipeuse).then((value) {
                            _loadPipeUseStreamData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'PipeUse Added Successfully' : '管線設定新增成功',
                                    style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：���置圓角
                                ),
                                backgroundColor: colorWhite80,
                              ),
                            );
                          }).catchError((e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  child: Text(
                                    e.toString(),
                                    style: const TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          });
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        showEnglish ? 'Add Pipe Use String' : '新增管線設定',
                        style: const TextStyle(fontSize: 26, color: healDarkGrey),
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

  Widget editPipeUse(Map<String, dynamic> pipeuse) {
    TextEditingController nameEditController = TextEditingController(text: pipeuse['name']);
    TextEditingController pipeSettingStringEditController = TextEditingController(text: pipeuse['pipeSettingString']);
    int active = int.parse(pipeuse['active'].toString());
    return Dialog(
      child: Container(
        color: healDarkGrey,
        width: double.infinity,
        height: 500,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(showEnglish ? 'Edit Pipe Use String' : '編輯管路設定', style: const TextStyle(color: colorWhite80, fontSize: 30), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 100,
                  height: 60,
                  child: TextField(
                    controller: nameEditController,
                    decoration: InputDecoration(
                      labelText: showEnglish ? 'Edit the Name for Identification' : '請輸入識別用名稱',
                      labelStyle: const TextStyle(color: colorWhite80, fontSize: 16),
                    ),
                    style: const TextStyle(fontSize: 24, color: colorWhite80),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 100,
                  height: 80,
                  child: TextField(
                    controller: pipeSettingStringEditController,
                    decoration: InputDecoration(
                      labelText: showEnglish ? 'Edit String forPipe Setting(Spaces Between Pipe Name, Use Underline Instead)' : '管路設定字串',
                      labelStyle: const TextStyle(color: colorWhite80, fontSize: 16),
                    ),
                    style: const TextStyle(fontSize: 24, color: colorWhite80),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 100,
                  height: 60,
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: Center(child: Text(showEnglish ? 'Active/Disable : ' : '啟閉開關 : ', style: const TextStyle(color: colorWhite80, fontSize: 22)))),
                      Expanded(
                        flex: 5,
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: colorWhite80,
                                width: 1,
                              ),
                            ),
                          ),
                          dropdownColor: colorDarkGrey,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: colorWhite80,
                          ),
                          iconSize: 28,
                          style: const TextStyle(
                            color: colorWhite80,
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                          ),
                          value: active,
                          items: [
                            DropdownMenuItem(
                              value: 1,
                              child: Text(showEnglish ? ' active' : '啟用', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                            ),
                            DropdownMenuItem(
                              value: 0,
                              child: Text(showEnglish ? 'disable' : '停用', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                            ),
                          ],
                          onChanged: (int? value) {
                            if (mounted) {
                              setState(() {
                                active = value!;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 650,
                  height: 60,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(200, 60),
                      foregroundColor: colorWhite80,
                      backgroundColor: colorWhite80,
                      side: const BorderSide(
                        color: healDarkGrey,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () async {
                      if (nameEditController.text == '' && pipeSettingStringEditController.text == '') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Container(
                              height: 80.0, // 設置高度
                              alignment: Alignment.center,
                              // color: healDarkGrey,
                              child: Text(
                                showEnglish ? 'All Fields Are Required' : '請輸入店名 與 管路設定字串',
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
                        return;
                      }
                      try {
                        if (active == 1) {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          prefs.setString('pipeUseId', pipeuse['pipeUseId'].toString());
                          // 除了'pipeUseId' = pipeuse['pipeUseId']這筆資料之外的所有資料 都將 active設為0
                          await DatabaseHelper().updateActiveFieldToZero();

                          DatabaseHelper().updatePipeUse({
                            'pipeUseId': pipeuse['pipeUseId'],
                            'name': nameEditController.text,
                            'pipeSettingString': pipeSettingStringEditController.text,
                            'active': active, //pipeActiveEditController.text == '1' ? 1 : 0,
                          }).then((value) {
                            _loadPipeUseStreamData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'Pipe Setting String Edited Successfully' : '管路設定編輯成功',
                                    style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                                backgroundColor: colorWhite80,
                              ),
                            );
                            Navigator.pop(context);
                          });
                        } else {
                          DatabaseHelper().updatePipeUse({
                            'pipeUseId': pipeuse['pipeUseId'],
                            'name': nameEditController.text,
                            'pipeSettingString': pipeSettingStringEditController.text,
                            'active': active, //pipeActiveEditController.text == '1' ? 1 : 0,
                          }).then((value) {
                            _loadPipeUseStreamData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'Pipe Setting String Edited Successfully' : '管路設定編輯成功',
                                    style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                                backgroundColor: colorWhite80,
                              ),
                            );
                          });
                        }
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                      Navigator.pop(context);
                    },
                    child: Text(
                      showEnglish ? 'Edit And Save' : '編輯並儲存',
                      style: const TextStyle(fontSize: 24, color: healDarkGrey),
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

  Widget showTranscationDataManage() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(200, 50),
              foregroundColor: colorWhite80,
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
              // 先做confirm 檢查 AlertDialog
              await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    backgroundColor: healDarkGrey,
                    content: Text(showEnglish ? 'Are you sure to import the Records Excel?' : '確定導入交易紀錄 Excel?', style: const TextStyle(color: colorWhite80, fontSize: 28)),
                    actions: <Widget>[
                      TextButton(
                        child: Text(showEnglish ? 'Cancel' : '取消', style: const TextStyle(color: Colors.red, fontSize: 26)),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(color: colorWhite80, fontSize: 26)),
                        onPressed: () async {
                          // 檢查檔案是否存在
                          String filePath = '$documentsPath/xlsx/all_transcation_records.xlsx';
                          if (!File(filePath).existsSync()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'File does not exist, please place it in Documents/healcafe22/xlsx/' : '檔案不存在, 請先放置檔案再重試',
                                    style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                              ),
                            );
                            return;
                          }
                          _readTranscationDataToDatabase().then((value) {
                            _loadTranscationsStreamData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'Records Data Imported Successfully' : '交易紀錄資料導入成功',
                                    style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          }).catchError((e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    e.toString(),
                                    style: const TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          });
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Text(showEnglish ? 'Import File from Excel' : '使用EXCEL導入', style: const TextStyle(color: colorWhite80, fontSize: 22)),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          flex: 9,
          child: Container(
            width: double.infinity,
            height: 600,
            decoration: const BoxDecoration(
              color: healDarkGrey,
            ),
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: transcationsData,
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text(showEnglish ? 'No Records found' : '尚未建立交易資料', style: const TextStyle(color: colorWhite80, fontSize: 24)));
                    } else {
                      return DataTable(
                        columns: [
                          DataColumn(
                            label: Text(
                              showEnglish ? 'OrderNo' : '訂單編號',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'P.Name' : '產品名稱',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Price' : '價格',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'FormulaString' : '配方字串',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Result' : '製作結果',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Source' : '來源',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          // DataColumn(
                          //   label: Text(
                          //     showEnglish ? 'Sales' : '銷售者',
                          //     style: const TextStyle(color: colorWhite80, fontSize: 20),
                          //   ),
                          // ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Created Date' : '建立日期',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Action' : '動作',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                        ],
                        rows: snapshot.data!.map((record) {
                          return DataRow(cells: [
                            DataCell(SizedBox(
                              width: 80,
                              child: Text(
                                record['transactionOrderNo'].toString(),
                                style: const TextStyle(color: colorWhite80, fontSize: 18),
                              ),
                            )),
                            DataCell(Text(
                              record['productName'],
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(
                              Text(
                                record['price'].toString(),
                                style: const TextStyle(color: colorWhite80, fontSize: 18),
                              ),
                            ),
                            DataCell(Text(
                              record['formulaString'],
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(Text(
                              record['isDrinkMade'].toString() == '1' ? 'Success' : 'Fail',
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(Text(
                              record['sourceId'],
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            // DataCell(
                            //   Text(
                            //     record['salesId'].split('@')[0],
                            //     style: const TextStyle(color: colorWhite80, fontSize: 18),
                            //   ),
                            // ),
                            DataCell(SizedBox(
                              width: 100,
                              child: Text(
                                record['createdDateTime'].toString().substring(0, 19),
                                style: const TextStyle(color: colorWhite80, fontSize: 18),
                              ),
                            )),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: colorWhite80),
                                    onPressed: () {
                                      showDialog(context: context, builder: (BuildContext context) => editRecord(record));
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: colorWhite80),
                                    onPressed: () {
                                      showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(10.0)), // 可選：設置圓角
                                            ),
                                            backgroundColor: healDarkGrey,
                                            title: Text(showEnglish ? 'Delete Transaction' : '刪除交易紀錄', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                            content: Text(showEnglish ? 'Are you sure? ' : '確定刪除嗎?', style: const TextStyle(color: Colors.red, fontSize: 26)),
                                            actions: <Widget>[
                                              TextButton(
                                                child: Text(showEnglish ? 'Cancel' : '取消', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                                onPressed: () => Navigator.pop(context, false),
                                              ),
                                              TextButton(
                                                child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                                onPressed: () => {
                                                  DatabaseHelper().deleteTransactionRecord(record['recordId']).then((value) {
                                                    _loadTranscationsStreamData();
                                                  }),
                                                  Navigator.pop(context, true),
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ).then((value) {
                                        if (value != null && value) {
                                          _loadTranscationsStreamData(); // 重新加載產品數據
                                        }
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget editRecord(record) {
    return AlertDialog(
      backgroundColor: healDarkGrey,
      title: Text(showEnglish ? 'Edit Transaction Record' : '編輯交易紀錄', style: const TextStyle(color: colorWhite80, fontSize: 24)),
      content: Text(showEnglish ? 'Edit Transaction Record' : '編輯交易紀錄', style: const TextStyle(color: colorWhite80, fontSize: 24)),
      actions: <Widget>[
        TextButton(
          child: Text(showEnglish ? 'Cancel' : '取消', style: const TextStyle(color: colorWhite80, fontSize: 24)),
          onPressed: () => Navigator.pop(context, false),
        ),
        TextButton(
          child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(color: colorWhite80, fontSize: 24)),
          onPressed: () async {
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }

  Widget showQrcodeDataManage() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(200, 50),
              foregroundColor: colorWhite80,
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
              // 先做confirm 檢查 AlertDialog
              await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    backgroundColor: healDarkGrey,
                    content: Text(showEnglish ? 'Are you sure to import the qrcode Excel?' : '確定導入Qrcode Excel?', style: const TextStyle(color: colorWhite80, fontSize: 28)),
                    actions: <Widget>[
                      TextButton(
                        child: Text(showEnglish ? 'Cancel' : '取消', style: const TextStyle(color: Colors.red, fontSize: 26)),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(color: colorWhite80, fontSize: 26)),
                        onPressed: () async {
                          // 檢查檔案是否存在
                          String filePath = '$documentsPath/xlsx/qrcode_manage.xlsx';
                          if (!File(filePath).existsSync()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'File does not exist, please place it in Documents/healcafe22/xlsx/' : '檔案不存在, 請先放置檔案再重試',
                                    style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                              ),
                            );
                            return;
                          }
                          _readQrcodeDataToDatabase().then((value) {
                            _loadQrcodeStreamData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'Qrcode Data Imported Successfully' : 'Qrcode資料導入成功',
                                    style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          }).catchError((e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    e.toString(),
                                    style: const TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          });
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Text(showEnglish ? 'Import File from Excel' : '使用EXCEL導入', style: const TextStyle(color: colorWhite80, fontSize: 22)),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          flex: 9,
          child: Container(
            width: double.infinity,
            height: 600,
            decoration: const BoxDecoration(
              color: healDarkGrey,
            ),
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: dbHelper.getAllQrcodes(),
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text(showEnglish ? 'No qrcode found' : '尚未建立 Qrcode 資料', style: const TextStyle(color: colorWhite80, fontSize: 24)));
                    } else {
                      return DataTable(
                        columns: [
                          DataColumn(
                            label: Text(
                              showEnglish ? 'QrCode Id' : 'Qrcode ID',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Q.Type' : 'Qrcode類型',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'EventId' : '活動名稱',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'StartTime' : '啟用時間',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'EndTime' : '停用時間',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'Status' : '使用狀態',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              showEnglish ? 'CreatedDate' : '建立日期',
                              style: const TextStyle(color: colorWhite80, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: IconButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return addQrcode();
                                      });
                                },
                                icon: const Icon(Icons.add_circle_outline, color: colorWhite80, size: 40)),
                          ),
                        ],
                        rows: snapshot.data!.map((qrcode) {
                          return DataRow(cells: [
                            DataCell(Text(
                              qrcode['qrCodeId'] != null ? qrcode['qrCodeId']!.toString() : '',
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(
                              Text(
                                qrcode['qrCodeType'].toString(),
                                style: const TextStyle(color: colorWhite80, fontSize: 18),
                              ),
                            ),
                            DataCell(Text(
                              qrcode['eventId'],
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(Text(
                              qrcode['startDateTime'] != null ? qrcode['startDateTime'].toString().substring(0, 19) : '',
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(Text(
                              qrcode['endDateTime'] != null ? qrcode['endDateTime'].toString().substring(0, 19) : '',
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(
                              Text(
                                qrcode['isUsed'] == 1
                                    ? showEnglish
                                        ? 'Used'
                                        : '已使用'
                                    : showEnglish
                                        ? 'Unused'
                                        : '未使用',
                                style: const TextStyle(color: colorWhite80, fontSize: 18),
                              ),
                            ),
                            DataCell(Text(
                              qrcode['createdDateTime'] != null ? qrcode['createdDateTime'].toString().substring(0, 19) : '',
                              style: const TextStyle(color: colorWhite80, fontSize: 18),
                            )),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: colorWhite80),
                                    onPressed: () {
                                      showDialog(context: context, builder: (BuildContext context) => editQrcode(qrcode));
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: colorWhite80),
                                    onPressed: () {
                                      showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(10.0)), // 可選：設置圓角
                                            ),
                                            backgroundColor: healDarkGrey,
                                            title: Text(showEnglish ? 'Delete Qrcode' : '刪除Qrcode', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                            content: Text(showEnglish ? 'Are you sure? ' : '確定刪除嗎?', style: const TextStyle(color: Colors.red, fontSize: 26)),
                                            actions: <Widget>[
                                              TextButton(
                                                child: Text(showEnglish ? 'Cancel' : '取消', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                                onPressed: () => Navigator.pop(context, false),
                                              ),
                                              TextButton(
                                                child: Text(showEnglish ? 'Confirm' : '確定', style: const TextStyle(color: colorWhite80, fontSize: 24)),
                                                onPressed: () => {
                                                  DatabaseHelper().deleteQrcode(qrcode['qrcodeId']).then((value) {
                                                    _loadQrcodeStreamData();
                                                  }),
                                                  Navigator.pop(context, true),
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ).then((value) {
                                        if (value != null && value) {
                                          _loadQrcodeStreamData(); // 重新加載產品數據
                                        }
                                      });
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget addQrcode() {
    final TextEditingController qrcodeIdController = TextEditingController();
    final TextEditingController eventTypeController = TextEditingController();
    final TextEditingController startDateTimeController = TextEditingController();
    final TextEditingController endDateTimeController = TextEditingController();
    int qrcodeType = 4;
    return Dialog(
      child: Container(
        color: healDarkGrey,
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(showEnglish ? 'Add Qrcode' : '新增Qrcode', style: const TextStyle(color: colorWhite80, fontSize: 28)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: TextField(
                      controller: qrcodeIdController,
                      decoration: InputDecoration(
                        hintText: showEnglish ? 'Input Qrcode ID' : '請輸入20 碼 Qrcode ID',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorWhite80,
                            width: 1,
                          ),
                        ),
                      ),
                      dropdownColor: colorWhite80,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: colorWhite80,
                      ),
                      iconSize: 28,
                      style: const TextStyle(
                        color: colorWhite80,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                      value: qrcodeType,
                      items: [
                        DropdownMenuItem(
                          value: 4,
                          child: Text(showEnglish ? 'QRcode Free' : 'QRcode交易免付費', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                        ),
                        DropdownMenuItem(
                          value: 5,
                          child: Text(showEnglish ? 'QRcode Discount' : 'QRcode交易折抵用', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                        ),
                        DropdownMenuItem(
                          value: 6,
                          child: Text(showEnglish ? 'QRcode Free and unlimited times' : 'QRcode交易免付費且不限次數', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                        ),
                        DropdownMenuItem(
                          value: 7,
                          child: Text(showEnglish ? 'QRcode Discount and unlimited times' : 'QRcode交易折抵用且不限次數', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                        ),
                      ],
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {
                            qrcodeType = value!;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: TextField(
                      controller: eventTypeController,
                      decoration: InputDecoration(
                        hintText: showEnglish ? 'Input Event Name' : '請輸入活動名稱',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: TextField(
                      controller: startDateTimeController,
                      decoration: InputDecoration(
                        hintText: showEnglish ? 'Input Start Time' : '請輸入開始時間',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: TextField(
                      controller: endDateTimeController,
                      decoration: InputDecoration(
                        hintText: showEnglish ? 'Input End Time' : '請輸入結束時間',
                        hintStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: colorWhite80),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: colorWhite80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 60,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(200, 60),
                        foregroundColor: colorWhite80,
                        backgroundColor: colorWhite80,
                        side: const BorderSide(
                          color: healDarkGrey,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () async {
                        if (qrcodeIdController.text.isEmpty || eventTypeController.text.isEmpty || startDateTimeController.text.isEmpty || endDateTimeController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Container(
                                height: 80.0, // 設置高度
                                alignment: Alignment.center,
                                // color: healDarkGrey,
                                child: Text(
                                  showEnglish ? 'All fields are required' : '所有空欄位都必須輸入',
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
                        } else {
                          final Map<String, dynamic> qrcode = {
                            'qrCodeId': qrcodeIdController.text,
                            'qrCodeType': qrcodeType,
                            'eventId': eventTypeController.text,
                            'startDateTime': startDateTimeController.text,
                            'endDateTime': endDateTimeController.text,
                            'createdDateTime': DateTime.now().toString(),
                            'exchangeDateTime': DateTime.now().toString(),
                          };
                          await DatabaseHelper().insertQrcode(qrcode).then((value) {
                            _loadQrcodeStreamData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  height: 80.0, // 設置高度
                                  alignment: Alignment.center,
                                  // color: healDarkGrey,
                                  child: Text(
                                    showEnglish ? 'Qrcode Added Successfully' : 'Qrcode新增成功',
                                    style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                                ),
                                backgroundColor: colorWhite80,
                              ),
                            );
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        showEnglish ? 'Add Qrcode' : '新增Qrcode',
                        style: const TextStyle(fontSize: 26, color: healDarkGrey),
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

  // Widget editQrcode(Map<String, dynamic> qrcode) {
  Widget editQrcode(Map<String, dynamic> qrcode) {
    int qrcodeType = qrcode['qrCodeType'] ?? 4;
    TextEditingController qrcodeIdEditController = TextEditingController(text: qrcode['qrCodeId'] ?? '');
    TextEditingController startDateTimeEditController = TextEditingController(text: qrcode['startDateTime'] ?? '');
    TextEditingController endDateTimeEditController = TextEditingController(text: qrcode['endDateTime'] ?? '');

    return Dialog(
      child: Container(
        color: healDarkGrey,
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(showEnglish ? 'Edit Qrcode' : '編輯Qrcode', style: const TextStyle(color: healDarkGrey, fontSize: 30), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  height: 80,
                  child: TextField(
                    controller: qrcodeIdEditController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: showEnglish ? 'Input the Qrcode ID' : '輸入Qrcode ID',
                      labelStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                    ),
                    style: const TextStyle(color: colorWhite80, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  // 使用 radio 組件 來呈現選項 1,2,3,9 的選擇
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: colorWhite80,
                          width: 1,
                        ),
                      ),
                    ),
                    dropdownColor: colorDarkGrey,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: colorWhite80,
                    ),
                    iconSize: 28,
                    style: const TextStyle(
                      color: colorWhite80,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                    value: qrcodeType,
                    items: [
                      DropdownMenuItem(
                        value: 4,
                        child: Text(showEnglish ? 'QRcode Free' : 'QRcode交易免付費', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                      ),
                      DropdownMenuItem(
                        value: 5,
                        child: Text(showEnglish ? 'QRcode Discount' : 'QRcode交易折抵用', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                      ),
                      DropdownMenuItem(
                        value: 6,
                        child: Text(showEnglish ? 'QRcode Free and unlimited times' : 'QRcode交易免付費且不限次數', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                      ),
                      DropdownMenuItem(
                        value: 7,
                        child: Text(showEnglish ? 'QRcode Discount and unlimited times' : 'QRcode交易折抵用且不限次數', style: const TextStyle(color: colorWhite80, fontSize: 22)),
                      ),
                    ],
                    onChanged: (int? value) {
                      if (mounted) {
                        setState(() {
                          qrcodeType = value!;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                //startDateTime
                SizedBox(
                  width: 350,
                  height: 60,
                  child: TextField(
                    controller: startDateTimeEditController,
                    decoration: InputDecoration(
                      labelText: showEnglish ? 'Input the startDateTime' : '輸入開始時間',
                      labelStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                    ),
                    style: const TextStyle(color: colorWhite80, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 20),
                //endDateTime
                SizedBox(
                  width: 350,
                  height: 60,
                  child: TextField(
                    controller: endDateTimeEditController,
                    decoration: InputDecoration(
                      labelText: showEnglish ? 'Input the endDateTime' : '輸入結束時間',
                      labelStyle: const TextStyle(color: colorWhite80, fontSize: 22),
                    ),
                    style: const TextStyle(color: colorWhite80, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  height: 60,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(200, 60),
                      foregroundColor: colorWhite80,
                      backgroundColor: colorWhite80,
                      side: const BorderSide(
                        color: healDarkGrey,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () {
                      try {
                        DatabaseHelper().updateQrcode({
                          'qrCodeId': qrcode['qrCodeId'],
                          'qrCodeType': qrcodeType,
                          'startDateTime': startDateTimeEditController.text,
                          'endDateTime': endDateTimeEditController.text,
                          'exchangeDateTime': DateTime.now().toString(),
                          'createdDateTime': qrcode['createdDateTime'].toString(),
                        }).then((value) {
                          _loadQrcodeStreamData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Container(
                                height: 80.0, // 設置高度
                                alignment: Alignment.center,
                                // color: healDarkGrey,
                                child: Text(
                                  showEnglish ? 'Qrcode Edited Successfully' : 'Qrcode編輯成功',
                                  style: const TextStyle(fontSize: 24.0, color: colorWhite80),
                                ),
                              ),
                              behavior: SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0), // 可選：設置圓角
                              ),
                              backgroundColor: colorWhite80,
                            ),
                          );
                          Navigator.pop(context);
                          Navigator.pop(context);
                        });
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                    child: Text(
                      showEnglish ? 'Edit And Save' : '編輯並儲存',
                      style: const TextStyle(fontSize: 24, color: healDarkGrey),
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
