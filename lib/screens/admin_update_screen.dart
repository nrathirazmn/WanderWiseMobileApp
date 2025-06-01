import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUpdateScreen extends StatefulWidget {
  @override
  _AdminUpdateScreenState createState() => _AdminUpdateScreenState();
}

class _AdminUpdateScreenState extends State<AdminUpdateScreen> {
  String status = "Press the button to start update";

  Future<void> updateUsers() async {
    setState(() {
      status = "⏳ Updating users...";
    });

    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      final snapshot = await usersRef.get();

      for (var doc in snapshot.docs) {
        final uid = doc.id;

        await usersRef.doc(uid).update({
          'uid': uid,
          'showInTravelBuddy': true, // or false if you want to hide
        });
      }

      setState(() {
        status = "✅ All users updated!";
      });
    } catch (e) {
      setState(() {
        status = "❌ Error: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Update")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status, textAlign: TextAlign.center),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateUsers,
              child: Text("Run Batch Update"),
            ),
          ],
        ),
      ),
    );
  }
}
