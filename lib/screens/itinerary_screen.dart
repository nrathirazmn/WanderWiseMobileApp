import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'daily_itinerary_screen.dart';

class ItineraryScreen extends StatefulWidget {
  @override
  _ItineraryScreenState createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSolo = false;

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitTrip() async {
    if (_startDate == null || _endDate == null) {
      print('❌ Start or end date is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both travel and return dates.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a destination.')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final tripCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('trips');

      final newTripDoc = await tripCollection.add({
        'destination': _destinationController.text.trim(),
        'startDate': _startDate,
        'endDate': _endDate,
        'participants': _isSolo ? [] : [{'photoUrl': FirebaseAuth.instance.currentUser?.photoURL}],
        'createdAt': FieldValue.serverTimestamp(),
      });

      final tripId = newTripDoc.id;
      await newTripDoc.update({'tripId': tripId});

      if (tripId.isNotEmpty) {
        print('🚀 Navigating to DailyItineraryScreen with:');
        print('Trip ID: $tripId');
        print('Destination (Trip Title): ${_destinationController.text.trim()}');
        print('Start Date: $_startDate');
        print('End Date: $_endDate');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DailyItineraryScreen(
              tripId: tripId,
              tripTitle: _destinationController.text.trim(),
              startDate: _startDate ?? DateTime.now(),
              endDate: _endDate ?? DateTime.now().add(Duration(days: 1)),
            ),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip planned successfully!')),
      );

      _destinationController.clear();
      setState(() {
        _startDate = null;
        _endDate = null;
      });
    } catch (e) {
      print('❌ Failed to create trip: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 25),
              Center(
                child: Column(
                  children: [
                    Text(
                      "Plan Your Trip",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 86, 35, 1),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Get your itinerary ready and plan out the whole trip",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("Solo Trip", style: TextStyle(fontSize: 14)),
                  Checkbox(
                    value: _isSolo,
                    onChanged: (val) => setState(() => _isSolo = val!),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: "Destination",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: Icon(Icons.search),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? "Enter a destination" : null,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.date_range),
                      label: Text(_startDate == null
                          ? "Travel Date"
                          : "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}"),
                      onPressed: () => _pickDate(context, true),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.date_range),
                      label: Text(_endDate == null
                          ? "Return Date"
                          : "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}"),
                      onPressed: () => _pickDate(context, false),
                    ),
                  ),
                ],
              ),
              Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: _submitTrip,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                    child: Text("Save Trip"),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
