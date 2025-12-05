import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prototype_catat_uang/database/database_helper.dart';

class InsertTransactionScreen extends StatefulWidget {
  // Tambahin parameter ini buat nangkep data yang mau diedit
  final Map<String, dynamic>? transactionToEdit;

  const InsertTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<InsertTransactionScreen> createState() => _InsertTransactionScreenState();
}

class _InsertTransactionScreenState extends State<InsertTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  
  String _type = 'Expense'; 
  String? _category;
  DateTime _selectedDate = DateTime.now();
  int? _selectedAccountId;
  List<Map<String, dynamic>> _accountList = []; 

  final List<String> _categories = ['Food', 'Transport', 'Entertainment', 'Salary', 'Kost', 'Household', 'Accessories', 'Internet', 'Skin&Body Care', 'Other'];

  bool _isEditMode = false; // Penanda mode edit

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    
    // CEK: Apakah ini mode Edit?
    if (widget.transactionToEdit != null) {
      _isEditMode = true;
      _nameController.text = widget.transactionToEdit!['name'];
      _amountController.text = widget.transactionToEdit!['amount'].toString();
      _dateController.text = widget.transactionToEdit!['date'];
      _type = widget.transactionToEdit!['type'];
      _category = widget.transactionToEdit!['category'];
      _selectedAccountId = widget.transactionToEdit!['account_id'];
      _selectedDate = DateTime.parse(widget.transactionToEdit!['date']);
    } else {
      _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  void _loadAccounts() async {
    final data = await DatabaseHelper().getAccounts();
    setState(() {
      _accountList = data;
      // Kalau mode Create (bukan Edit) dan belum milih akun, pilih yang pertama default
      if (!_isEditMode && _selectedAccountId == null && data.isNotEmpty) {
        _selectedAccountId = data.first['id'];
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih akun dulu bro!')));
        return;
      }

      int amount = int.parse(_amountController.text);

      Map<String, dynamic> row = {
        'name': _nameController.text,
        'category': _category ?? 'Other',
        'amount': amount,
        'date': _dateController.text,
        'type': _type,
        'account_id': _selectedAccountId,
      };
      
      if (_isEditMode) {
        // === LOGIC UPDATE (EDIT) ===
        await DatabaseHelper().updateTransactionWithLogic(widget.transactionToEdit!['id'], row);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil diupdate!')));
      } else {
        // === LOGIC INSERT (BARU) ===
        await DatabaseHelper().insertTransaction(row);
        int changeAmount = (_type == 'Expense') ? (amount * -1) : amount;
        await DatabaseHelper().updateAccountBalance(_selectedAccountId!, changeAmount);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  InputDecoration _modernInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditMode ? "Edit Transaksi" : "Tambah Transaksi", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.shade300)),
                child: Row(children: [_buildTypeButton("Income", Colors.teal), _buildTypeButton("Expense", Colors.redAccent)]),
              ),
              const SizedBox(height: 25),
              DropdownButtonFormField<int>(
                value: _selectedAccountId,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                decoration: _modernInputDecoration("Sumber Dana", Icons.account_balance_wallet),
                items: _accountList.map((account) {
                  return DropdownMenuItem<int>(
                    value: account['id'],
                    child: Text("${account['name']} (Rp ${account['balance']})"),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
              ),
              const SizedBox(height: 20),
              TextFormField(controller: _nameController, decoration: _modernInputDecoration("Judul Transaksi", Icons.edit), validator: (val) => val!.isEmpty ? 'Isi dulu' : null),
              const SizedBox(height: 20),
              TextFormField(controller: _amountController, keyboardType: TextInputType.number, decoration: _modernInputDecoration("Nominal (Rp)", Icons.monetization_on), validator: (val) => val!.isEmpty ? 'Isi dulu' : null),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _category,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                decoration: _modernInputDecoration("Kategori", Icons.category),
                items: _categories.map((String category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                onChanged: (val) => setState(() => _category = val),
              ),
              const SizedBox(height: 20),
              TextFormField(controller: _dateController, readOnly: true, decoration: _modernInputDecoration("Tanggal", Icons.calendar_month), onTap: () => _selectDate(context)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(backgroundColor: _type == 'Expense' ? const Color(0xFFFF6B6B) : Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: Text(_isEditMode ? "Update Transaksi" : "Simpan Transaksi", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, Color color) {
    bool isSelected = _type == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(25), boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : []),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: isSelected ? color : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}