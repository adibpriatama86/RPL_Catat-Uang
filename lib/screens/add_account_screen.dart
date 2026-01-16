import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:prototype_catat_uang/database/database_helper.dart';
import 'package:prototype_catat_uang/screens/insert_transaction_screen.dart'; // CurrencyInputFormatter

class AddAccountScreen extends StatefulWidget {
  final Map<String, dynamic>? accountToEdit;

  const AddAccountScreen({super.key, this.accountToEdit});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _typeController = TextEditingController(text: 'Cash');

  bool _isEditMode = false;
  int _oldBalance = 0;

  @override
  void initState() {
    super.initState();
    if (widget.accountToEdit != null) {
      _isEditMode = true;
      _nameController.text = widget.accountToEdit!['name'];
      _typeController.text = widget.accountToEdit!['type'];
      _oldBalance = widget.accountToEdit!['balance'];

      _balanceController.text = NumberFormat.currency(
        locale: 'id',
        symbol: '',
        decimalDigits: 0,
      ).format(_oldBalance);
    }
  }

  // =========================
  // TYPE PICKER
  // =========================
  void _showTypePicker(bool isDark) {
    final types = ['Cash', 'Bank', 'E-Wallet', 'Investment'];
    final icons = [
      Icons.wallet,
      Icons.account_balance,
      Icons.phone_android,
      Icons.trending_up
    ];
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pilih Tipe Akun",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: types.length,
                itemBuilder: (_, i) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _typeController.text = types[i]);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors[i].withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors[i]),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icons[i], color: colors[i]),
                          const SizedBox(width: 8),
                          Text(
                            types[i],
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors[i]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // SAVE ACCOUNT
  // =========================
  Future<void> _saveAccount() async {
    HapticFeedback.mediumImpact();
    if (!_formKey.currentState!.validate()) return;

    final newBalance =
        int.parse(_balanceController.text.replaceAll('.', ''));

    final row = {
      'name': _nameController.text,
      'type': _typeController.text,
      'balance': newBalance,
    };

    if (_isEditMode) {
      await DatabaseHelper()
          .updateAccount(widget.accountToEdit!['id'], row);

      final diff = newBalance - _oldBalance;
      if (diff != 0) {
        await DatabaseHelper().insertTransaction({
          'name': 'Koreksi Saldo (${_nameController.text})',
          'category': 'Lainnya',
          'amount': diff.abs(),
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'type': diff > 0 ? 'Income' : 'Expense',
          'account_id': widget.accountToEdit!['id'],
        });
      }
    } else {
      final newId = await DatabaseHelper().insertAccount(row);
      if (newBalance > 0) {
        await DatabaseHelper().insertTransaction({
          'name': 'Saldo Awal ${_nameController.text}',
          'category': 'Lainnya',
          'amount': newBalance,
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'type': 'Income',
          'account_id': newId,
        });
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  // =========================
  // INPUT DECORATION
  // =========================
  InputDecoration _inputDeco(
      String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor:
          isDark ? Colors.grey[850] : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditMode ? "Edit Akun" : "Tambah Akun",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration:
                    _inputDeco("Nama Akun", Icons.label_outline, isDark),
                validator: (v) =>
                    v!.isEmpty ? 'Nama harus diisi' : null,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _typeController,
                readOnly: true,
                decoration: _inputDeco(
                        "Tipe Akun", Icons.category_outlined, isDark)
                    .copyWith(
                        suffixIcon:
                            const Icon(Icons.arrow_drop_down)),
                onTap: () => _showTypePicker(isDark),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter()
                ],
                decoration: _inputDeco(
                    "Saldo Saat Ini", Icons.monetization_on_outlined, isDark),
                validator: (v) =>
                    v!.isEmpty ? 'Saldo harus diisi' : null,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
                    _isEditMode ? "Update Akun" : "Simpan Akun",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}