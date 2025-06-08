import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'daily_itinerary_screen.dart';
import 'package:lottie/lottie.dart';

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

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
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

        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;

        final tripDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('trips')
            .doc(tripId)
            .get();

        final tripData = tripDoc.data();
        final tripTitle = tripData?['destination'] ?? 'Unnamed Trip';
        final startDate = (tripData?['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        final endDate = (tripData?['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(Duration(days: 1));

        if (_isSolo) {
          // Show dialog to ask about travel buddy
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white.withOpacity(0.95),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset(
                        'assets/TravelItinerary.json', 
                        height: 120,
                      ),
                        const SizedBox(height: 16),
                        Text(
                          "Travel Buddy?",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown[800]),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        "You're going solo — but would you like to meet other travelers too?",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),

                  // Icon(Icons.group, size: 48, color: Colors.brown),
                  // const SizedBox(height: 16),
                  // Text(
                  //   "Travel Buddy?",
                  //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown[800]),
                  // ),
                  // const SizedBox(height: 12),
                  // Text(
                  //   "You're going solo — but would you like to meet other travelers too?",
                  //   textAlign: TextAlign.center,
                  //   style: TextStyle(fontSize: 14, color: Colors.black87),
                  // ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DailyItineraryScreen(
                                  tripId: tripId,
                                  tripTitle: tripTitle,
                                  startDate: startDate,
                                  endDate: endDate,
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.brown),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("No thanks", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(context, '/travel-buddy');
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.brown,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("Yes, please", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        } else {
        // DIRECTLY navigate to itinerary
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DailyItineraryScreen(
              tripId: tripId,
              tripTitle: tripTitle,
              startDate: startDate,
              endDate: endDate,
            ),
          ),
        );
      }

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
              const SizedBox(height: 25),
              Center(
                child: Column(
                  children: [
                    Text(
                      "Plan Your Trip",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 86, 35, 1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Get your itinerary ready and plan out the whole trip",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("Solo Trip", style: TextStyle(fontSize: 14)),
                  Switch(
                    value: _isSolo,
                    onChanged: (val) => setState(() => _isSolo = val),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text("Destination", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                    boxShadow: [
                      BoxShadow(color: Colors.grey.shade300, blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  child: TextFormField(
                    controller: _destinationController,
                    decoration: InputDecoration(
                      hintText: "Where to?",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      prefixIcon: Icon(Icons.search),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? "Enter a destination" : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("Trip Dates", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _pickDateRange(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                    boxShadow: [
                      BoxShadow(color: Colors.grey.shade300, blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (_startDate == null || _endDate == null)
                            ? "Select travel dates"
                            : "${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}",
                        style: TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.calendar_today, color: Colors.brown),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Save Trip", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
