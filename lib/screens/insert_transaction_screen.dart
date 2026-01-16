import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:prototype_catat_uang/database/database_helper.dart';
import 'package:prototype_catat_uang/widgets/custom_switch.dart'; // Pastikan path ini bener

class InsertTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transactionToEdit;
  const InsertTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<InsertTransactionScreen> createState() =>
      _InsertTransactionScreenState();
}

class _InsertTransactionScreenState
    extends State<InsertTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _categoryController = TextEditingController();
  final _accountController = TextEditingController();

  String _type = 'Expense';
  DateTime _selectedDate = DateTime.now();
  int? _selectedAccountId;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      if (widget.transactionToEdit != null) {
        _isEditMode = true;
        final trx = widget.transactionToEdit!;
        _nameController.text = trx['name'];
        _amountController.text = NumberFormat.currency(
          locale: 'id',
          symbol: '',
          decimalDigits: 0,
        ).format(trx['amount']);
        _type = trx['type'];
        _categoryController.text = trx['category'];
        _selectedAccountId = trx['account_id'];
        _selectedDate = DateTime.parse(trx['date']);
        _dateController.text =
            DateFormat('EEEE, dd/MM/yyyy', 'id_ID')
                .format(_selectedDate);
        _loadAccountName(_selectedAccountId!);
      } else {
        _dateController.text =
            DateFormat('EEEE, dd/MM/yyyy', 'id_ID')
                .format(_selectedDate);
      }
    });
  }

  void _loadAccountName(int id) async {
    final accounts = await DatabaseHelper().getAccounts();
    final acc = accounts.firstWhere(
      (e) => e['id'] == id,
      orElse: () => {},
    );
    if (acc.isNotEmpty) {
      setState(() => _accountController.text = acc['name']);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            DateFormat('EEEE, dd/MM/yyyy', 'id_ID')
                .format(picked);
      });
    }
  }

  // ================= ACCOUNT PICKER =================
  void _showAccountPicker(bool isDark) async {
    final accounts = await DatabaseHelper().getAccounts();

    String saldo(int amount) => NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        ).format(amount);

    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pilih Sumber Dana",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
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
                  itemCount: accounts.length,
                  itemBuilder: (_, i) {
                    final acc = accounts[i];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedAccountId = acc['id'];
                          _accountController.text = acc['name'];
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              acc['name'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              saldo(acc['balance']),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey),
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
        );
      },
    );
  }

  // ================= CATEGORY PICKER =================
  void _showCategoryPicker(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return _CategoryGridSheet(
          type: _type,
          onCategorySelected: (c) {
            setState(() => _categoryController.text = c);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  // ================= SAVE =================
  Future<void> _saveTransaction() async {
    HapticFeedback.mediumImpact();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun dulu bro!')),
      );
      return;
    }

    final amount =
        int.parse(_amountController.text.replaceAll('.', ''));

    final row = {
      'name': _nameController.text,
      'category': _categoryController.text,
      'amount': amount,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'type': _type,
      'account_id': _selectedAccountId,
    };

    if (_isEditMode) {
      await DatabaseHelper().updateTransactionWithLogic(
        widget.transactionToEdit!['id'],
        row,
      );
    } else {
      await DatabaseHelper().insertTransaction(row);
      await DatabaseHelper().updateAccountBalance(
        _selectedAccountId!,
        _type == 'Expense' ? -amount : amount,
      );
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  // ================= INPUT DECORATION =================
  InputDecoration _inputDeco(
    String label,
    IconData icon,
    bool isDark,
  ) {
    final activeColor =
        _type == 'Income' ? Colors.teal : const Color(0xFFFF6B6B);

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),

      filled: true,
      fillColor:
          isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,

      // LABEL NORMAL (belum fokus)
      labelStyle: TextStyle(
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),

      // 🔥 LABEL SAAT FOCUS (INI YANG LU CARI)
      floatingLabelStyle: TextStyle(
        color: activeColor,
        fontWeight: FontWeight.w600,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
          width: 1,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: activeColor,
          width: 1.5,
        ),
      ),
    );
  }

  // ================= BUILD =================
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
        title: Text(_isEditMode ? "Edit" : "Tambah Transaksi"),
        foregroundColor: textColor,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // === GANTI BAGIAN SWITCH MANUAL DENGAN CUSTOM SWITCH ===
              CustomSwitch(
                currentType: _type,
                onChanged: (val) {
                  setState(() {
                    _type = val;
                    // Reset kategori saat ganti tipe (biar ga nyampur)
                    _categoryController.clear();
                  });
                },
              ),
              // =======================================================

              const SizedBox(height: 25),

              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration:
                    _inputDeco("Tanggal", Icons.calendar_month, isDark),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration:
                    _inputDeco("Judul Transaksi", Icons.edit, isDark),
                validator: (v) => v!.isEmpty ? 'Isi dulu' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter()
                ],
                decoration:
                    _inputDeco("Nominal (Rp)", Icons.payments, isDark),
                validator: (v) => v!.isEmpty ? 'Isi dulu' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _categoryController,
                readOnly: true,
                decoration: _inputDeco(
                        "Kategori", Icons.category, isDark)
                    .copyWith(
                        suffixIcon:
                            const Icon(Icons.arrow_drop_down)),
                onTap: () => _showCategoryPicker(isDark),
                validator: (v) =>
                    v!.isEmpty ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _accountController,
                readOnly: true,
                decoration: _inputDeco(
                        "Akun", Icons.account_balance_wallet, isDark)
                    .copyWith(
                        suffixIcon:
                            const Icon(Icons.arrow_drop_down)),
                onTap: () => _showAccountPicker(isDark),
                validator: (_) =>
                    _selectedAccountId == null ? 'Pilih akun' : null,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == 'Expense'
                        ? const Color(0xFFFF6B6B)
                        : Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
                    _isEditMode ? "Update" : "Simpan",
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
  
  // Fungsi _buildTypeButton sudah DIHAPUS karena diganti CustomSwitch
}

