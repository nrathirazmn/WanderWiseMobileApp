
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;

  String? _name;
  String? _age;
  String? _nationality;
  String? _contact;
  String? _social;

@override
void initState() {
  super.initState();
  _loadUserData();
}

Future<void> _loadUserData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final data = doc.data();
  if (data != null) {
    setState(() {
      _name = data['name'];
      _age = data['age']?.toString();
      _nationality = data['nationality'];
      _contact = data['contact'];
      _social = data['social'];
    });
  }
}

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || user == null) return;
    _formKey.currentState!.save();

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'name': _name,
      'age': int.tryParse(_age ?? '0'),
      'nationality': _nationality,
      'contact': _contact,
      'social': _social,
    }, SetOptions(merge: true));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(labelText: 'Name'),
                onSaved: (value) => _name = value,
              ),
              TextFormField(
                initialValue: _age,
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _age = value,
              ),
              TextFormField(
                initialValue: _nationality,
                decoration: InputDecoration(labelText: 'Nationality'),
                onSaved: (value) => _nationality = value,
              ),
              TextFormField(
                initialValue: _contact,
                decoration: InputDecoration(labelText: 'Contact Number'),
                onSaved: (value) => _contact = value,
              ),
              TextFormField(
                initialValue: _social?.isNotEmpty == true
                    ? _social
                    : '@${FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'username'}',
                decoration: InputDecoration(labelText: 'Socials'),
                onSaved: (value) => _social = value,
              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
