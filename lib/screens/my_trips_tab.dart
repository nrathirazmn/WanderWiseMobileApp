import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                  if (guideIds.isEmpty)
                    const ListTile(
                      title: Text('No guides added yet.'),
                    )
                  else
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('forum_posts')
                          .where(FieldPath.documentId, whereIn: guideIds)
                          .get(),
                      builder: (context, guideSnapshot) {
                        if (guideSnapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          );
                        }
                        final guides = guideSnapshot.data?.docs ?? [];
                        print("\uD83D\uDCD9 Found \${guides.length} guides for trip '\$title'");

                        return Column(
                          children: guides.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final guideTitle = data['title'] ?? 'Untitled Guide';
                            print("\uD83D\uDD17 Guide loaded: \${doc.id} — Title: \$guideTitle");

                            return ListTile(
                              leading: const Icon(Icons.book),
                              title: Text(guideTitle),
                              subtitle: const Text("Tap to view guide"),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostDetailsScreen(postId: doc.id),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
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
