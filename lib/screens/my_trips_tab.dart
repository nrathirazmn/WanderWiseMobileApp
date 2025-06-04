import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
            final guides = List<String>.from(trip['embeddedGuides'] ?? []);
            final itineraryMap = Map<String, dynamic>.from(trip['dailyItinerary'] ?? {});

            // Summary info
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
              child: ExpansionTile(
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${start != null ? DateFormat.yMMMd().format(start) : '?'} - ${end != null ? DateFormat.yMMMd().format(end) : '?'}',
                ),
                trailing: const Icon(Icons.expand_more),
                children: [
                  if (latestNote != null && latestNote.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.notes),
                      title: const Text("Latest Note"),
                      subtitle: Text(latestNote),
                    ),
                  if (checklistCount > 0)
                    ListTile(
                      leading: const Icon(Icons.checklist),
                      title: Text("Checklist Items: $checklistCount"),
                    ),
                  // if (guides.isEmpty)
                  //   const ListTile(
                  //     title: Text('No guides added yet.'),
                  //   )
                  // else
                  //   ...guides.map((url) => ListTile(
                  //         leading: const Icon(Icons.picture_as_pdf),
                  //         title: const Text('Download Guide'),
                  //         onTap: () {
                  //           final uri = Uri.parse(url);
                  //           launchUrl(uri, mode: LaunchMode.externalApplication);
                  //         },
                  //       )),
                  ListTile(
                    leading: const Icon(Icons.arrow_forward_ios),
                    title: const Text('View Full Trip Details'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TripDetailsScreen(tripId: tripId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
