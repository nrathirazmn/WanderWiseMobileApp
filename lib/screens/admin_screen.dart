import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUpdateScreen extends StatelessWidget {
  const AdminUpdateScreen({super.key});

  // Bug fix likes, matches, and bio for all users
  Future<void> patchUserFieldsForAll(BuildContext context) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final snapshot = await usersRef.get();

    int updatedCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final updates = <String, dynamic>{};
      if (!data.containsKey('likes')) updates['likes'] = [];
      if (!data.containsKey('matches')) updates['matches'] = [];
      if (!data.containsKey('bio')) updates['bio'] = 'Loves to travel!';

      if (updates.isNotEmpty) {
        await usersRef.doc(doc.id).update(updates);
        updatedCount++;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Patched $updatedCount user(s)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Only allow specific admin email
    if (user == null || user.email != 'nrathirazmn@gmail.com') {
      return Scaffold(
        appBar: AppBar(title: Text('Unauthorized')),
        body: Center(child: Text('🚫 You do not have access to this page.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Colors.brown[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, Admin!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.update),
              label: Text('Patch Likes, Matches & Bio'),
              onPressed: () => patchUserFieldsForAll(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
           
          ],
        ),
      ),
    );
  }
}
