import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'post_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _DailyItineraryScreenState extends State<DailyItineraryScreen>
    with SingleTickerProviderStateMixin {
  late DateTime startDate;
  late DateTime endDate;
  late List<DateTime> travelDays;
  int selectedDayIndex = 0;
  final Map<DateTime, TextEditingController> noteControllers = {};
  final Map<DateTime, List<String>> checklistItems = {};
  final Map<DateTime, TextEditingController> newChecklistInput = {};
  List<String> _embeddedGuides = [];
  String? uid;
  bool isReady = false;
  final List<String> _headerImages = [
    'https://media.timeout.com/images/105240189/image.jpg',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e',
    'https://images.unsplash.com/photo-1491553895911-0055eca6402d',
    'https://images.unsplash.com/photo-1506748686214-e9df14d4d9d0',
    'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1'
  ];
  late String _selectedHeaderImage;

  @override
  void initState() {
    super.initState();
    _selectedHeaderImage = _headerImages[Random().nextInt(_headerImages.length)];
    Future.delayed(Duration.zero, () async {
      uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || widget.tripId.trim().isEmpty) return;
      startDate = widget.startDate;
      endDate = widget.endDate;
      travelDays = _generateDateRange(startDate, endDate);
      for (var date in travelDays) {
        noteControllers[date] = TextEditingController();
        checklistItems[date] = [];
        newChecklistInput[date] = TextEditingController();
      }
      await _loadExistingData();
      setState(() => isReady = true);
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
    if (data != null && data['embeddedGuides'] != null) {
      _embeddedGuides = List<String>.from(data['embeddedGuides']);
    }
  }

  Future<void> _saveToFirestore(DateTime date) async {
    if (uid == null || widget.tripId.trim().isEmpty) return;

    final note = noteControllers[date]?.text ?? '';
    final checklist = checklistItems[date] ?? [];
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    final tripRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(widget.tripId);

    await tripRef.set({
      'dailyItinerary': {
        formattedDate: {
          'notes': note,
          'checklist': checklist,
        }
      }
    }, SetOptions(merge: true));
  }

void _showEditTripDatesDialog() async {
  DateTime newStart = startDate;
  DateTime newEnd = endDate;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Edit Trip Dates"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("Start Date: ${DateFormat.yMMMd().format(newStart)}"),
              trailing: Icon(Icons.date_range),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: newStart,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  newStart = picked;
                }
              },
            ),
            ListTile(
              title: Text("End Date: ${DateFormat.yMMMd().format(newEnd)}"),
              trailing: Icon(Icons.date_range),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: newEnd,
                  firstDate: newStart,
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  newEnd = picked;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (uid == null) return;
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('trips')
                  .doc(widget.tripId)
                  .update({
                    'startDate': newStart,
                    'endDate': newEnd,
                  });

              // Update local state and reload travelDays
              setState(() {
                startDate = newStart;
                endDate = newEnd;
                travelDays = _generateDateRange(startDate, endDate);
                selectedDayIndex = 0;

                // Reset note + checklist editors
                noteControllers.clear();
                checklistItems.clear();
                newChecklistInput.clear();
                for (var date in travelDays) {
                  noteControllers[date] = TextEditingController();
                  checklistItems[date] = [];
                  newChecklistInput[date] = TextEditingController();
                }
              });

              await _loadExistingData();

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Trip dates updated!")),
              );
            },
            child: Text("Save"),
          ),
        ],
      );
    },
  );
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
    final formatter = DateFormat('d MMMM yyyy');
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          title: const Text('Itinerary Planner', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: !isReady
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Picture Header
                    Stack(
                      children: [
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(_selectedHeaderImage),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          bottom: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Trip to', style: TextStyle(fontSize: 18, color: Colors.white)),
                              Text(widget.tripTitle,
                                  style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                                  SizedBox(width: 6),
                                  Text("${formatter.format(startDate)} - ${formatter.format(endDate)}",
                                      style: TextStyle(color: Colors.white, fontSize: 14)),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                    const TabBar(
                      labelColor: Colors.black,
                      indicatorColor: Colors.orange,
                      tabs: [
                        Tab(text: 'Overview'),
                        Tab(text: 'Trip plan'),
                        Tab(text: 'Budget'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildOverviewTab(),
                          _buildTripPlanTab(),
                          _buildBudgetTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    int numDays = travelDays.length;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Trip Type: Solo trip", style: TextStyle(fontSize: 16, color: Colors.black87)),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Duration: $numDays days", style: TextStyle(fontSize: 16, color: Colors.black87)),
              TextButton.icon(
                onPressed: _showEditTripDatesDialog,
                icon: Icon(Icons.edit_calendar, size: 18),
                label: Text("Edit Dates", style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          SizedBox(height: 8),
          Divider(),
          SizedBox(height: 8),
          Text("Embedded Guides", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          if (_embeddedGuides.isEmpty)
            Text("No guides added yet.")
          else
          SizedBox(
            height: 150,
            child: ListView.separated(
              itemCount: _embeddedGuides.length,
              separatorBuilder: (_, __) => SizedBox(height: 10),
              itemBuilder: (context, index) {
                final postId = _embeddedGuides[index];

                // Skip invalid/empty postIds
                if (postId == null || postId.trim().isEmpty) {
                  return SizedBox(); 
                }

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailsScreen(postId: postId),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.insert_drive_file, color: Colors.orange),
                            SizedBox(width: 10),
                          ],
                        ),
                        Expanded(
                          child: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('forum_posts').doc(postId).get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Text("Loading...", style: TextStyle(fontStyle: FontStyle.italic));
                              }
                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return Text("Guide not found", style: TextStyle(color: Colors.red));
                              }

                              final postData = snapshot.data!.data() as Map<String, dynamic>;
                              final title = postData['title'] ?? 'Untitled Guide';

                              return Text(
                                title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              );
                            },
                          ),
                        ),                        
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Text("Notes:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 4),
          Text("This trip includes some amazing places and food experiences planned ahead.",
              style: TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }

Widget _buildTripPlanTab() {
  final selectedDate = travelDays[selectedDayIndex];
  final formatter = DateFormat('EEE, MMM d');

  return Column(
    children: [
      SizedBox(height: 15),
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
                  color: isSelected ? Colors.brown : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
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
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Day Plan Notes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    TextField(
                      controller: noteControllers[selectedDate],
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Write your plans or reflections here...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text("Checklist / Places", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    ...checklistItems[selectedDate]!.map((item) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            leading: const Icon(Icons.place_outlined),
                            title: Text(item),
                          ),
                        )),
                    SizedBox(height: 12),
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
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.add_circle, color: Colors.brown, size: 32),
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
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        ),
                        onPressed: () async {
                          await _saveToFirestore(selectedDate);
                          final formatted = DateFormat('EEE, MMM d').format(selectedDate);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Saved $formatted")),
                          );
                        },
                        icon: Icon(Icons.save, color: Colors.white),
                        label: Text("Save Day", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
     
  

  Widget _buildBudgetTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .where('tripName', isEqualTo: widget.tripTitle)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        double total = 0;
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          total += (data['converted'] ?? 0).toDouble();
        }

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'Expense'),
                subtitle: Text("${data['amount']} ${data['from']} → ${data['converted']} ${data['to']}"),
                trailing: Text(DateFormat('dd MMM').format((data['timestamp'] as Timestamp).toDate())),
              );
            }),
            Divider(),
            ListTile(
              title: Text("Total", style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text("${total.toStringAsFixed(2)} ${docs.isNotEmpty ? docs.first['to'] : ''}"),
            ),

            
          ],
          
        );
        
      },
    );

  }
}