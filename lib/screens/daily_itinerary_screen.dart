import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailyItineraryScreen extends StatefulWidget {
  final String tripId;
  final String tripTitle;
  final DateTime startDate;
  final DateTime endDate;

  const DailyItineraryScreen({
    required this.tripId,
    required this.tripTitle,
    required this.startDate,
    required this.endDate,
    Key? key,
  }) : super(key: key);

  @override
  _DailyItineraryScreenState createState() => _DailyItineraryScreenState();
}

class _DailyItineraryScreenState extends State<DailyItineraryScreen> {
  late List<DateTime> travelDays;
  int selectedDayIndex = 0;
  final Map<DateTime, TextEditingController> noteControllers = {};
  final Map<DateTime, List<String>> checklistItems = {};
  final Map<DateTime, TextEditingController> newChecklistInput = {};

  String? uid;
  bool isReady = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      uid = FirebaseAuth.instance.currentUser?.uid;

      print('🧭 Initializing DailyItineraryScreen with:');
      print('Trip ID: ${widget.tripId}');
      print('Trip Title: ${widget.tripTitle}');
      print('Start Date: ${widget.startDate}');
      print('End Date: ${widget.endDate}');
      print('UID: $uid');

      if (uid == null || widget.tripId.trim().isEmpty) {
        print('❌ UID or tripId is missing!');
        return;
      }

      travelDays = _generateDateRange(widget.startDate, widget.endDate);
      for (var date in travelDays) {
        noteControllers[date] = TextEditingController();
        checklistItems[date] = [];
        newChecklistInput[date] = TextEditingController();
      }

      await _loadExistingData();
      setState(() {
        isReady = true;
      });

      final currentDate = travelDays[selectedDayIndex];
      print('🔍 isReady: $isReady, UID: $uid');
      print('🔍 Controllers check: ');
      print('- Has current date: ${currentDate != null}');
      print('- noteControllers has key: ${noteControllers.containsKey(currentDate)}');
      print('- checklistItems has key: ${checklistItems.containsKey(currentDate)}');
      print('- newChecklistInput has key: ${newChecklistInput.containsKey(currentDate)}');
    });
  }

  List<DateTime> _generateDateRange(DateTime start, DateTime end) {
    final List<DateTime> days = [];
    DateTime current = start;
    while (!current.isAfter(end)) {
      days.add(current);
      current = current.add(Duration(days: 1));
    }
    return days;
  }

  Future<void> _loadExistingData() async {
    if (uid == null || widget.tripId.trim().isEmpty) return;
    final tripDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(widget.tripId)
        .get();
    final data = tripDoc.data();
    if (data != null && data['dailyItinerary'] != null) {
      final itinerary = Map<String, dynamic>.from(data['dailyItinerary']);
      itinerary.forEach((dateStr, entry) {
        final date = DateTime.tryParse(dateStr);
        if (date != null && travelDays.contains(date)) {
          noteControllers[date]?.text = entry['notes'] ?? '';
          checklistItems[date] = List<String>.from(entry['checklist'] ?? []);
        }
      });
    }
  }

  Future<void> _saveToFirestore(DateTime date) async {
    if (uid == null || widget.tripId.trim().isEmpty) {
      print('⚠️ Cannot save — Missing UID or Trip ID.');
      return;
    }

    final note = noteControllers[date]?.text ?? '';
    final checklist = checklistItems[date] ?? [];
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    final tripRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(widget.tripId);

    try {
      await tripRef.set({
        'dailyItinerary': {
          formattedDate: {
            'notes': note,
            'checklist': checklist,
          }
        }
      }, SetOptions(merge: true));

      print('✅ Saved itinerary for $formattedDate');
    } catch (e) {
      print('❌ Error saving itinerary: $e');
    }
  }

  @override
  void dispose() {
    noteControllers.values.forEach((c) => c.dispose());
    newChecklistInput.values.forEach((c) => c.dispose());
    selectedDayIndex = 0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady || uid == null ||
        !noteControllers.containsKey(travelDays[selectedDayIndex]) ||
        !checklistItems.containsKey(travelDays[selectedDayIndex]) ||
        !newChecklistInput.containsKey(travelDays[selectedDayIndex])) {
      return Scaffold(
        appBar: AppBar(title: Text("Trip to ${widget.tripTitle}")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final selectedDate = travelDays[selectedDayIndex];
    final formatter = DateFormat('EEE, MMM d');

    return Scaffold(
      appBar: AppBar(title: Text("Trip to ${widget.tripTitle}")),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: travelDays.length,
              itemBuilder: (context, index) {
                final day = travelDays[index];
                final label = formatter.format(day);
                final isSelected = index == selectedDayIndex;
                return GestureDetector(
                  onTap: () => setState(() => selectedDayIndex = index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Day Plan Notes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: noteControllers[selectedDate],
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Write your plans or reflections here...",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text("Checklist / Places", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        ...checklistItems[selectedDate]!.map((item) => Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: ListTile(
                                leading: const Icon(Icons.place_outlined),
                                title: Text(item),
                              ),
                            )),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: newChecklistInput[selectedDate],
                                decoration: InputDecoration(
                                  hintText: 'Add new place or activity',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.teal, size: 32),
                              onPressed: () {
                                final text = newChecklistInput[selectedDate]?.text.trim();
                                if (text != null && text.isNotEmpty) {
                                  setState(() {
                                    checklistItems[selectedDate]?.add(text);
                                    newChecklistInput[selectedDate]?.clear();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FloatingActionButton.extended(
              onPressed: () async {
                await _saveToFirestore(selectedDate);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Saved Day ${selectedDayIndex + 1}")),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text("Save Day"),
            ),
          ),
        ],
      ),
    );
  }
}
