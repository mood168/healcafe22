import 'package:flutter/material.dart';
import 'pages/database_helper.dart';
import 'pages/main_page.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> checkAndRequestPermission() async {
  var storageStatus = await Permission.storage.status;
  var externalStorageStatus = await Permission.manageExternalStorage.status;

  if (!storageStatus.isGranted) {
    var result = await Permission.storage.request();
    if (!result.isGranted) {
      return false;
    }
  }

  if (!externalStorageStatus.isGranted) {
    var result = await Permission.manageExternalStorage.request();
    if (!result.isGranted) {
      return false;
    }
  }

  return true;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    bool permissionGranted = await checkAndRequestPermission();
    if (!permissionGranted) {
      debugPrint('Storage permissions not granted');
      // 您可能想要在這裡添加一些錯誤處理邏輯
    } else {
      debugPrint('All permissions granted');
    }

    await DatabaseHelper().database; // 初始化資料庫
    debugPrint('Sqlite 初始化成功！');
  } catch (e) {
    debugPrint('初始化出現異常：$e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}
