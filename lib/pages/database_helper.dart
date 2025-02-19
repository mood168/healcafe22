// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'product.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'healcafe22.db');
    return await openDatabase(
      path,
      version: 2, // 更新版本號
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE user_login (
      userEmail TEXT PRIMARY KEY,
      userName TEXT,
      userPassWord TEXT,
      userLevel INTEGER,
      userId TEXT,
      createdDateTime TEXT,
      userPhone TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE products (
      docId TEXT PRIMARY KEY,
      productName TEXT,
      alcohol TEXT,
      price INTEGER,
      imgPath TEXT,
      placeOrder INTEGER,
      recommended INTEGER,
      active INTEGER,      
      createdDateTime TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE qrcode_manage (
      qrCodeId TEXT PRIMARY KEY,
      qrCodeType INTEGER,
      eventId TEXT,
      isUsed INTEGER,
      exchangeDateTime TEXT,
      startDateTime TEXT,
      endDateTime TEXT,
      createdDateTime TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE all_transcation_records (
      recordId INTEGER PRIMARY KEY AUTOINCREMENT,
      productName TEXT,
      formulaString TEXT,
      imgPath TEXT,
      correctWeight1 INTEGER,
      correctWeight2 INTEGER,
      correctWeight3 INTEGER,
      correctWeight4 INTEGER,
      correctWeight5 INTEGER,
      correctWeight6 INTEGER,
      correctWeight7 INTEGER,
      correctWeight8 INTEGER,
      correctWeight9 INTEGER,
      correctWeight10 INTEGER,
      correctWeight11 INTEGER,
      correctWeight12 INTEGER,
      correctWeight13 INTEGER,
      correctWeight14 INTEGER,
      correctWeight16 INTEGER,
      g1 INTEGER,
      g2 INTEGER,
      g3 INTEGER,
      g4 INTEGER,
      g5 INTEGER,
      g6 INTEGER,
      g7 INTEGER,
      g8 INTEGER,
      g9 INTEGER,
      g10 INTEGER,
      g11 INTEGER,
      g12 INTEGER,
      g13 INTEGER,
      g14 INTEGER,
      g16 INTEGER,
      createdDateTime TEXT,
      isDrinkMade INTEGER,
      price INTEGER,
      qrCodeId TEXT,
      salesId TEXT,
      sourceId TEXT,
      transactionOrderNo TEXT,
      remark TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE pipe_use_manage (
        pipeUseId INTEGER PRIMARY KEY,
        name TEXT,
        pipeSettingString TEXT,
        active INTEGER,
        createdDateTime TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
    CREATE TABLE products (
      docId TEXT PRIMARY KEY,
      productName TEXT,
      alcohol TEXT,
      price INTEGER,
      imgPath TEXT,
      placeOrder INTEGER,
      recommended INTEGER,
      active INTEGER,      
      createdDateTime TEXT
    )
  ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
      CREATE TABLE qrcode_manage (
      qrCodeId TEXT PRIMARY KEY,
      qrCodeType INTEGER,
      eventId TEXT,
      isUsed INTEGER,
      exchangeDateTime TEXT,
      startDateTime TEXT,
      endDateTime TEXT,
      createdDateTime TEXT
      )
    ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
      CREATE TABLE all_transcation_records (
        recordId INTEGER PRIMARY KEY AUTOINCREMENT,
        productName TEXT,
        formulaString TEXT,
        imgPath TEXT,
        correctWeight1 INTEGER,
        correctWeight2 INTEGER,
        correctWeight3 INTEGER,
        correctWeight4 INTEGER,
        correctWeight5 INTEGER,
        correctWeight6 INTEGER,
        correctWeight7 INTEGER,
        correctWeight8 INTEGER,
        correctWeight9 INTEGER,
        correctWeight10 INTEGER,
        correctWeight11 INTEGER,
        correctWeight12 INTEGER,
        correctWeight13 INTEGER,
        correctWeight14 INTEGER,
        correctWeight16 INTEGER,
        g1 INTEGER,
        g2 INTEGER,
        g3 INTEGER,
        g4 INTEGER,
        g5 INTEGER,
        g6 INTEGER,
        g7 INTEGER,
        g8 INTEGER,
        g9 INTEGER,
        g10 INTEGER,
        g11 INTEGER,
        g12 INTEGER,
        g13 INTEGER,
        g14 INTEGER,
        g16 INTEGER,
        createdDateTime TEXT,
        isDrinkMade INTEGER,
        price INTEGER,
        qrCodeId TEXT,
        salesId TEXT,
        sourceId TEXT,
        transactionOrderNo TEXT,
        remark TEXT
      )
    ''');
    }

    if (oldVersion < 5) {
      await db.execute('''
    CREATE TABLE pipe_use_manage (
        pipeUseId INTEGER PRIMARY KEY,
        name TEXT,
        pipeSettingString TEXT,
        active INTEGER,
        createdDateTime TEXT
      )
    ''');
    }
  }

  String generate20CharGuid() {
    const uuid = Uuid(); //
    return uuid.v4().substring(0, 20);
  }

  // 插入數據示例
  Future<void> insertQrCode(Map<String, dynamic> qrCode) async {
    final db = await database;
    await db.insert('qrcode_manage', qrCode, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('user_login', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.insert('products', product, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUser(String userEmail) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_login',
      where: 'userEmail = ?',
      whereArgs: [userEmail],
    );
    // print('maps: ${maps.toString()}');
    if (maps.isNotEmpty) {
      prefs.setString('userEmail', userEmail);
      return maps.first;
    }
    prefs.setString('userEmail', '');
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllMembers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_login',
      orderBy: 'createdDateTime DESC',
    );
    if (maps.isNotEmpty) {
      return maps;
    }
    // Add a return statement here to handle the case when maps is empty
    return [];
  }

  Future<void> updateMember(Map<String, dynamic> user) async {
    final db = await database;
    await db.update(
      'user_login',
      user,
      where: 'userId = ?',
      whereArgs: [user['userId']],
    );
  }

  Future<void> deleteMember(String userId) async {
    final db = await database;
    await db.delete(
      'user_login',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllProductsMenu() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'placeOrder ASC',
    );
    if (maps.isNotEmpty) {
      return maps;
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      orderBy: 'placeOrder ASC',
    );
    if (maps.isNotEmpty) {
      return maps;
    }
    return [];
  }

  Future<List<Product>> getProductsByDocId(docId) async {
    final db = await database;
    final List<Product> products = [];
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'docId = ?',
      whereArgs: [docId],
    );
    for (var map in maps) {
      products.add(Product.fromMap(map));
    }
    return products;
  }

  Future<List<Map<String, dynamic>>> getAllRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'all_transcation_records',
      orderBy: 'createdDateTime DESC',
    );
    if (maps.isNotEmpty) {
      return maps;
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getAllRecordsProductTotal() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'all_transcation_records',
      groupBy: 'productName',
    );
    if (maps.isNotEmpty) {
      return maps;
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getAllRecordsLike(String searchString) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'all_transcation_records',
      where: 'transactionOrderNo like ?',
      whereArgs: ['%$searchString%'],
      orderBy: 'createdDateTime DESC',
    );
    if (maps.isNotEmpty) {
      return maps;
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getAllRecordsStart(String startDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'all_transcation_records',
      where: 'createdDateTime >= ?',
      whereArgs: ['$startDate 00:00:00'],
      orderBy: 'createdDateTime DESC',
    );
    if (maps.isNotEmpty) {
      return maps;
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getAllRecordsByOrderNumber(String orderNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'all_transcation_records',
      where: 'transactionOrderNo = ?',
      whereArgs: [orderNumber],
    );
    if (maps.isNotEmpty) {
      return maps;
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getAllRecordsStartEnd(String startDate, String endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'all_transcation_records',
      where: 'createdDateTime >= ? AND createdDateTime <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'createdDateTime DESC',
    );
    if (maps.isNotEmpty) {
      return maps;
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getAllRecordsStartEndBySource(String startDate, String endDate, String source) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'all_transcation_records',
      where: 'createdDateTime >= ? AND createdDateTime <= ? AND sourceId = ?',
      whereArgs: [startDate, endDate, source],
      orderBy: 'createdDateTime DESC',
    );

    if (maps.isNotEmpty) {
      return maps;
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> insertTransactionRecords(Map<String, dynamic> record) async {
    final db = await database;
    await db.insert(
      'all_transcation_records',
      record,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return [];
  }

  Future<List<Map<String, dynamic>>> updateTransactionRecord(Map<String, dynamic> record) async {
    final db = await database;
    await db.update(
      'all_transcation_records',
      record,
      where: 'transactionOrderNo = ?',
      whereArgs: [record['transactionOrderNo']],
    );
    return [];
  }

  Future<List<Map<String, dynamic>>> deleteTransactionRecord(String recordId) async {
    final db = await database;
    await db.delete(
      'all_transcation_records',
      where: 'recordId = ?',
      whereArgs: [recordId],
    );
    return [];
  }

  Future<List<Map<String, dynamic>>> getAllQrcodes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'qrcode_manage',
    );
    if (maps.isNotEmpty) {
      return maps;
    }
    return [];
  }

  Future<void> insertQrcode(Map<String, dynamic> qrcode) async {
    final db = await database;
    await db.insert('qrcode_manage', qrcode, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateQrcode(Map<String, dynamic> qrcode) async {
    final db = await database;
    await db.update(
      'qrcode_manage',
      qrcode,
      where: 'qrCodeId = ?',
      whereArgs: [qrcode['qrCodeId']],
    );
  }

  Future<void> deleteQrcode(String qrCodeId) async {
    final db = await database;
    await db.delete(
      'qrcode_manage',
      where: 'qrCodeId = ?',
      whereArgs: [qrCodeId],
    );
  }

  Future<List<Map<String, dynamic>>> getQrcodeById(String qrCodeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'qrcode_manage',
      where: 'qrCodeId = ?',
      whereArgs: [qrCodeId],
    );
    if (maps.isNotEmpty) {
      return maps;
    }
    return [];
  }

  Future<String> getLatestUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? '';
    if (userId.isEmpty) {
      userId = 'S00001';
    } else {
      userId = 'S${(int.parse(userId.substring(1)) + 1).toString().padLeft(5, '0')}';
    }
    prefs.setString('userId', userId);
    return userId;
  }

  Future<List<Map<String, dynamic>>> getAllQrcodeById(String qrCodeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'qrcode',
      where: 'qrCodeId = ?',
      whereArgs: [qrCodeId],
    );
    if (maps.isNotEmpty) {
      return maps;
    }
    return [];
  }

  Future<void> updateQrcodeById(Map<String, dynamic> qrcode) async {
    final db = await database;
    await db.update(
      'qrcode',
      qrcode,
      where: 'qrCodeId = ?',
      whereArgs: [qrcode['qrCodeId']],
    );
  }

  Future<List<Map<String, dynamic>>> getProductsByDocQrcodeId(String docId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'docId = ?',
      whereArgs: [docId],
    );
    if (maps.isNotEmpty) {
      return maps;
    }
    return [];
  }

  Future<void> updateProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.update(
      'products',
      product,
      where: 'docId = ?',
      whereArgs: [product['docId']],
    );
  }

  Future<void> updateProductActive(Map<String, dynamic> product) async {
    final db = await database;
    await db.update(
      'products',
      product,
      where: 'docId = ?',
      whereArgs: [product['docId']],
    );
  }

  Future<bool> deleteProduct(String docId) async {
    final db = await database;
    await db.delete(
      'products',
      where: 'docId = ?',
      whereArgs: [docId],
    );
    return true;
  }

  Future<bool> deleteProductAll() async {
    final db = await database;
    await db.delete(
      'products',
    );
    return true;
  }

  Future<void> insertPipeUse(Map<String, dynamic> pipeUse) async {
    final db = await database;
    await db.insert('pipe_use_manage', pipeUse, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllPipeUses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pipe_use_manage',
      orderBy: 'createdDateTime DESC',
    );
    if (maps.isNotEmpty) {
      return maps;
    }
    return [];
  }

  Future<void> updatePipeUse(pipeUse) async {
    final db = await database;
    await db.update(
      'pipe_use_manage',
      pipeUse,
      where: 'pipeUseId = ?',
      whereArgs: [pipeUse['pipeUseId']],
    );
  }

  //設定函式 updateActiveFieldToZero 讓所有 pipeUseId 的 active 字段設為 0
  Future<void> updateActiveFieldToZero() async {
    final db = await database;
    await db.update(
      'pipe_use_manage',
      {
        'active': 0,
      },
      where: 'active = ?',
      whereArgs: [1],
    );
  }

  Future<void> updatePipeUseOpposite(Map<String, dynamic> pipeuse) async {
    final db = await database;
    await db.update(
      'pipe_use_manage',
      pipeuse,
      where: 'pipUseId = ?',
      whereArgs: [pipeuse['pipUseId']],
    );
  }

  Future<bool> deletePipeUse(int pipeUseId) async {
    final db = await database;
    await db.delete(
      'pipe_use_manage',
      where: 'pipeUseId = ?',
      whereArgs: [pipeUseId],
    );
    return true;
  }

  Future<void> updatePipeUsesActiveExcept() async {
    final db = await database;
    await db.update(
      'pipe_use_manage',
      {
        'active': 0,
      },
      where: 'active = ?',
      whereArgs: [1],
    );
  }
}

class ProductTotal {
  String name;
  String imgPath;
  int total;
  int quantity;

  ProductTotal({required this.name, required this.imgPath, required this.total, required this.quantity});
}
