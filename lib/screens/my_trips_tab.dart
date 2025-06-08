import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'daily_itinerary_screen.dart';
import 'post_details_screen.dart';
import 'trip_details_screen.dart';

class MyTripsTab extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('Please log in to view your trips.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('trips')
          .orderBy('startDate')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final trips = snapshot.data?.docs ?? [];

        if (trips.isEmpty) {
          return const Center(child: Text('No trips added yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index].data() as Map<String, dynamic>;
            final tripId = trips[index].id;

            final title = trip['destination'] ?? 'Unnamed Trip';
            final start = (trip['startDate'] as Timestamp?)?.toDate();
            final end = (trip['endDate'] as Timestamp?)?.toDate();
            final guideIds = List<String>.from(trip['embeddedGuides'] ?? []);
            final itineraryMap = Map<String, dynamic>.from(trip['dailyItinerary'] ?? {});

            print("\uD83D\uDCCC Trip: $title — Embedded Guide IDs: $guideIds");

            String? latestNote;
            int checklistCount = 0;
            if (itineraryMap.isNotEmpty) {
              final sortedKeys = itineraryMap.keys.toList()..sort();
              final lastDay = itineraryMap[sortedKeys.last];
              latestNote = lastDay['notes'];
              checklistCount = (lastDay['checklist'] as List?)?.length ?? 0;
            }

return Card(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  elevation: 4,
  margin: const EdgeInsets.symmetric(vertical: 8),
  child: ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${start != null ? DateFormat.yMMMd().format(start) : '?'} - ${end != null ? DateFormat.yMMMd().format(end) : '?'}',
          style: TextStyle(color: Colors.grey[700]),
        ),
        if (latestNote != null && latestNote.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text("📝 ${latestNote.length > 40 ? latestNote.substring(0, 40) + '...' : latestNote}"),
          ),
        if (checklistCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text("✅ $checklistCount checklist items"),
          ),
      ],
    ),
    // trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DailyItineraryScreen(
            tripId: tripId,
            tripTitle: title,
            startDate: start!,
            endDate: end!,
          ),
        ),
      );
    },
  ),
);
          },
        );
      },
    );
  }
}
