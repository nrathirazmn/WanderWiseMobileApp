import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TravelBuddySetupScreen extends StatefulWidget {
  @override
  _TravelBuddySetupScreenState createState() => _TravelBuddySetupScreenState();
}

class _TravelBuddySetupScreenState extends State<TravelBuddySetupScreen> {
  final TextEditingController bioController = TextEditingController();
  bool isSaving = false;

  Future<void> _saveBuddyProfile() async {
    setState(() => isSaving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'bio': bioController.text.trim().isEmpty
          ? 'Loves to travel!'
          : bioController.text.trim(),
    });

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Up Travel Buddy'),
        backgroundColor: const Color.fromARGB(255, 86, 35, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Travel Buddy Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text(
              'Write a short bio that other travelers will see. It helps others understand who you are and what kind of travel you enjoy!',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            SizedBox(height: 16),
            TextField(
              controller: bioController,
              maxLines: 5,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Example: Backpacker who loves food, sunsets and small villages!',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.check),
                label: Text('Save and Continue'),
                onPressed: isSaving ? null : _saveBuddyProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 86, 35, 1),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
