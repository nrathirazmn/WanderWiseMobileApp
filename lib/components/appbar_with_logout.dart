
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

AppBar buildAppBarWithLogout(BuildContext context, String title) {
  return AppBar(
    title: Text(title),
    actions: [
      IconButton(
        icon: Icon(Icons.logout),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          // Can also use Navigator.pushReplacementNamed(context, '/login') if needed but high chances aren't able to
        },
      ),
    ],
  );
}
