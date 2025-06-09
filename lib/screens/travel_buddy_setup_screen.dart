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
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.brown.shade100,
        title: Text('Create Travel Buddy Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(Icons.person_pin_circle, size: 80, color: Colors.brown[300]),
            ),
            SizedBox(height: 12),
            Center(
              child: Text(
                'Let Others Know You ✈️',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown[800]),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Write a short travel bio to connect better with your future buddies!',
                style: TextStyle(fontSize: 14, color: Colors.brown[600]),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.shade100,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: bioController,
                maxLines: 5,
                maxLength: 200,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Example: Adventurous foodie who loves hiking and hidden beaches!',
                ),
              ),
            ),
            SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.check_circle_outline, color: Colors.white,),
                label: Text('Save & Continue', style: TextStyle(color: Colors.white),),
                onPressed: isSaving ? null : _saveBuddyProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
