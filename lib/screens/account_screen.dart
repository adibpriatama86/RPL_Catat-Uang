import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prototype_catat_uang/database/database_helper.dart';
import 'package:prototype_catat_uang/screens/add_account_screen.dart';
import 'package:prototype_catat_uang/screens/account_detail_screen.dart'; // IMPORT SCREEN BARU

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

  void _loadAccounts() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper().getAccounts();
    int total = 0;
    for (var acc in data) {
      total += (acc['balance'] as int);
    }
    setState(() {
      _accounts = data;
      _totalBalance = total;
      _isLoading = false;
    });
  }

  String formatRupiah(int amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);

  IconData _getIcon(String type) {
    switch (type) {
      case 'Cash': return Icons.wallet;
      case 'Bank': return Icons.account_balance;
      case 'E-Wallet': return Icons.phone_android;
      default: return Icons.attach_money;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'Cash': return Colors.green;
      case 'Bank': return Colors.blue;
      case 'E-Wallet': return Colors.orange;
      default: return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Saldo", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text(formatRupiah(_totalBalance), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),

            // LIST AKUN
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _accounts.isEmpty 
                  ? const Center(child: Text("Belum ada akun. Tambahin dulu bro!", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _accounts.length,
                      itemBuilder: (context, index) {
                        final acc = _accounts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                          // INKWELL: KLIK = DETAIL, TAHAN = HAPUS
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            // 1. KLIK: Buka Detail
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AccountDetailScreen(account: acc),
                                ),
                              );
                            },
                            // 2. TAHAN: Hapus Akun
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Hapus Akun?"),
                                    content: Text("Yakin mau hapus akun '${acc['name']}'?"),
                                    actions: [
                                      TextButton(child: const Text("Batal"), onPressed: () => Navigator.pop(context)),
                                      TextButton(
                                        child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await DatabaseHelper().deleteAccount(acc['id']);
                                          _loadAccounts();
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Akun berhasil dihapus.")));
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: _getColor(acc['type']).withOpacity(0.1), child: Icon(_getIcon(acc['type']), color: _getColor(acc['type']))),
                              title: Text(acc['name'], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                              subtitle: Text(acc['type'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              trailing: Text(formatRupiah(acc['balance']), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddAccountScreen())).then((value) {
            if (value == true) _loadAccounts(); 
          });
        },
        backgroundColor: const Color(0xFFFF6B6B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Akun Baru", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}