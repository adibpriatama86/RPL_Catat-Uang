import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:prototype_catat_uang/database/database_helper.dart';

class AccountDetailScreen extends StatefulWidget {
  final Map<String, dynamic> account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() =>
      _AccountDetailScreenState();
}

class _AccountDetailScreenState
    extends State<AccountDetailScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DatabaseHelper()
        .getTransactionsByAccount(widget.account['id']);
    setState(() {
      _transactions = data;
      _isLoading = false;
    });
  }

  String formatRupiah(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor =
        isDark ? Colors.white : Colors.black87;
    final subTextColor =
        isDark ? Colors.grey[400]! : Colors.grey;

    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.account['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // =========================
          // SUMMARY SALDO
          // =========================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                Text(
                  "Sisa Saldo",
                  style: TextStyle(color: subTextColor),
                ),
                const SizedBox(height: 5),
                Text(
                  formatRupiah(widget.account['balance']),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // =========================
          // LIST TRANSAKSI
          // =========================
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? Center(
                        child: Text(
                          "Belum ada transaksi di ${widget.account['name']}",
                          style:
                              TextStyle(color: subTextColor),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(16),
                        itemCount:
                            _transactions.length,
                        itemBuilder: (context, index) {
                          final trx =
                              _transactions[index];
                          final isExpense =
                              trx['type'] == 'Expense';

                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 8),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius:
                                  BorderRadius.circular(
                                      12),
                              border: isDark
                                  ? null
                                  : Border.all(
                                      color: Colors
                                          .grey.shade200),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isExpense
                                    ? Colors.red
                                        .withOpacity(0.1)
                                    : Colors.teal
                                        .withOpacity(0.1),
                                child: Icon(
                                  isExpense
                                      ? Icons
                                          .arrow_downward
                                      : Icons
                                          .arrow_upward,
                                  color: isExpense
                                      ? Colors.red
                                      : Colors.teal,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                trx['name'],
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              subtitle: Text(
                                trx['date'],
                                style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 12),
                              ),
                              trailing: Text(
                                formatRupiah(
                                    trx['amount']),
                                style: TextStyle(
                                  color: isExpense
                                      ? Colors.redAccent
                                      : Colors.teal,
                                  fontWeight:
                                      FontWeight.bold,
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