import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prototype_catat_uang/database/database_helper.dart';
import 'package:prototype_catat_uang/widgets/custom_switch.dart'; // Import CustomSwitch

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DateTime _focusedDate = DateTime.now();

  Map<String, int> _categoryData = {};
  int _totalExpense = 0;
  int _totalIncome = 0;

  bool _isLoading = true;
  int _touchedIndex = -1;
  String _chartType = 'Expense';

  final List<Color> _colors = [
    const Color(0xFFFF6B6B),
    const Color(0xFFFFD93D),
    const Color(0xFF6BCB77),
    const Color(0xFF4D96FF),
    const Color(0xFF9A616D),
    const Color(0xFFFF9F1C),
    const Color(0xFF2EC4B6),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + offset);
      _isLoading = true;
      _touchedIndex = -1;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DatabaseHelper().getTransactions();

    final currentMonth = DateFormat('yyyy-MM').format(_focusedDate);

    Map<String, int> tempMap = {};
    int totalExp = 0;
    int totalInc = 0;

    for (var item in data) {
      if (item['date'].toString().startsWith(currentMonth)) {
        int amount = item['amount'] as int;

        if (item['type'] == 'Expense') {
          totalExp += amount;
        } else {
          totalInc += amount;
        }

        if (item['type'] == _chartType) {
          tempMap[item['category']] =
              (tempMap[item['category']] ?? 0) + amount;
        }
      }
    }

    final sortedKeys = tempMap.keys.toList()
      ..sort((a, b) => tempMap[b]!.compareTo(tempMap[a]!));

    setState(() {
      _categoryData = {
        for (var k in sortedKeys) k: tempMap[k]!,
      };
      _totalExpense = totalExp;
      _totalIncome = totalInc;
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

  // ===========================
  // BUILD
  // ===========================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey;
    final cardColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    final currentTotal =
        _chartType == 'Expense' ? _totalExpense : _totalIncome;
    final currentColor =
        _chartType == 'Expense' ? Colors.redAccent : Colors.teal;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios,
                        size: 18, color: textColor),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Text(
                    DateFormat('MMMM yyyy', 'id_ID').format(_focusedDate),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios,
                        size: 18, color: textColor),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ),

            // === GANTI TOGGLE MANUAL DENGAN CUSTOM SWITCH ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: CustomSwitch(
                currentType: _chartType,
                onChanged: (val) {
                  setState(() {
                    _chartType = val;
                    _touchedIndex = -1; // Reset chart highlight
                  });
                  _loadData(); // Reload data sesuai tipe baru
                },
              ),
            ),
            // ===============================================

            const SizedBox(height: 10),

            // CHART
            _isLoading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : currentTotal == 0
                    ? Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset('assets/empty.json',
                                  width: 200, height: 200),
                              Text(
                                "Belum ada data $_chartType",
                                style: TextStyle(color: subTextColor),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 300,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (event, pieTouchResponse) {
                                    setState(() {
                                      if (!event
                                              .isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse
                                                  .touchedSection ==
                                              null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex = pieTouchResponse
                                          .touchedSection!
                                          .touchedSectionIndex;
                                    });
                                  },
                                ),
                                sectionsSpace: 2,
                                centerSpaceRadius: 60,
                                sections:
                                    _generateSections(currentTotal),
                                borderData:
                                    FlBorderData(show: false),
                              ),
                            ),

                            SizedBox(
                              width: 100,
                              child: FittedBox(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _touchedIndex == -1
                                          ? "Total $_chartType"
                                          : _categoryData.keys.elementAt(
                                              _touchedIndex),
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: subTextColor),
                                    ),
                                    Text(
                                      _touchedIndex == -1
                                          ? formatRupiah(currentTotal)
                                          : formatRupiah(
                                              _categoryData.values
                                                  .elementAt(
                                                      _touchedIndex)),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: currentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

            const SizedBox(height: 20),

            // LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categoryData.length,
                itemBuilder: (context, index) {
                  final category =
                      _categoryData.keys.elementAt(index);
                  final amount = _categoryData[category]!;
                  final percent =
                      (amount / currentTotal) * 100;
                  final itemColor =
                      _colors[index % _colors.length];
                  final isSelected = _touchedIndex == index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(isSelected ? 10 : 0),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? cardColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: Colors.grey.shade300)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          padding:
                              const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: itemColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "${percent.toStringAsFixed(0)}%",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: textColor),
                          ),
                        ),
                        Text(
                          formatRupiah(amount),
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: textColor),
                        ),
                      ],
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

  // ===========================
  // HELPERS
  // ===========================

  // _buildTypeButton SUDAH DIHAPUS karena diganti CustomSwitch

  List<PieChartSectionData> _generateSections(int total) {
    return List.generate(_categoryData.length, (index) {
      final amount = _categoryData.values.elementAt(index);
      final isTouched = index == _touchedIndex;

      return PieChartSectionData(
        color: _colors[index % _colors.length],
        value: amount.toDouble(),
        title: "",
        radius: isTouched ? 60 : 50,
      );
    });
  }
}