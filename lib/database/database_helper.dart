import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'catat_duit.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        amount INTEGER,
        date TEXT,
        type TEXT,
        account_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        type TEXT, 
        balance INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        type TEXT
      )
    ''');

    // Default Categories
    await db.insert('categories', {'name': 'Makan', 'type': 'Expense'});
    await db.insert('categories', {'name': 'Transport', 'type': 'Expense'});
    await db.insert('categories', {'name': 'Kost', 'type': 'Expense'});
    await db.insert('categories', {'name': 'Belanja', 'type': 'Expense'});
    await db.insert('categories', {'name': 'Hiburan', 'type': 'Expense'});
    await db.insert('categories', {'name': 'Gaji', 'type': 'Income'});
    await db.insert('categories', {'name': 'Bonus', 'type': 'Income'});
  }

  // --- CRUD KATEGORI ---
  Future<List<Map<String, dynamic>>> getCategories(String type) async {
    Database db = await database;
    return await db.query('categories', where: 'type = ?', whereArgs: [type]);
  }

  Future<int> insertCategory(String name, String type) async {
    Database db = await database;
    return await db.insert('categories', {'name': name, 'type': type});
  }

  Future<void> updateCategory(int id, String newName) async {
    Database db = await database;
    await db.update('categories', {'name': newName}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCategory(int id) async {
    Database db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD TRANSAKSI ---
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('transactions', row);
  }

  // === FIX SORTING DISINI ===
  // Ditambah ", id DESC" biar dalam tanggal yang sama, yang inputnya belakangan (ID gede) ada di atas
  Future<List<Map<String, dynamic>>> getTransactions() async {
    Database db = await database;
    return await db.query('transactions', orderBy: "date DESC, id DESC");
  }

  Future<void> deleteTransactionWithRefund(int id) async {
    Database db = await database;
    List<Map> trans = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    
    if (trans.isNotEmpty) {
      var item = trans.first;
      int amount = item['amount'] as int;
      int accountId = item['account_id'] as int;
      String type = item['type'];

      int refundAmount = (type == 'Expense') ? amount : (amount * -1);
      await updateAccountBalance(accountId, refundAmount);
      await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> updateTransactionWithLogic(int id, Map<String, dynamic> newRow) async {
    Database db = await database;
    List<Map> oldTrans = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (oldTrans.isNotEmpty) {
      var oldItem = oldTrans.first;
      int oldAmount = oldItem['amount'] as int;
      int oldAccountId = oldItem['account_id'] as int;
      String oldType = oldItem['type'];

      int refundAmount = (oldType == 'Expense') ? oldAmount : (oldAmount * -1);
      await updateAccountBalance(oldAccountId, refundAmount);

      await db.update('transactions', newRow, where: 'id = ?', whereArgs: [id]);

      int newAmount = newRow['amount'];
      int newAccountId = newRow['account_id'];
      String newType = newRow['type'];

      int applyAmount = (newType == 'Expense') ? (newAmount * -1) : newAmount;
      await updateAccountBalance(newAccountId, applyAmount);
    }
  }

  // --- CRUD AKUN ---
  Future<int> insertAccount(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('accounts', row);
  }

  Future<void> updateAccount(int id, Map<String, dynamic> row) async {
    Database db = await database;
    await db.update('accounts', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAccounts() async {
    Database db = await database;
    return await db.query('accounts');
  }

  Future<void> updateAccountBalance(int accountId, int amount) async {
    Database db = await database;
    List<Map> result = await db.query('accounts', where: 'id = ?', whereArgs: [accountId]);
    if (result.isNotEmpty) {
      int currentBalance = result.first['balance'] as int;
      int newBalance = currentBalance + amount;
      await db.update('accounts', {'balance': newBalance}, where: 'id = ?', whereArgs: [accountId]);
    }
  }

  Future<void> deleteAccount(int id) async {
    Database db = await database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // === FIX SORTING DETAIL AKUN JUGA ===
  Future<List<Map<String, dynamic>>> getTransactionsByAccount(int accountId) async {
    Database db = await database;
    return await db.query('transactions', where: 'account_id = ?', whereArgs: [accountId], orderBy: "date DESC, id DESC");
  }
}