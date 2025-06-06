// (Updated SettingsPage with gradient thumbnail preview)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _showInTravelBuddy = false;
  bool _isLoading = true;

  final Map<String, List<Color>> themes = {
    'Coral Crush': [Color(0xFFFF5F6D), Color(0xFFFFC371)],
    'Aqua Pop': [Color(0xFF00F260), Color(0xFF0575E6)],
    'Sand & Sea': [Color(0xFFFFE259), Color(0xFFFFA751)],
  };

  @override
  void initState() {
    super.initState();
    _loadUserSetting();
  }

  Future<void> _loadUserSetting() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      _showInTravelBuddy = doc.data()?['showInTravelBuddy'] ?? false;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _showInTravelBuddy = value);

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'showInTravelBuddy': value,
    });
  }

  void _navigateToChangePassword() {
    Navigator.pushNamed(context, '/change-password');
  }

  void _navigateToUpdateEmail() {
    Navigator.pushNamed(context, '/update-email');
  }

  void _showGradientPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: themes.entries.map((entry) {
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: entry.value),
              ),
            ),
            title: Text(entry.key),
            onTap: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'headerGradient': entry.key,
                });
              }
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Privacy', style: Theme.of(context).textTheme.headlineSmall),
                ),
                SwitchListTile(
                  title: const Text("Show me in Travel Buddy"),
                  subtitle: const Text("Allow others to see your profile in the travel buddy feature."),
                  value: _showInTravelBuddy,
                  onChanged: _updateSetting,
                ),
                const Divider(),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Theme', style: Theme.of(context).textTheme.headlineSmall),
                ),
                ListTile(
                  leading: const Icon(Icons.color_lens),
                  title: const Text('Change Header Gradient'),
                  subtitle: const Text('Customize your profile header theme.'),
                  onTap: _showGradientPicker,
                ),
                const Divider(),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Account', style: Theme.of(context).textTheme.headlineSmall),
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Change Password'),
                  onTap: _navigateToChangePassword,
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Update Email'),
                  onTap: _navigateToUpdateEmail,
                ),
                const Divider(),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Other Settings', style: Theme.of(context).textTheme.headlineSmall),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('settings_options').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No settings available.'));
                    }

                    final settings = snapshot.data!.docs;

                    return Column(
                      children: settings.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.tune),
                          title: Text(data['title'] ?? 'No Title'),
                          onTap: () {},
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
