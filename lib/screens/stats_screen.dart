import 'package:prototype_catat_uang/database/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  void _loadData() async {
    final data = await DatabaseHelper().getTransactions();
    Map<String, int> tempMap = {};
    int totalExp = 0;
    int totalInc = 0;
    String startMonth = DateFormat('yyyy-MM').format(_focusedDate);

    for (var item in data) {
      String date = item['date'];
      if (date.startsWith(startMonth)) {
        int amount = item['amount'] as int;
        
        if (item['type'] == 'Expense') {
          totalExp += amount;
        } else {
          totalInc += amount;
        }

        if (item['type'] == _chartType) {
          String cat = item['category'];
          if (tempMap.containsKey(cat)) tempMap[cat] = tempMap[cat]! + amount;
          else tempMap[cat] = amount;
        }
      }
    }
    
    var sortedKeys = tempMap.keys.toList(growable: false)
      ..sort((k1, k2) => tempMap[k2]!.compareTo(tempMap[k1]!));
    Map<String, int> sortedMap = Map.fromIterable(sortedKeys, key: (k) => k, value: (k) => tempMap[k]!);

    setState(() {
      _categoryData = sortedMap;
      _totalExpense = totalExp;
      _totalIncome = totalInc;
      _isLoading = false;
    });
  }

  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    int currentTotalChart = _chartType == 'Expense' ? _totalExpense : _totalIncome;
    Color currentColor = _chartType == 'Expense' ? Colors.redAccent : Colors.teal;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.black87), onPressed: () => _changeMonth(-1)),
                  Text(DateFormat('MMM yyyy').format(_focusedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black87), onPressed: () => _changeMonth(1)),
                ],
              ),
            ),

            // TOGGLE SWITCH
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.shade300)),
              child: Row(children: [_buildTypeButton("Expense", Colors.redAccent), _buildTypeButton("Income", Colors.teal)]),
            ),
            const SizedBox(height: 10),

            // CHART AREA
            _isLoading
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : currentTotalChart == 0
                    ? Expanded(child: Center(child: Text("Belum ada data $_chartType bulan ini.", style: const TextStyle(color: Colors.grey))))
                    : SizedBox(
                        // Tinggi container chart tetep 300, tapi radius chart di dalemnya kita kecilin
                        height: 300,
                        child: Stack( 
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                sectionsSpace: 2,
                                // === DIET RADIUS ===
                                // Lubang tengah dikecilin dikit (70 -> 60) biar imbang
                                centerSpaceRadius: 60, 
                                sections: _generateSections(currentTotalChart),
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                            
                            // TEXT DETAIL
                            SizedBox(
                              width: 100,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _touchedIndex == -1 ? "Total $_chartType" : _categoryData.keys.elementAt(_touchedIndex),
                                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    Text(
                                      _touchedIndex == -1 
                                          ? formatRupiah(currentTotalChart)
                                          : formatRupiah(_categoryData.values.elementAt(_touchedIndex)),
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: currentColor),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
            
            const SizedBox(height: 20),

            // LIST CATEGORY
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categoryData.length,
                itemBuilder: (context, index) {
                  String category = _categoryData.keys.elementAt(index);
                  int amount = _categoryData[category]!;
                  double percentage = (amount / currentTotalChart) * 100;
                  Color itemColor = _colors[index % _colors.length];
                  bool isSelected = _touchedIndex == index; 

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(isSelected ? 10 : 0),
                    decoration: BoxDecoration(color: isSelected ? Colors.grey[100] : Colors.transparent, borderRadius: BorderRadius.circular(10), border: isSelected ? Border.all(color: Colors.grey.shade300) : null),
                    child: Row(
                      children: [
                        Container(width: 50, padding: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: itemColor, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text("${percentage.toStringAsFixed(0)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12))),
                        const SizedBox(width: 12),
                        Expanded(child: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87))),
                        Text(formatRupiah(amount), style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)), 
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

  Widget _buildTypeButton(String label, Color color) {
    bool isSelected = _chartType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _chartType = label;
            _touchedIndex = -1; 
          });
          _loadData(); 
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(25), boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : []),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: isSelected ? color : Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateSections(int total) {
    return List.generate(_categoryData.length, (index) {
      int amount = _categoryData.values.elementAt(index);
      final isTouched = index == _touchedIndex;
      
      // === DIET RADIUS ===
      // Normal: 50 (sebelumnya 90-an)
      // Pas diklik: 60 (sebelumnya 110)
      // Total Radius dari tengah = 60 (center) + 60 (max chart) = 120. 
      // Diameter = 240. Container 300. Sisa space 60px (Aman banget!)
      final double radius = isTouched ? 60.0 : 50.0; 
      
      final double fontSize = isTouched ? 18.0 : 0.0;
      return PieChartSectionData(color: _colors[index % _colors.length], value: amount.toDouble(), title: "", radius: radius, titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white));
    });
  }
}