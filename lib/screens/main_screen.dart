import 'package:flutter/material.dart';
import 'package:prototype_catat_uang/screens/transaction_screen.dart';
import 'package:prototype_catat_uang/screens/stats_screen.dart';
import 'package:prototype_catat_uang/screens/account_screen.dart';
import 'package:prototype_catat_uang/screens/insert_transaction_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<TransactionPageState> _transactionKey = GlobalKey();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          switch (_selectedIndex) {
            case 0:
              return TransactionPage(key: _transactionKey);
            case 1:
              return const StatsScreen();
            case 2:
              return const AccountScreen();
            default:
              return const Center(child: Text('Error'));
          }
        },
      ),

      // === LOGIC UMPETIN TOMBOL (+) ===
      // Kalau lagi di halaman Saldo (Index 2), tombolnya NULL (ilang).
      // Kalau enggak, baru munculin FloatingActionButton.
      floatingActionButton: _selectedIndex == 2 
          ? null 
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InsertTransactionScreen()),
                ).then((value) {
                  if (value == true) {
                    _transactionKey.currentState?.refreshData();
                  }
                });
              },
              backgroundColor: const Color(0xFFFF6B6B),
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white),
            ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: const Color(0xFFFF6B6B).withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Color(0xFFFF6B6B)),
            label: 'Transaksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFFFF6B6B)),
            label: 'Statistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: Color(0xFFFF6B6B)),
            label: 'Saldo',
          ),
        ],
      ),
    );
  }
}