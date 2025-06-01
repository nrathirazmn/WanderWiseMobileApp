import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FAQ')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('faqs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No FAQs available.'));
          }

          final faqs = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final data = faqs[index].data() as Map<String, dynamic>;
              return ExpansionTile(
                title: Text(data['question'] ?? 'No Question'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(data['answer'] ?? 'No Answer'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
