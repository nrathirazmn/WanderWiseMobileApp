import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _selectedCurrency;
  final List<String> _currencies = ['MYR', 'KRW', 'USD', 'JPY', 'EUR', 'SGD'];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  Future<List<Map<String, dynamic>>> _fetchExpenses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .get();

    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Map<String, double> _aggregateByCurrency(List<Map<String, dynamic>> expenses) {
    final Map<String, double> totals = {};
    for (var exp in expenses) {
      final date = (exp['timestamp'] as Timestamp?)?.toDate();
      if (date == null || date.month != _selectedMonth || date.year != _selectedYear) continue;
      if (_selectedCurrency != null && exp['to'] != _selectedCurrency) continue;
      final trip = exp['tripName'] ?? 'Unlinked Expenses';
      final converted = (exp['converted'] ?? 0).toDouble();
      totals[trip] = (totals[trip] ?? 0) + converted;
    }
    return totals;
  }

  Future<void> _exportToPDF(Map<String, double> data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Expense Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            ...data.entries.map((e) => pw.Text("${e.key}: ${e.value.toStringAsFixed(2)} ${_selectedCurrency ?? ''}")),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _showMonthYearPicker() async {
    int tempMonth = _selectedMonth;
    int tempYear = _selectedYear;

    final selected = await showModalBottomSheet<Map<String, int>>(
      context: context,
      builder: (context) {
        return Container(
          height: 250,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: _selectedMonth - 1),
                        itemExtent: 32,
                        onSelectedItemChanged: (index) => tempMonth = index + 1,
                        children: List.generate(12, (index) => Center(child: Text(DateFormat.MMM().format(DateTime(0, index + 1))))),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: 0),
                        itemExtent: 32,
                        onSelectedItemChanged: (index) => tempYear = DateTime.now().year - index,
                        children: List.generate(5, (index) => Center(child: Text((DateTime.now().year - index).toString()))),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, {'month': tempMonth, 'year': tempYear}),
                child: Text("Confirm"),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedMonth = selected['month']!;
        _selectedYear = selected['year']!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.brown.shade100,
        title: Text('Reports Summary', style: TextStyle(color: Colors.brown.shade800)),
        iconTheme: IconThemeData(color: Colors.brown.shade800),
        actions: [
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text("No expense data found."));

          final expenses = snapshot.data!;
          final totals = _aggregateByCurrency(expenses);
          final totalSum = totals.values.fold(0.0, (a, b) => a + b);

          final grouped = <String, Map<String, List<Map<String, dynamic>>>>{};
          final dateFormatter = DateFormat('yyyy-MM');
          final dayFormatter = DateFormat('yyyy-MM-dd');

          for (var exp in expenses) {
            final date = (exp['timestamp'] as Timestamp?)?.toDate();
            if (date == null || date.month != _selectedMonth || date.year != _selectedYear) continue;
            if (_selectedCurrency != null && exp['to'] != _selectedCurrency) continue;
            final monthKey = dateFormatter.format(date);
            final dayKey = dayFormatter.format(date);
            final trip = exp['tripName'] ?? 'Unlinked Expenses';
            grouped.putIfAbsent(monthKey, () => {});
            final monthly = grouped[monthKey]!;
            final label = "$trip - $dayKey";
            monthly.putIfAbsent(label, () => []).add(exp);
          }

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showMonthYearPicker,
                    icon: Icon(Icons.date_range),
                    label: Text("${DateFormat.MMM().format(DateTime(0, _selectedMonth))} $_selectedYear"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: "Converted to...",
                    onSelected: (value) {
                      setState(() {
                        _selectedCurrency = value == 'All' ? null : value;
                      });
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'All', child: Text('All Currencies')),
                      ..._currencies.map((c) => PopupMenuItem(value: c, child: Text(c))).toList(),
                    ],
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.brown.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.currency_exchange, size: 20, color: Colors.brown.shade800),
                          SizedBox(width: 6),
                          Text(
                            _selectedCurrency ?? "All",
                            style: TextStyle(color: Colors.brown.shade800),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.brown.shade800),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: 20),
              if (totals.isNotEmpty)
                PieChart(
                  dataMap: totals,
                  chartRadius: MediaQuery.of(context).size.width / 2.2,
                  legendOptions: LegendOptions(
                    legendPosition: LegendPosition.bottom,
                    showLegendsInRow: true,
                  ),
                  chartValuesOptions: ChartValuesOptions(
                    showChartValuesInPercentage: true,
                    showChartValues: true,
                  ),
                ),
              SizedBox(height: 20),
              ...grouped.entries.expand((monthEntry) {
                return monthEntry.value.entries.map((dayEntry) {
                  final parts = dayEntry.key.split(" - ");
                  final destination = parts[0];
                  final date = parts.length > 1 ? parts[1] : '';
                  final entries = dayEntry.value;
                  final totalDaySum = entries.fold(0.0, (sum, exp) => sum + (exp['converted'] ?? 0).toDouble());

                  return Card(
                    color: Colors.white,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(destination, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text(date, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                          SizedBox(height: 8),
                          ...entries.map((exp) {
                            final name = exp['name'] ?? 'No Name';
                            final from = exp['from'] ?? 'MYR';
                            final to = exp['to'] ?? 'USD';
                            final amount = exp['amount'] ?? 0;
                            final converted = exp['converted']?.toDouble() ?? 0.0;
                            IconData icon = Icons.attach_money;
                            final lowerName = name.toString().toLowerCase();
                            if (lowerName.contains('flight')) icon = Icons.flight;
                            else if (lowerName.contains('food') || lowerName.contains('meal')) icon = Icons.restaurant;
                            else if (lowerName.contains('hotel') || lowerName.contains('stay')) icon = Icons.hotel;
                            else if (lowerName.contains('transport')) icon = Icons.directions_bus;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(icon, color: Colors.teal),
                              title: Text(name),
                              subtitle: Text("$amount $from → ${converted.toStringAsFixed(2)} $to"),
                            );
                          }),
                          Divider(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Subtotal: ${totalDaySum.toStringAsFixed(2)} ${_selectedCurrency ?? ''}",
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                });
              }),
              Divider(thickness: 1.5),
            ],
          );
        },
      ),
    );
  }
}
