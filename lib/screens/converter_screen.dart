import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../widgets/save_expense_modal.dart';
import 'itinerary_screen.dart';

class ConverterScreen extends StatefulWidget {
  @override
  _ConverterScreenState createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _amountController = TextEditingController();
  String _from = 'MYR';
  String _to = 'KRW';
  double? _converted;
  double? _rate;
  bool _loading = false;
  String? _apiError;
  List<Map<String, dynamic>> _tripDocs = [];

  final currencies = ['MYR', 'KRW', 'USD', 'JPY', 'EUR', 'SGD'];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .get();
      setState(() {
        _tripDocs = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
      });
    }
  }

  Future<void> _convert() async {
    final input = double.tryParse(_amountController.text.trim());

    if (input == null || input <= 0) {
      setState(() {
        _converted = null;
        _rate = null;
        _apiError = 'Please enter a valid amount.';
      });
      return;
    }

    if (_from == _to) {
      setState(() {
        _converted = input;
        _rate = 1.0;
        _apiError = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _apiError = null;
    });

    final url = Uri.parse('https://open.er-api.com/v6/latest/$_from');
    try {
      final res = await http.get(url);
      final data = json.decode(res.body);
      if (data['result'] == 'success' && data['rates'][_to] != null) {
        final rate = (data['rates'][_to] as num).toDouble();
        final result = input * rate;
        setState(() {
          _rate = rate;
          _converted = result;
        });
      } else {
        setState(() {
          _apiError = 'No rate found.';
          _converted = null;
          _rate = null;
        });
      }
    } catch (e) {
      setState(() {
        _apiError = 'Failed to convert.';
        _converted = null;
        _rate = null;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

void _showTripSelectionDialog() {
  if (_tripDocs.isEmpty) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("No Trips Found"),
        content: Text("You don't have any trips yet. Please create one to link this expense."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/main', arguments: 3); // Go to Itinerary
            },
            child: Text("Create & Link Trip"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  } else {
    // Trips available, show only dropdown once and go straight to modal
    String? selectedTrip;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Select Trip to Save Expense"),
          content: DropdownButtonFormField(
            isExpanded: true,
            hint: Text("Select Trip"),
            value: selectedTrip,
            items: _tripDocs.map((doc) {
              return DropdownMenuItem(
                value: doc['id'],
                child: Text(doc['destination'] ?? 'Unnamed Trip'),
              );
            }).toList(),
            onChanged: (val) => setState(() => selectedTrip = val.toString()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: selectedTrip == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => SaveExpenseModal(
                          converted: _converted,
                          from: _from,
                          to: _to,
                          amountController: _amountController,
                          trips: [selectedTrip!],
                        ),
                      );
                    },
              child: Text("Next"),
            ),
          ],
        ),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final flags = {
      'MYR': '🇲🇾',
      'KRW': '🇰🇷',
      'USD': '🇺🇸',
      'JPY': '🇯🇵',
      'EUR': '🇪🇺',
      'SGD': '🇸🇬'
    };

    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 30),
            Text(
              'Currency Converter',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            Text(
              'Convert your money to get real-time conversion and monitor your expenses',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _currencyDropdown(_from, (val) {
                        setState(() => _from = val);
                        _convert();
                      }, flags),
                      IconButton(
                        icon: Icon(Icons.swap_horiz, size: 32, color: Colors.brown),
                        tooltip: 'Swap currencies',
                        onPressed: () {
                          setState(() {
                            final temp = _from;
                            _from = _to;
                            _to = temp;
                          });
                          _convert();
                        },
                      ),
                      _currencyDropdown(_to, (val) {
                        setState(() => _to = val);
                        _convert();
                      }, flags),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _convert(),
                    decoration: InputDecoration(
                      labelText: "Amount",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),
            _loading
                ? CircularProgressIndicator()
                : Text(
                    _converted != null ? "${_converted!.toStringAsFixed(2)} $_to" : "--",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
            if (_rate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "1 $_from = ${_rate!.toStringAsFixed(4)} $_to",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            if (_apiError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_apiError!, style: TextStyle(color: Colors.red)),
              ),
            SizedBox(height: 25),
            ElevatedButton.icon(
              icon: Icon(Icons.save_alt_rounded, color: Colors.white),
              label: Text("Save as Expense", style: TextStyle(color: Colors.white)),
              onPressed: _showTripSelectionDialog,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: Colors.brown.shade600,
              ),
            ),
            SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.description, size: 28),
                      onPressed: () => Navigator.pushNamed(context, '/expenses-report'),
                    ),
                    SizedBox(height: 4),
                    Text('Reports', style: TextStyle(fontSize: 14)),
                  ],
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.receipt_long, size: 28),
                      onPressed: () => Navigator.pushNamed(context, '/expenses'),
                    ),
                    SizedBox(height: 4),
                    Text('Expenses', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _currencyDropdown(String selected, Function(String) onChanged, Map<String, String> flags) {
    return Column(
      children: [
        Text(flags[selected] ?? '', style: TextStyle(fontSize: 28)),
        SizedBox(height: 4),
        Container(
          width: 100,
          padding: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[100],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              onChanged: (val) => onChanged(val!),
              items: currencies
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
