import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HowToPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('How to Use WanderWise')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('how_to_steps').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No guides available.'));
          }

          final steps = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final data = steps[index].data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(data['title'] ?? 'No Title'),
                  subtitle: Text(data['desc'] ?? 'No Description'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
