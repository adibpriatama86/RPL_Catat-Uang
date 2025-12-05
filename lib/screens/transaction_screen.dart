import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prototype_catat_uang/database/database_helper.dart';
import 'package:prototype_catat_uang/screens/insert_transaction_screen.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => TransactionPageState();
}

class TransactionPageState extends State<TransactionPage> {
  String _selectedFilter = 'Harian'; 
  DateTime _focusedDate = DateTime.now(); 
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  int _totalIncome = 0;
  int _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + offset);
      _isLoading = true;
    });
    refreshData();
  }

  void refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await DatabaseHelper().getTransactions();
    
    List<Map<String, dynamic>> filteredData = [];
    int inc = 0;
    int exp = 0;
    String currentMonthStr = DateFormat('yyyy-MM').format(_focusedDate);

    for (var item in data) {
      if (item['date'].toString().startsWith(currentMonthStr)) {
        filteredData.add(item);
        if (item['type'] == 'Income') inc += (item['amount'] as int);
        else exp += (item['amount'] as int);
      }
    }
    setState(() {
      _transactions = filteredData;
      _totalIncome = inc;
      _totalExpense = exp;
      _isLoading = false;
    });
  }

  String formatRupiah(int amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  String getDay(String dateStr) => DateFormat('dd').format(DateTime.parse(dateStr));
  String getDayName(String dateStr) => DateFormat('E').format(DateTime.parse(dateStr));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left, color: Colors.black87), onPressed: () => _changeMonth(-1)),
                    Text(DateFormat('MMMM yyyy').format(_focusedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    IconButton(icon: const Icon(Icons.chevron_right, color: Colors.black87), onPressed: () => _changeMonth(1)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ["Harian", "Bulanan"].map((filter) {
                    bool isActive = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(color: isActive ? const Color(0xFFFF6B6B) : Colors.grey[100], borderRadius: BorderRadius.circular(20), border: isActive ? null : Border.all(color: Colors.grey.shade300)),
                        child: Text(filter, style: TextStyle(color: isActive ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Income", style: TextStyle(color: Colors.grey, fontSize: 12)), Text(formatRupiah(_totalIncome), style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold))]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("Expense", style: TextStyle(color: Colors.grey, fontSize: 12)), Text(formatRupiah(_totalExpense), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))]),
                  ],
                )
              ],
            ),
          ),
          // BODY
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _transactions.isEmpty 
                ? Center(child: Text("Belum ada transaksi", style: TextStyle(color: Colors.grey[400])))
                : _selectedFilter == 'Harian' ? _buildDailyView() : _buildMonthlyView(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyView() {
    Map<String, List<Map<String, dynamic>>> groupedTransactions = {};
    for (var tr in _transactions) {
      String date = tr['date'];
      if (!groupedTransactions.containsKey(date)) groupedTransactions[date] = [];
      groupedTransactions[date]!.add(tr);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: groupedTransactions.keys.length,
      itemBuilder: (context, index) {
        String dateKey = groupedTransactions.keys.elementAt(index);
        List<Map<String, dynamic>> dailyTrans = groupedTransactions[dateKey]!;
        int dailyTotal = 0;
        for(var t in dailyTrans) {
           if(t['type'] == 'Expense') dailyTotal -= (t['amount'] as int); else dailyTotal += (t['amount'] as int);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [Text(getDay(dateKey), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)), child: Text(getDayName(dateKey), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)))]),
                  Text(formatRupiah(dailyTotal), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ...dailyTrans.map((trx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  // === INTERAKSI BARU ===
                  
                  // 1. KLIK BIASA = EDIT
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => InsertTransactionScreen(transactionToEdit: trx))
                    ).then((value) {
                      if(value == true) refreshData();
                    });
                  },

                  // 2. TAHAN LAMA = HAPUS
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Hapus Transaksi?"),
                          content: Text("Yakin mau hapus '${trx['name']}'? Saldo bakal dikembaliin."),
                          actions: [
                            TextButton(child: const Text("Batal"), onPressed: () => Navigator.of(context).pop()),
                            TextButton(
                              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                              onPressed: () async {
                                Navigator.of(context).pop(); 
                                await DatabaseHelper().deleteTransactionWithRefund(trx['id']);
                                refreshData();
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaksi dihapus.")));
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: trx['type'] == 'Expense' ? Colors.red.withOpacity(0.1) : Colors.teal.withOpacity(0.1), child: Icon(trx['type'] == 'Expense' ? Icons.arrow_downward : Icons.arrow_upward, color: trx['type'] == 'Expense' ? Colors.red : Colors.teal, size: 20)),
                    title: Text(trx['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    subtitle: Text(trx['category'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: Text(formatRupiah(trx['amount']), style: TextStyle(color: trx['type'] == 'Expense' ? Colors.redAccent : Colors.teal, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }),
            const SizedBox(height: 5),
          ],
        );
      },
    );
  }

  Widget _buildMonthlyView() {
    Map<String, int> categorySummary = {};
    for (var tr in _transactions) {
      String cat = tr['category'];
      int amt = tr['amount'] as int;
      if(tr['type'] == 'Income') continue; 
      if (!categorySummary.containsKey(cat)) categorySummary[cat] = 0;
      categorySummary[cat] = categorySummary[cat]! + amt;
    }
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: categorySummary.length,
      itemBuilder: (context, index) {
        String cat = categorySummary.keys.elementAt(index);
        int amount = categorySummary[cat]!;
        return Card(elevation: 0, color: Colors.grey[50], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.category, color: Colors.grey)), title: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), trailing: Text(formatRupiah(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))));
      },
    );
  }
}