import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SaveExpenseModal extends StatefulWidget {
  final double? converted;
  final String from;
  final String to;
  final TextEditingController amountController;
  final List<String> trips;

  const SaveExpenseModal({
    required this.converted,
    required this.from,
    required this.to,
    required this.amountController,
    required this.trips,
  });

  @override
  _SaveExpenseModalState createState() => _SaveExpenseModalState();
}

class _SaveExpenseModalState extends State<SaveExpenseModal> {
  final TextEditingController _expenseNameController = TextEditingController();
  final TextEditingController _newTripController = TextEditingController();
  String? _selectedTrip;

  @override
  Widget build(BuildContext context) {
    final currentTrips = widget.trips;

    return AlertDialog(
      title: Text("Save Expense"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _expenseNameController,
              decoration: InputDecoration(
                labelText: 'Expense Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Existing Trip (optional)',
                border: OutlineInputBorder(),
              ),
              value: _selectedTrip,
            items: [
              ...currentTrips
                  .where((t) => t != 'All Trips')
                  .map((trip) => DropdownMenuItem(
                        value: trip,
                        child: Text(trip),
                      )),
              if (_selectedTrip != null &&
                  !currentTrips.contains(_selectedTrip))
                DropdownMenuItem(
                  value: _selectedTrip,
                  child: Text(_selectedTrip! + " (new)"),
                ),
            ],
              onChanged: (value) => setState(() => _selectedTrip = value),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _newTripController,
              decoration: InputDecoration(
                labelText: 'Or Create New Trip',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  setState(() => _selectedTrip = value.trim());
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = _expenseNameController.text.trim();
            final input = double.tryParse(widget.amountController.text.trim());
            final user = FirebaseAuth.instance.currentUser;

            if (name.isEmpty || input == null || widget.converted == null || user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please fill in expense name and amount.')),
              );
              return;
            }


            final expenseData = {
              'name': name,
              'amount': input,
              'converted': widget.converted,
              'from': widget.from,
              'to': widget.to,
              'timestamp': Timestamp.now(),
            };

            if (_selectedTrip != null) {
              expenseData['trip'] = _selectedTrip;
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('trips')
                  .doc(_selectedTrip)
                  .set({'created': Timestamp.now()}, SetOptions(merge: true));
            }

            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('expenses')
                .add(expenseData);

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Expense saved successfully')),
            );
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}
