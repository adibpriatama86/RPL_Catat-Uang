import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prototype_catat_uang/database/database_helper.dart';

class AccountDetailScreen extends StatefulWidget {
  final Map<String, dynamic> account; // Data akun (Nama, ID, Saldo)

  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final data = await DatabaseHelper().getTransactionsByAccount(widget.account['id']);
    setState(() {
      _transactions = data;
      _isLoading = false;
    });
  }

  String formatRupiah(int amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  String getDay(String dateStr) => DateFormat('dd').format(DateTime.parse(dateStr));
  String getDayName(String dateStr) => DateFormat('E').format(DateTime.parse(dateStr));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.account['name'], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context), // Balik ke halaman sebelumnya
        ),
      ),
      body: Column(
        children: [
          // SUMMARY KECIL DI ATAS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                const Text("Sisa Saldo", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 5),
                // Note: Ini saldo statis pas diklik. Kalo mau realtime harus query ulang akunnya.
                // Tapi buat skrg cukup pake data yg dipassing.
                Text(formatRupiah(widget.account['balance']), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // LIST TRANSAKSI
          Expanded(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : _transactions.isEmpty 
              ? Center(child: Text("Belum ada transaksi di ${widget.account['name']}", style: const TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    var trx = _transactions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: trx['type'] == 'Expense' ? Colors.red.withOpacity(0.1) : Colors.teal.withOpacity(0.1),
                          child: Icon(
                            trx['type'] == 'Expense' ? Icons.arrow_downward : Icons.arrow_upward,
                            color: trx['type'] == 'Expense' ? Colors.red : Colors.teal, 
                            size: 20
                          ),
                        ),
                        title: Text(trx['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        subtitle: Text(trx['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: Text(
                          formatRupiah(trx['amount']),
                          style: TextStyle(
                            color: trx['type'] == 'Expense' ? Colors.redAccent : Colors.teal,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}