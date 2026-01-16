import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';

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
    initializeDateFormatting('id_ID', null).then((_) {
      refreshData();
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + offset);
      _isLoading = true;
    });
    refreshData();
  }

  Future<void> refreshData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    final data = await DatabaseHelper().getTransactions();

    final currentMonth = DateFormat('yyyy-MM').format(_focusedDate);

    int income = 0;
    int expense = 0;
    List<Map<String, dynamic>> filtered = [];

    for (var trx in data) {
      if (trx['date'].toString().startsWith(currentMonth)) {
        filtered.add(trx);
        if (trx['type'] == 'Income') {
          income += trx['amount'] as int;
        } else {
          expense += trx['amount'] as int;
        }
      }
    }

    setState(() {
      _transactions = filtered;
      _totalIncome = income;
      _totalExpense = expense;
      _isLoading = false;
    });
  }

  // =======================
  // HELPERS
  // =======================

  String formatRupiah(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String getDay(String dateStr) =>
      DateFormat('dd').format(DateTime.parse(dateStr));

  String getDayName(String dateStr) =>
      DateFormat('EEEE', 'id_ID').format(DateTime.parse(dateStr));

  // =======================
  // BUILD
  // =======================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey;

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(isDark, cardColor, textColor, subTextColor),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? _buildEmptyState(subTextColor)
                    : _selectedFilter == 'Harian'
                        ? _buildDailyView(
                            isDark,
                            cardColor,
                            textColor,
                            subTextColor,
                          )
                        : _buildMonthlyView(cardColor, textColor),
          ),
        ],
      ),
    );
  }

  // =======================
  // HEADER
  // =======================

  Widget _buildHeader(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: textColor),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                DateFormat('MMMM yyyy', 'id_ID').format(_focusedDate),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: textColor),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ["Harian", "Bulanan"].map((filter) {
              final isActive = _selectedFilter == filter;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFF6B6B)
                        : isDark
                            ? Colors.grey[800]
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isActive ? Colors.white : subTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pemasukan",
                      style: TextStyle(color: subTextColor, fontSize: 12)),
                  Text(formatRupiah(_totalIncome),
                      style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Pengeluaran",
                      style: TextStyle(color: subTextColor, fontSize: 12)),
                  Text(formatRupiah(_totalExpense),
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =======================
  // EMPTY STATE
  // =======================

  Widget _buildEmptyState(Color subTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/empty.json', width: 180, height: 180),
          const SizedBox(height: 10),
          Text(
            "Belum ada transaksi nih...",
            style: TextStyle(color: subTextColor),
          ),
        ],
      ),
    );
  }

  // =======================
  // DAILY VIEW
  // =======================

  Widget _buildDailyView(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var trx in _transactions) {
      grouped.putIfAbsent(trx['date'], () => []);
      grouped[trx['date']]!.add(trx);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dailyTrans = grouped[dateKey]!;

        int dailyIncome = 0;
        int dailyExpense = 0;

        for (var t in dailyTrans) {
          if (t['type'] == 'Income') {
            dailyIncome += t['amount'] as int;
          } else {
            dailyExpense += t['amount'] as int;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        getDay(dateKey),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          getDayName(dateKey),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (dailyIncome > 0)
                        Text(
                          "+ ${formatRupiah(dailyIncome)}",
                          style: const TextStyle(
                              color: Colors.teal,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      if (dailyExpense > 0)
                        Text(
                          "- ${formatRupiah(dailyExpense)}",
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            ...dailyTrans.map((trx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: isDark
                      ? null
                      : Border.all(color: Colors.grey.shade100),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            InsertTransactionScreen(transactionToEdit: trx),
                      ),
                    ).then((value) {
                      if (value == true) refreshData();
                    });
                  },
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    _showDeleteDialog(trx);
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: trx['type'] == 'Expense'
                          ? Colors.red.withOpacity(0.1)
                          : Colors.teal.withOpacity(0.1),
                      child: Icon(
                        trx['type'] == 'Expense'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: trx['type'] == 'Expense'
                            ? Colors.red
                            : Colors.teal,
                      ),
                    ),
                    title: Text(
                      trx['name'],
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: textColor),
                    ),
                    subtitle: Text(
                      trx['category'],
                      style:
                          TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    trailing: Text(
                      formatRupiah(trx['amount']),
                      style: TextStyle(
                        color: trx['type'] == 'Expense'
                            ? Colors.redAccent
                            : Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

  // =======================
  // MONTHLY VIEW
  // =======================

  Widget _buildMonthlyView(Color cardColor, Color textColor) {
    final Map<String, int> summary = {};

    for (var trx in _transactions) {
      if (trx['type'] == 'Income') continue;
      summary[trx['category']] =
          (summary[trx['category']] ?? 0) + trx['amount'] as int;
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: summary.length,
      itemBuilder: (context, index) {
        final cat = summary.keys.elementAt(index);
        final amount = summary[cat]!;

        return Card(
          elevation: 0,
          color: cardColor,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.category, color: Colors.grey),
            ),
            title: Text(
              cat,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: textColor),
            ),
            trailing: Text(
              formatRupiah(amount),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent),
            ),
          ),
        );
      },
    );
  }

  // =======================
  // DELETE DIALOG
  // =======================

  void _showDeleteDialog(Map<String, dynamic> trx) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Transaksi?"),
        content: Text(
          "Yakin mau hapus '${trx['name']}'?\nSaldo bakal dikembaliin.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
              await DatabaseHelper()
                  .deleteTransactionWithRefund(trx['id']);
              refreshData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Transaksi dihapus.")),
              );
            },
            child: const Text(
              "Hapus",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
