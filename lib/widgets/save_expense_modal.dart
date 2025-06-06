import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SaveExpenseModal extends StatefulWidget {
  final double? converted;
  final String from;
  final String to;
  final TextEditingController amountController;
  final List<String> trips; // Should contain only 1 selected tripId

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
  String? _tripId;
  String? _tripName;

  @override
  void initState() {
    super.initState();
    if (widget.trips.isNotEmpty) {
      _tripId = widget.trips.first;
      _loadTripName();
    }
  }

  Future<void> _loadTripName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _tripId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(_tripId!)
          .get();

      if (doc.exists) {
        setState(() {
          _tripName = doc.data()?['destination'] ?? 'Unnamed Trip';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Save Expense"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _expenseNameController,
              decoration: const InputDecoration(
                labelText: 'Expense Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_tripName != null)
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.brown),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Linked to: $_tripName',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = _expenseNameController.text.trim();
            final input = double.tryParse(widget.amountController.text.trim());
            final user = FirebaseAuth.instance.currentUser;

            if (name.isEmpty || input == null || widget.converted == null || user == null || _tripId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill in all required fields.')),
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
              'trip': _tripId,
              'tripName': _tripName ?? 'Unnamed Trip',
            };

            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('expenses')
                .add(expenseData);

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Expense saved successfully')),
            );
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
