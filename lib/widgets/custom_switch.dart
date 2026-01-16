import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Buat Haptic

class CustomSwitch extends StatelessWidget {
  final String currentType; // 'Income' atau 'Expense'
  final Function(String) onChanged; // Fungsi buat ngasih tau parent kalo berubah

  const CustomSwitch({
    super.key,
    required this.currentType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    bool isIncome = currentType == 'Income';
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Warna Dasar
    Color incomeColor = Colors.teal;
    Color expenseColor = const Color(0xFFFF6B6B);
    Color activeColor = isIncome ? incomeColor : expenseColor;
    Color inactiveColor = isDark ? Colors.grey : Colors.grey[600]!;
    
    // Warna Background Container
    Color backgroundColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[200]!;
    // Warna Slider (Kotak yang gerak)
    Color sliderColor = isDark ? const Color(0xFF424242) : Colors.white;

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25), // Rounded banget
      ),
      child: Stack(
        children: [
          // 1. SLIDER ANIMASI (Kotak yang gerak)
          AnimatedAlign(
            duration: const Duration(milliseconds: 250), // Durasi Geser
            curve: Curves.easeInOut, // Gaya gerak mulus
            alignment: isIncome ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: (MediaQuery.of(context).size.width - 48) / 2, // Setengah lebar layar minus padding
              decoration: BoxDecoration(
                color: sliderColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

          // 2. TEXT LABEL (Income & Expense)
          Row(
            children: [
              // TOMBOL INCOME (KIRI)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!isIncome) {
                      HapticFeedback.selectionClick(); // Getar
                      onChanged('Income');
                    }
                  },
                  child: Container(
                    color: Colors.transparent, // Biar area tap luas
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontFamily: 'Poppins', // Pastikan font sama
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isIncome ? incomeColor : inactiveColor,
                      ),
                      child: const Text("Income"),
                    ),
                  ),
                ),
              ),

              // TOMBOL EXPENSE (KANAN)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (isIncome) {
                      HapticFeedback.selectionClick(); // Getar
                      onChanged('Expense');
                    }
                  },
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: !isIncome ? expenseColor : inactiveColor,
                      ),
                      child: const Text("Expense"),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}