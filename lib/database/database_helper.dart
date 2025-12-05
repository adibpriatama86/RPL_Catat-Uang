import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Singleton pattern biar koneksinya cuma satu aja di seluruh app
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
    // Nentuin lokasi file database di HP (data_keuangan.db)
    String path = join(await getDatabasesPath(), 'catat_duit.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Bikin Tabel pas pertama kali install
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

    // 2. Tabel Akun (YANG BARU)
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        type TEXT, 
        balance INTEGER
      )
    ''');
  }

  // --- FITUR CRUD (Create, Read, Update, Delete) ---

  // 1. Tambah Data (Insert)
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('transactions', row);
  }

  // 2. Ambil Semua Data (Read)
  Future<List<Map<String, dynamic>>> getTransactions() async {
    Database db = await database;
    // Order by date descending (terbaru di atas)
    return await db.query('transactions', orderBy: "date DESC");
  }

  // 3. Hapus Data
  Future<int> deleteTransaction(int id) async {
    Database db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
  
  // 4. Update Data
  Future<int> updateTransaction(Map<String, dynamic> row) async {
    Database db = await database;
    int id = row['id'];
    return await db.update('transactions', row, where: 'id = ?', whereArgs: [id]);
  }

  // Tambah Akun Baru
  Future<int> insertAccount(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('accounts', row);
  }

  // Ambil Semua Akun
  Future<List<Map<String, dynamic>>> getAccounts() async {
    Database db = await database;
    return await db.query('accounts');
  }

  // 2. TAMBAH FUNGSI UPDATE SALDO
  // Fungsi ini bakal dipanggil pas kita simpan transaksi
  Future<void> updateAccountBalance(int accountId, int amount) async {
    Database db = await database;
    
    // Ambil saldo sekarang dulu
    List<Map> result = await db.query('accounts', where: 'id = ?', whereArgs: [accountId]);
    
    if (result.isNotEmpty) {
      int currentBalance = result.first['balance'] as int;
      int newBalance = currentBalance + amount; // amount bisa minus (expense) atau plus (income)
      
      // Update saldo baru ke database
      await db.update(
        'accounts', 
        {'balance': newBalance}, 
        where: 'id = ?', 
        whereArgs: [accountId]
      );
    }
  }

  // Hapus Transaksi + Balikin Saldo (SMART DELETE)
  Future<void> deleteTransactionWithRefund(int id) async {
    Database db = await database;

    // 1. Ambil detail transaksi dulu sebelum dihapus (biar tau nominal & akunnya)
    List<Map> trans = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    
    if (trans.isNotEmpty) {
      var item = trans.first;
      int amount = item['amount'] as int;
      int accountId = item['account_id'] as int;
      String type = item['type'];

      // 2. Hitung Refund (Kebalikan dari logic Insert)
      // Kalo Expense dihapus, saldonya DITAMBAH balik. Kalo Income dihapus, saldonya DIKURANGI.
      int refundAmount = (type == 'Expense') ? amount : (amount * -1);

      // 3. Update Saldo Akun
      await updateAccountBalance(accountId, refundAmount);

      // 4. Baru deh hapus transaksinya
      await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    }
  }

  // === FITUR EDIT (UPDATE) SAKTI ===
  Future<void> updateTransactionWithLogic(int id, Map<String, dynamic> newRow) async {
    Database db = await database;

    // 1. Ambil Data LAMA
    List<Map> oldTrans = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (oldTrans.isNotEmpty) {
      var oldItem = oldTrans.first;
      int oldAmount = oldItem['amount'] as int;
      int oldAccountId = oldItem['account_id'] as int;
      String oldType = oldItem['type'];

      // 2. Balikin Saldo LAMA (Refund)
      // Kalau dulu Expense, balikin duitnya. Kalau dulu Income, tarik duitnya.
      int refundAmount = (oldType == 'Expense') ? oldAmount : (oldAmount * -1);
      await updateAccountBalance(oldAccountId, refundAmount);

      // 3. Update Data Transaksi di Database
      await db.update('transactions', newRow, where: 'id = ?', whereArgs: [id]);

      // 4. Potong Saldo BARU (Apply New)
      int newAmount = newRow['amount'];
      int newAccountId = newRow['account_id'];
      String newType = newRow['type'];

      // Kalau sekarang Expense, potong lagi. Kalau Income, tambah lagi.
      int applyAmount = (newType == 'Expense') ? (newAmount * -1) : newAmount;
      await updateAccountBalance(newAccountId, applyAmount);
    }
  }

  // FITUR BARU: Hapus Akun
  // Note: Hati-hati, kalo akun dihapus, transaksi yg nyangkut di akun ini
  // idealnya ikut kehapus atau dipindahin. Tapi buat skrg kita hapus akunnya aja.
  Future<void> deleteAccount(int id) async {
    Database db = await database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getTransactionsByAccount(int accountId) async {
    Database db = await database;
    // Ambil data transaksi where account_id = ID yang dipilih, urutkan tanggal terbaru
    return await db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: "date DESC"
    );
  }
}