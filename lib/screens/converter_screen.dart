import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../widgets/save_expense_modal.dart';

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
  List<String> _trips = ['All Trips'];

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
        _trips = ['All Trips', ...snapshot.docs.map((doc) => doc.id)];
      });
    }
  }

  Future<void> _convert() async {
    final input = double.tryParse(_amountController.text.trim());
    if (input == null || input == 0) {
      setState(() {
        _converted = null;
        _rate = null;
        _apiError = null;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            Text(
              'Currency Converter',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 86, 35, 1),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Convert your money to get real-time conversion and add expenses',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 15),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row with FROM, arrow, TO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // FROM currency + flag
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("${flags[_from]}", style: TextStyle(fontSize: 32)),
                            SizedBox(height: 8),
                            Container(
                              width: 80,
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _from,
                                  isExpanded: true,
                                  onChanged: (val) {
                                    setState(() {
                                      _from = val!;
                                    });
                                    _convert();
                                  },
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
                        ),

                        SizedBox(width: 24),

                        Image.asset('assets/BrownArrow.png', height: 40, width: 40),
                        

                        SizedBox(width: 24),

                        // TO currency + flag
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("${flags[_to]}", style: TextStyle(fontSize: 32)),
                            SizedBox(height: 8),
                            Container(
                              width: 80,
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _to,
                                  isExpanded: true,
                                  onChanged: (val) {
                                    setState(() {
                                      _to = val!;
                                    });
                                    _convert();
                                  },
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
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Amount input below centered
                    Container(
                      width: 180,
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _convert(),
                        decoration: InputDecoration(
                          labelText: "Amount",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 15),

            _loading
                ? CircularProgressIndicator()
                : Text(
                    _converted != null ? "${_converted!.toStringAsFixed(2)} $_to" : "--",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 86, 35, 1),
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

            SizedBox(height: 15),

            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text("Save as Expense"),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => SaveExpenseModal(
                    converted: _converted,
                    from: _from,
                    to: _to,
                    amountController: _amountController,
                    trips: _trips,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.description, size: 28),
                      onPressed: () => Navigator.pushNamed(context, '/savedReports'),
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
}
