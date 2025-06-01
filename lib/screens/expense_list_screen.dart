import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text("Saved Expenses")),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return Center(child: Text("No expenses saved."));

          final docs = snapshot.data!.docs;

          // Group expenses by trip
          final Map<String, List<QueryDocumentSnapshot>> grouped = {};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final trip = data['trip'] ?? 'No Trip';
            if (!grouped.containsKey(trip)) {
              grouped[trip] = [];
            }
            grouped[trip]!.add(doc);
          }

          return ListView(
            children: grouped.entries.map((entry) {
              final trip = entry.key;
              final expenses = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Text(
                      trip,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ),
                  ...expenses.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name']),
                      subtitle: Text(
                        "${data['amount']} ${data['from']} → ${data['converted'].toStringAsFixed(2)} ${data['to']}",
                      ),
                      trailing: data['timestamp'] != null
                          ? Text(
                              (data['timestamp'] as Timestamp)
                                  .toDate()
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0],
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            )
                          : null,
                    );
                  }).toList(),
                  Divider(thickness: 1),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
