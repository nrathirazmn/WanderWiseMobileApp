
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

// class ReportsScreen extends StatefulWidget {
//   const ReportsScreen({super.key});

//   @override
//   State<ReportsScreen> createState() => _ReportsScreenState();
// }

// class _ReportsScreenState extends State<ReportsScreen> {
//   DateTime? _startDate;
//   DateTime? _endDate;
//   String? _selectedCurrency;
//   final List<String> _currencies = ['MYR', 'KRW', 'USD', 'JPY', 'EUR', 'SGD'];

//   Future<List<Map<String, dynamic>>> _fetchExpenses() async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return [];

//     Query query = FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .collection('expenses');

//     if (_startDate != null) {
//       query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
//     }
//     if (_endDate != null) {
//       query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_endDate!));
//     }

//     final snapshot = await query.get();

//     return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
//   }

//   Map<String, double> _aggregateByCurrency(List<Map<String, dynamic>> expenses) {
//     final Map<String, double> totals = {};

//     for (var exp in expenses) {
//       if (_selectedCurrency != null && exp['to'] != _selectedCurrency) continue;

//       final trip = exp['trip'] ?? 'Uncategorized';
//       final converted = (exp['converted'] ?? 0).toDouble();

//       totals[trip] = (totals[trip] ?? 0) + converted;
//     }

//     return totals;
//   }

//   Future<void> _exportToPDF(Map<String, double> data) async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.Page(
//         build: (pw.Context context) => pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Text("Expense Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
//             pw.SizedBox(height: 12),
//             ...data.entries.map((e) => pw.Text("${e.key}: ${e.value.toStringAsFixed(2)} ${_selectedCurrency ?? ''}")),
//           ],
//         ),
//       ),
//     );

//     await Printing.layoutPdf(onLayout: (format) async => pdf.save());
//   }

//   Future<void> _pickDateRange() async {
//     final picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2022),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         _startDate = picked.start;
//         _endDate = picked.end;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Reports Summary'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.picture_as_pdf),
//             onPressed: () async {
//               final expenses = await _fetchExpenses();
//               final totals = _aggregateByCurrency(expenses);
//               _exportToPDF(totals);
//             },
//             tooltip: "Export PDF",
//           )
//         ],
//       ),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: _fetchExpenses(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting)
//             return Center(child: CircularProgressIndicator());
//           if (!snapshot.hasData || snapshot.data!.isEmpty)
//             return Center(child: Text("No expense data found."));

//           final expenses = snapshot.data!;
//           final totals = _aggregateByCurrency(expenses);

//           return ListView(
//             padding: EdgeInsets.all(16),
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: _pickDateRange,
//                     icon: Icon(Icons.date_range),
//                     label: Text("Date Range"),
//                   ),
//                   DropdownButton<String>(
//                     hint: Text("Currency"),
//                     value: _selectedCurrency,
//                     items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
//                     onChanged: (val) => setState(() => _selectedCurrency = val),
//                   )
//                 ],
//               ),
//               SizedBox(height: 20),
//               SizedBox(
//                 height: 250,
//                 child: PieChart(
//                   PieChartData(
//                     sections: totals.entries.map((e) {
//                       final value = e.value;
//                       final percent = value / totals.values.reduce((a, b) => a + b) * 100;
//                       return PieChartSectionData(
//                         title: "${e.key} (${percent.toStringAsFixed(1)}%)",
//                         value: value,
//                         radius: 80,
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20),
//               ...totals.entries.map((e) => ListTile(
//                     title: Text(e.key),
//                     trailing: Text("${e.value.toStringAsFixed(2)} ${_selectedCurrency ?? ''}"),
//                   )),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
