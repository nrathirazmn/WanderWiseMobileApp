import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WelcomeScreen extends StatefulWidget {
  final String userName;

  WelcomeScreen({required this.userName});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool showInBuddy = false;
  bool isSaving = false;

void savePreferenceAndContinue() async {
  setState(() => isSaving = true);

  final uid = FirebaseAuth.instance.currentUser!.uid;

  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'showInTravelBuddy': showInBuddy,
  });

  if (!mounted) return;

  if (showInBuddy) {
    Navigator.pushReplacementNamed(context, '/travelbuddy-setup');
  } else {
    Navigator.pushReplacementNamed(context, '/main', arguments: {'selectedIndex': 1});
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/travelerWP.png', height: 180),
              SizedBox(height: 32),
              Text('Welcome', style: TextStyle(fontSize: 22)),
              SizedBox(height: 4),
              Text(
                widget.userName,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'It’s great to see you here.\nWould you like to be shown in Travel Buddy?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Show me in Travel Buddy'),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('What is Travel Buddy?'),
                          content: Text(
                            'Travel Buddy is a feature that allows other users to discover you as a potential travel companion. '
                            'If you turn this on, your profile will be visible to other solo travelers looking to connect and explore together!',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Got it!'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text(
                      'What\'s this?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Switch(
                    value: showInBuddy,
                    onChanged: (val) => setState(() => showInBuddy = val),
                  ),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isSaving ? null : savePreferenceAndContinue,
                icon: Icon(Icons.arrow_forward, color: Colors.white),
                label: Text(
                  "Let’s get it",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 86, 35, 1),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
