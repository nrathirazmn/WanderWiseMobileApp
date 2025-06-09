import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTravelBuddyScreen extends StatefulWidget {
  @override
  _EditTravelBuddyScreenState createState() => _EditTravelBuddyScreenState();
}

class _EditTravelBuddyScreenState extends State<EditTravelBuddyScreen> {
  final TextEditingController bioController = TextEditingController();
  bool isLoading = true;
  final accentColor = Colors.brown;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      bioController.text = data['bio'] ?? '';
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _saveChanges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'bio': bioController.text.trim(),
    });

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Travel Buddy bio updated")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor.shade50,
      appBar: AppBar(
        title: Text("Edit Travel Buddy"),
        backgroundColor: Colors.brown.shade100,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: accentColor.shade200,
                    child: Icon(Icons.person_pin, size: 45, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Update Your Travel Vibes",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accentColor.shade800),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Let others know your travel style",
                    style: TextStyle(color: Colors.brown.shade600),
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.shade100.withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Travel Buddy Bio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 10),
                        TextField(
                          controller: bioController,
                          maxLines: 5,
                          maxLength: 200,
                          decoration: InputDecoration(
                            hintText: "e.g. Sunset lover who thrives in quiet towns and local food hunts!",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _saveChanges,
                    icon: Icon(Icons.save, color: Colors.white,),
                    label: Text("Save Changes", style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}