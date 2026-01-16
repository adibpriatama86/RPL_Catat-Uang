import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import 'package:prototype_catat_uang/database/database_helper.dart';
import 'package:prototype_catat_uang/screens/add_account_screen.dart';
import 'package:prototype_catat_uang/screens/account_detail_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;
  int _totalBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);

    final data = await DatabaseHelper().getAccounts();
    int total = 0;
    for (var acc in data) {
      total += acc['balance'] as int;
    }

    setState(() {
      _accounts = data;
      _totalBalance = total;
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

  IconData _getIcon(String type) {
    switch (type) {
      case 'Cash':
        return Icons.wallet;
      case 'Bank':
        return Icons.account_balance;
      case 'E-Wallet':
        return Icons.phone_android;
      default:
        return Icons.attach_money;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'Cash':
        return Colors.green;
      case 'Bank':
        return Colors.blue;
      case 'E-Wallet':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  void _confirmDelete(Map<String, dynamic> acc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Akun?"),
        content: Text(
          "Yakin mau hapus akun '${acc['name']}'?\nTransaksi terkait mungkin jadi error.",
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
              await DatabaseHelper().deleteAccount(acc['id']);
              _loadAccounts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Akun berhasil dihapus.")),
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

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total Saldo", style: TextStyle(color: subTextColor)),
                  const SizedBox(height: 5),
                  Text(
                    formatRupiah(_totalBalance),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            // LIST
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _accounts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset(
                                'assets/empty.json',
                                width: 200,
                                height: 200,
                              ),
                              Text(
                                "Belum ada akun. Tambahin dulu yuk!",
                                style: TextStyle(color: subTextColor),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _accounts.length,
                          itemBuilder: (context, index) {
                            final acc = _accounts[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: isDark
                                    ? null
                                    : Border.all(
                                        color: Colors.grey.shade200),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AccountDetailScreen(
                                        account: acc,
                                      ),
                                    ),
                                  );
                                },
                                onLongPress: () {
                                  HapticFeedback.lightImpact();
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: cardColor,
                                    shape:
                                        const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.vertical(
                                              top:
                                                  Radius.circular(20)),
                                    ),
                                    builder: (_) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.all(10),
                                        child: Column(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 4,
                                              margin: const EdgeInsets.only(
                                                  bottom: 20),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        10),
                                              ),
                                            ),

                                            ListTile(
                                              leading: const Icon(
                                                  Icons.edit,
                                                  color: Colors.blue),
                                              title: Text(
                                                "Edit Akun",
                                                style: TextStyle(
                                                    color: textColor),
                                              ),
                                              onTap: () {
                                                HapticFeedback
                                                    .selectionClick();
                                                Navigator.pop(context);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        AddAccountScreen(
                                                      accountToEdit:
                                                          acc,
                                                    ),
                                                  ),
                                                ).then((value) {
                                                  if (value == true) {
                                                    _loadAccounts();
                                                  }
                                                });
                                              },
                                            ),

                                            ListTile(
                                              leading: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red),
                                              title: const Text(
                                                "Hapus Akun",
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                              onTap: () {
                                                HapticFeedback
                                                    .selectionClick();
                                                Navigator.pop(context);
                                                _confirmDelete(acc);
                                              },
                                            ),

                                            const SizedBox(height: 10),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        _getColor(acc['type'])
                                            .withOpacity(0.1),
                                    child: Icon(
                                      _getIcon(acc['type']),
                                      color:
                                          _getColor(acc['type']),
                                    ),
                                  ),
                                  title: Text(
                                    acc['name'],
                                    style: TextStyle(
                                        color: textColor,
                                        fontWeight:
                                            FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    acc['type'],
                                    style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 12),
                                  ),
                                  trailing: Text(
                                    formatRupiah(acc['balance']),
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),

      // FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddAccountScreen(),
            ),
          ).then((value) {
            if (value == true) _loadAccounts();
          });
        },
        backgroundColor: const Color(0xFFFF6B6B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Akun Baru",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