// ================= CATEGORY GRID (TIDAK DIUBAH) =================
class _CategoryGridSheet extends StatefulWidget {
  final String type;
  final Function(String) onCategorySelected;
  const _CategoryGridSheet(
      {required this.type, required this.onCategorySelected});

  @override
  State<_CategoryGridSheet> createState() =>
      _CategoryGridSheetState();
}

class _CategoryGridSheetState extends State<_CategoryGridSheet> {
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    final data =
        await DatabaseHelper().getCategories(widget.type);
    setState(() => _categories = data);
  }

  void _manageCategory(Map<String, dynamic>? category) {
    final controller =
        TextEditingController(text: category?['name'] ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text(category == null ? "Tambah Kategori" : "Edit Kategori"),
        content: TextField(controller: controller),
        actions: [
          if (category != null)
            TextButton(
              onPressed: () async {
                await DatabaseHelper().deleteCategory(category['id']);
                Navigator.pop(context);
                _loadCategories();
              },
              child:
                  const Text("Hapus", style: TextStyle(color: Colors.red)),
            ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                if (category == null) {
                  await DatabaseHelper()
                      .insertCategory(controller.text, widget.type);
                } else {
                  await DatabaseHelper()
                      .updateCategory(category['id'], controller.text);
                }
                Navigator.pop(context);
                _loadCategories();
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Pilih Kategori (${widget.type})",
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("Tahan lama untuk edit/hapus",
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.5,
              ),
              itemCount: _categories.length + 1,
              itemBuilder: (_, i) {
                if (i == _categories.length) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return GestureDetector(
                    onTap: () => _manageCategory(null),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2C)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.add,
                          color:
                              isDark ? Colors.white : Colors.black54),
                    ),
                  );
                }
                final cat = _categories[i];
                return GestureDetector(
                  onTap: () =>
                      widget.onCategorySelected(cat['name']),
                  onLongPress: () => _manageCategory(cat),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.type == 'Expense'
                          ? const Color(0xFFFF6B6B).withOpacity(0.1)
                          : Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.type == 'Expense'
                            ? const Color(0xFFFF6B6B)
                            : Colors.teal,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.type == 'Expense'
                            ? const Color(0xFFFF6B6B)
                            : Colors.teal,
                      ),
                      textAlign: TextAlign.center,
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    int value = int.parse(newValue.text.replaceAll('.', ''));
    final formatter = NumberFormat('#,###', 'id');
    String newText =
        formatter.format(value).replaceAll(',', '.');
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}