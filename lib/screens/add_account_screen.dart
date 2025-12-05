import 'package:flutter/material.dart';
import 'package:prototype_catat_uang/database/database_helper.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(); 
  String _selectedType = 'Cash'; 

  final List<String> _types = ['Cash', 'Bank', 'E-Wallet', 'Investment'];

  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> row = {
        'name': _nameController.text,
        'type': _selectedType,
        'balance': int.parse(_balanceController.text),
      };

      await DatabaseHelper().insertAccount(row);

      if (!mounted) return;
      Navigator.pop(context, true); 
    }
  }

  // Helper Style biar Rounded & Modern (Sama kayak Insert Transaction)
  InputDecoration _modernInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey), 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), // INI RAHASIANYA
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
      ),
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
        title: const Text("Tambah Akun", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0), // Padding digedein dikit biar lega
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Nama Akun
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black87), 
                decoration: _modernInputDecoration("Nama Akun", Icons.label_outline),
                validator: (val) => val!.isEmpty ? 'Nama harus diisi' : null,
              ),
              const SizedBox(height: 20),

              // 2. Tipe Akun
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: Colors.white, 
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                decoration: _modernInputDecoration("Tipe Akun", Icons.category_outlined),
                items: _types.map((String type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 20),

              // 3. Saldo Awal
              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black87), 
                decoration: _modernInputDecoration("Saldo Saat Ini", Icons.monetization_on_outlined),
                validator: (val) => val!.isEmpty ? 'Saldo harus diisi' : null,
              ),
              const SizedBox(height: 40),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Tombol juga rounded 15
                    elevation: 3,
                  ),
                  child: const Text("Simpan Akun", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}